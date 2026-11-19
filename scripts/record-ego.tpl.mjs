// Body for `ego-browser nodejs`. rec-ego.sh prepends: const CFG = {url, outdir, secs, actions, space};
// (copied from gpt62-lecture 2026-11-19 for the Neon rematch) Records a page in Ego Lite by repeated Page.captureScreenshot (JPEG + wall-clock timestamps).
const fs = await import("node:fs");
const path = await import("node:path");
const { url, outdir, secs, actions, space } = CFG;
const W = 1280, H = 800;
fs.rmSync(outdir, { recursive: true, force: true });
fs.mkdirSync(path.join(outdir, "f"), { recursive: true });
const task = await taskSpace(space + " " + Date.now());
console.log({ taskSpaceId: task.spaceId });
const page = task.page("p1");
await page.cdp("Emulation.setDeviceMetricsOverride", { width: W, height: H, deviceScaleFactor: 1, mobile: false });
await page.goto("about:blank");
const logs = [];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const KEY = {
  w: ["w", "KeyW", 87], a: ["a", "KeyA", 65], s: ["s", "KeyS", 83], d: ["d", "KeyD", 68], " ": [" ", "Space", 32],
  ArrowUp: ["ArrowUp", "ArrowUp", 38], ArrowDown: ["ArrowDown", "ArrowDown", 40], ArrowLeft: ["ArrowLeft", "ArrowLeft", 37], ArrowRight: ["ArrowRight", "ArrowRight", 39],
  Enter: ["Enter", "Enter", 13], Shift: ["Shift", "ShiftLeft", 16], "/": ["/", "Slash", 191],
};
for (const c of "abcdefghijklmnopqrstuvwxyz") KEY[c] ??= [c, "Key" + c.toUpperCase(), c.toUpperCase().charCodeAt(0)];
let mx = W / 2, my = H / 2, btn = "none";
const mouse = (type, x, y, extra = {}) => page.cdp("Input.dispatchMouseEvent", { type, x, y, button: btn, buttons: btn === "left" ? 1 : 0, clickCount: 1, ...extra });
const moveTo = async (x, y, steps = 8) => {
  const x0 = mx, y0 = my;
  for (let i = 1; i <= steps; i++) { mx = x0 + (x - x0) * i / steps; my = y0 + (y - y0) * i / steps; await mouse("mouseMoved", mx, my); await sleep(16); }
};
const down = async () => { btn = "left"; await mouse("mousePressed", mx, my); };
const up = async () => { await mouse("mouseReleased", mx, my); btn = "none"; };
// CDP Input.dispatchKeyEvent is dropped when the Ego window is not focused; ego's page.keyboard is not (same for every model)
const key = (type, k) => type === "keyDown" ? page.keyboard.down(k) : page.keyboard.up(k);
const run = async (a) => {
  if (a.do === "key") { await key("keyDown", a.key); await sleep(140); await key("keyUp", a.key); }
  else if (a.do === "down") await key("keyDown", a.key);
  else if (a.do === "up") await key("keyUp", a.key);
  else if (a.do === "click") { await moveTo(a.x, a.y, 4); await down(); await sleep(60); await up(); }
  else if (a.do === "clicktext") {
    // same rule for every model: press the visible button/link whose text matches a.re (start/enter/sound...), else click a.x,a.y
    const hit = await page.evaluate(([srcs, skipSrc]) => {
      const skip = new RegExp(skipSrc, "i");
      const all = [...document.querySelectorAll("button, a, [role=button], label, [role=radio], [role=option], [role=tab], [aria-pressed], [data-value], input[type=radio] + *, .swatch, .option")]
        .filter((e) => { const r = e.getBoundingClientRect(); const s = getComputedStyle(e); return r.width > 4 && r.height > 4 && r.width < 700 && r.height < 300 && s.visibility !== "hidden" && s.display !== "none" && +s.opacity > 0.05 && (e.innerText || "").length < 200; });
      for (const src of [].concat(srcs)) {
        const re = new RegExp(src, "i");
        const els = all.filter((e) => { const t = (e.innerText || e.getAttribute("aria-label") || "").trim(); return re.test(t) && !skip.test(t); });
        els.sort((p, q) => (p.innerText || "").length - (q.innerText || "").length);
        const e = els[0];
        if (e) { e.scrollIntoView({ block: "center", inline: "center", behavior: "instant" }); const r = e.getBoundingClientRect(); return { x: r.x + r.width / 2, y: r.y + r.height / 2, text: (e.innerText || "").trim().slice(0, 40) }; }
      }
      return null;
    }, [a.re, a.skip ?? "how to|help|guide|tutorial|restart|reset|retry|settings|sound|mute|도움말|방법|다시|재시작"]).catch(() => null);
    logs.push("[clicktext] " + JSON.stringify(hit));
    const p = hit ?? { x: a.x, y: a.y };
    await moveTo(p.x, p.y, 4); await down(); await sleep(60); await up();
    // same for every model: do not leave keyboard focus on the clicked button (some games ignore Space while a button is focused)
    await page.evaluate(() => { const a = document.activeElement; if (a && a !== document.body && a.blur) a.blur(); }).catch(() => {});
  }
  else if (a.do === "keyif") {
    // same rule for every model: press a.key only while the page text matches a.when (e.g. a game-over screen)
    const on = await page.evaluate((src) => new RegExp(src, "i").test(document.body.innerText || ""), a.when).catch(() => false);
    if (on) { logs.push("[keyif] " + a.key); await key("keyDown", a.key); await sleep(140); await key("keyUp", a.key); }
  }
  else if (a.do === "move") await moveTo(a.x, a.y, a.steps ?? 8);
  else if (a.do === "moveby") await moveTo(mx + (a.dx ?? 0), my + (a.dy ?? 0), a.steps ?? 8);
  else if (a.do === "mdown") { await moveTo(a.x, a.y, 4); await down(); }
  else if (a.do === "mup") { if (a.x != null) await moveTo(a.x, a.y, a.steps ?? 10); await up(); }
  else if (a.do === "wheel") { await moveTo(a.x ?? 640, a.y ?? 400, 2); const n = 10; for (let i = 0; i < n; i++) { await page.cdp("Input.dispatchMouseEvent", { type: "mouseWheel", x: mx, y: my, deltaX: 0, deltaY: a.dy / n }); await sleep(25); } }
  else if (a.do === "drag") { await moveTo(a.x, a.y, 4); await down(); await moveTo(a.x2, a.y2, a.steps ?? 15); await sleep(a.ms ?? 50); await up(); }
};
// Ego Lite refuses real pointer lock for automated input. Same shim for every model (recording only, files untouched):
// requestPointerLock "succeeds", pointerLockElement reports the element, exitPointerLock clears it.
await page.cdp("Page.addScriptToEvaluateOnNewDocument", { source: `(() => {
  let locked = null;
  Object.defineProperty(Document.prototype, "pointerLockElement", { configurable: true, get() { return locked; } });
  Element.prototype.requestPointerLock = function () { locked = this; setTimeout(() => document.dispatchEvent(new Event("pointerlockchange")), 0); return Promise.resolve(); };
  Document.prototype.exitPointerLock = function () { locked = null; setTimeout(() => document.dispatchEvent(new Event("pointerlockchange")), 0); };
  window.__recKeys = []; addEventListener("keydown", (e) => { if (window.__recKeys.length < 40) window.__recKeys.push(e.code + (document.hasFocus() ? "" : "!nofocus")); }, true);
})();` });
// keyboard events only reach a focused page: bring the tab to front and emulate focus (same for every model)
await page.cdp("Page.bringToFront").catch((e) => logs.push("[front] " + String(e).slice(0, 120)));
await page.cdp("Emulation.setFocusEmulationEnabled", { enabled: true }).catch((e) => logs.push("[focus] " + String(e).slice(0, 120)));
const frames = [];
let stop = false, n = 0;
const t0 = Date.now();
await page.goto(url, { waitUntil: "load", timeout: 30000 }).catch((e) => logs.push("[goto] " + String(e).slice(0, 300)));
const tLoad = Date.now();
// ego lite 0.6.3.17: Page.startScreencast sends only a few frames, so poll Page.captureScreenshot instead
// (same for every model; timestamps are wall-clock so playback speed stays real).
const grab = (async () => {
  while (!stop) {
    try {
      const r = await page.cdp("Page.captureScreenshot", { format: "jpeg", quality: 88 });
      const name = `f/${String(n++).padStart(5, "0")}.jpg`;
      fs.writeFileSync(path.join(outdir, name), Buffer.from(r.data, "base64"));
      frames.push({ name, t: Date.now() / 1000 });
    } catch (e) { logs.push("[grab] " + String(e).slice(0, 200)); await sleep(50); }
  }
})();
const acts = (async () => {
  for (const a of [...actions].sort((p, q) => p.at - q.at)) {
    const wait = a.at * 1000 - (Date.now() - tLoad);
    if (wait > 0) await sleep(wait);
    try { await run(a); } catch (e) { logs.push(`[action] ${String(e).slice(0, 200)}`); }
  }
})();
await acts;
const left = secs * 1000 - (Date.now() - tLoad);
if (left > 0) await sleep(left);
stop = true; await grab;
await page.screenshot({ path: path.join(outdir, "last.png") });
const text = await page.evaluate(() => document.body ? document.body.innerText.slice(0, 1500) : "").catch(() => "");
const keysSeen = await page.evaluate(() => (window.__recKeys || []).slice(0, 12).join(",")).catch(() => "?");
logs.push("[keys] " + keysSeen);
await page.goto("about:blank").catch(() => {});
let cc = "ffconcat version 1.0\n";
for (let i = 0; i < frames.length; i++) {
  const d = i + 1 < frames.length ? frames[i + 1].t - frames[i].t : 1 / 10;
  cc += `file '${frames[i].name}'\nduration ${Math.max(0.001, d).toFixed(4)}\n`;
}
if (frames.length) cc += `file '${frames.at(-1).name}'\n`;
fs.writeFileSync(path.join(outdir, "frames.ffconcat"), cc);
const span = frames.length ? frames.at(-1).t - frames[0].t : 0;
fs.writeFileSync(path.join(outdir, "report.json"), JSON.stringify({ url, browser: "ego-lite", frames: frames.length, span, fps: frames.length / Math.max(span, 0.001), loadMs: tLoad - t0, logs, text }, null, 1));
console.log(outdir, "frames", frames.length, "fps", (frames.length / Math.max(span, 0.001)).toFixed(1), "logs", logs.length);
await task.finish({ keep: [] });
