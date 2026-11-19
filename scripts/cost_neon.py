#!/usr/bin/env python3
"""Neon-round cost table -> costs-neon.json.
Gemini (agy log.json usage): input x in, cache_read x cached, (output+thinking) x out. Hydrogen kept as ep.11 (no cache price) for comparability.
Sol (codex turn.completed): (input-cached) x in + cached x cached + output x out, plus self-spawned helper agents from ~/.codex/sessions.
Sonnet: total_cost_usd reported by Claude Code."""
import json, os, re, glob
B = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEMO = os.environ.get('DEMO') == '1'
T = ['ski', 'turing', 'labbench'] if DEMO else ['water', 'globe', 'store', 'city', 'blackhole']
P = {'neon': (3.0, 0.15, 15.0), 'hydrogen': (1.5, None, 7.5), 'sol': (2.0, 0.10, 10.0)}
SESS = {}
for f in glob.glob(os.path.expanduser('~/.codex/sessions/**/*.jsonl'), recursive=True):
    mm = re.search(r'([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\.jsonl$', f)
    if mm: SESS[mm.group(1)] = f
def helper(tid, seen):
    f = SESS.get(tid); usd = 0.0; n = 0
    if not f: return 0.0, 0
    txt = open(f, encoding='utf8', errors='ignore').read()
    for m in re.finditer(r'"SubAgentActivity","model":"([^"]+)".{0,200}?"agent_thread_id":"([^"]+)"', txt):
        mod, a = m.groups()
        if a in seen: continue
        seen.add(a); sf = SESS.get(a); u = None
        if sf:
            for line in open(sf, encoding='utf8', errors='ignore'):
                for x in re.findall(r'"total_token_usage":(\{[^}]+\})', line): u = json.loads(x)
        if u and mod == 'gpt-6.2-sol':
            c = u.get('cached_input_tokens', 0)
            usd += ((u['input_tokens'] - c) * 2.0 + c * 0.10 + u['output_tokens'] * 10.0) / 1e6; n += 1
        su, sn = helper(a, seen); usd += su; n += sn
    return usd, n
def gem(d, m):
    u = json.load(open(f'{d}/log.json'))['usage']
    pi, pc, po = P[m]; out = u['output_tokens'] + u.get('thinking_tokens', 0)
    usd = (u['input_tokens'] * pi + (u.get('cache_read_tokens', 0) * pc if pc else 0) + out * po) / 1e6
    return round(usd, 3), {'input': u['input_tokens'], 'cached': u.get('cache_read_tokens', 0), 'output': out}
def sol(d):
    lines = open(f'{d}/log.jsonl').read().splitlines()
    u = [json.loads(x) for x in lines if 'turn.completed' in x][-1]['usage']
    c = u.get('cached_input_tokens', 0)
    usd = ((u['input_tokens'] - c) * 2.0 + c * 0.10 + u['output_tokens'] * 10.0) / 1e6
    tid = next((re.search(r'"thread_id":"([^"]+)"', x).group(1) for x in lines if '"thread_id"' in x), None)
    hu, hn = helper(tid, set()) if tid else (0, 0)
    return round(usd + hu, 3), {'input': u['input_tokens'] - c, 'cached': c, 'output': u['output_tokens'], 'helpers': hn, 'helper_usd': round(hu, 3)}
res = {'runs': {}, 'failed': [], 'prices': P}
for t in T:
    res['runs'][t] = {}
    for m in ['neon', 'hydrogen', 'sonnet', 'sol']:
        d = f'{B}/runs/{t}/{m}'
        if m == 'sonnet': r = {'usd': round(json.load(open(f'{d}/log.json'))['total_cost_usd'], 3), 'kind': 'reported'}
        elif m == 'sol': usd, tok = sol(d); r = {'usd': usd, 'tokens': tok, 'kind': 'estimate'}
        else: usd, tok = gem(d, m); r = {'usd': usd, 'tokens': tok, 'kind': 'estimate'}
        r['seconds'] = json.load(open(f'{d}/meta.json'))['seconds']
        res['runs'][t][m] = r
for d in ([] if DEMO else sorted(glob.glob(f'{B}/runs-failed-neon/*'))):
    meta = json.load(open(f'{d}/meta.json')) if os.path.exists(f'{d}/meta.json') else {}
    try: usd, tok = gem(d, 'neon')
    except Exception: usd, tok = None, None
    res['failed'].append({'id': os.path.basename(d), 'usd': usd, 'tokens': tok, 'seconds': meta.get('seconds'), 'rc': meta.get('rc')})
res['total'] = {m: round(sum(res['runs'][t][m]['usd'] for t in T), 2) for m in ['neon', 'hydrogen', 'sonnet', 'sol']}
res['seconds'] = {m: sum(res['runs'][t][m]['seconds'] for t in T) for m in ['neon', 'hydrogen', 'sonnet', 'sol']}
res['failed_usd'] = round(sum(f['usd'] or 0 for f in res['failed']), 2)
json.dump(res, open(f'{B}/' + ('costs-neon-demo.json' if DEMO else 'costs-neon.json'), 'w'), indent=1)
for t in T: print(t, {m: (r['usd'], r['seconds']) for m, r in res['runs'][t].items()})
print('total', res['total'], 'sec', res['seconds']); print('failed', res['failed'])
