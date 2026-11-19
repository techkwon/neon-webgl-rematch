#!/bin/zsh
# usage: run_one.sh <model: hydrogen|neon|sol|sonnet|terra|astra (carbon|fable kept, not used in ep.9)> <task> <workdir>
# Conditions (same as ep.7/ep.8): Claude = file tools only; Codex = workspace-write sandbox;
# agy = --sandbox with commands auto-approved (headless accept-edits ends the turn on a denied command).
M=$1; T=$2
BASE=${0:A:h}
WORK="$3/$T/$M"; mkdir -p "$WORK"; cd "$WORK"
PROMPT="$(cat $BASE/prompts/$T.txt)"
START=$(date +%s)
case $M in
  hydrogen) env -i HOME=$HOME PATH=$PATH USER=$USER agy -p "$PROMPT" --model gemini-4-hydrogen-high --sandbox --dangerously-skip-permissions --output-format json < /dev/null > log.json 2> err.txt;;
  neon)     env -i HOME=$HOME PATH=$PATH USER=$USER agy -p "$PROMPT" --model gemini-4-neon-high --sandbox --dangerously-skip-permissions --output-format json < /dev/null > log.json 2> err.txt;;
  # Carbon is not in the Google-account (AI Pro) catalog for this account, so it runs on the Gemini API key
  # with session-only settings (same setup as ep.8; nothing is written to settings.json).
  carbon)   env -i HOME=$HOME PATH=$PATH USER=$USER GEMINI_API_KEY="$(security find-generic-password -a "$USER" -s agy-gemini-api-key -w)" agy -p "$PROMPT" --model gemini-4-carbon --settings '{"modelProvider":"gemini","customModelsConfig":{"customModels":{"gemini-4-carbon":{"displayName":"Gemini 4 Carbon","modelName":"gemini-4-carbon","apiProvider":"API_PROVIDER_GOOGLE_GEMINI"}}}}' --sandbox --dangerously-skip-permissions --output-format json < /dev/null > log.json 2> err.txt;;
  astra)    env -i HOME=$HOME PATH=$PATH codex exec --skip-git-repo-check -s workspace-write -C . -m gpt-6-astra -c model_reasoning_effort=high --json -o last.txt "$PROMPT" < /dev/null > log.jsonl 2> err.txt;;
  sol)      env -i HOME=$HOME PATH=$PATH codex exec --skip-git-repo-check -s workspace-write -C . -m gpt-6.2-sol -c model_reasoning_effort=high --json -o last.txt "$PROMPT" < /dev/null > log.jsonl 2> err.txt;;
  terra)    env -i HOME=$HOME PATH=$PATH codex exec --skip-git-repo-check -s workspace-write -C . -m gpt-6.1-terra -c model_reasoning_effort=high --json -o last.txt "$PROMPT" < /dev/null > log.jsonl 2> err.txt;;
  sonnet)   env -i HOME=$HOME PATH=$PATH USER=$USER claude -p "$PROMPT" --model claude-sonnet-5-5 --effort high --setting-sources "" --strict-mcp-config --permission-mode acceptEdits --allowedTools "Write,Edit,Read" --output-format json < /dev/null > log.json 2> err.txt;;
  fable)    env -i HOME=$HOME PATH=$PATH USER=$USER claude -p "$PROMPT" --model claude-fable-5-2 --effort high --setting-sources "" --strict-mcp-config --permission-mode acceptEdits --allowedTools "Write,Edit,Read" --output-format json < /dev/null > log.json 2> err.txt;;
esac
RC=$?
END=$(date +%s)
echo "{\"model\":\"$M\",\"task\":\"$T\",\"seconds\":$((END-START)),\"rc\":$RC}" > meta.json
OUT=$BASE/runs/$T/$M; mkdir -p $OUT; cp -f index.html meta.json $OUT/ 2>/dev/null
cp -f log.json log.jsonl last.txt err.txt $OUT/ 2>/dev/null
echo "done $M $T rc=$RC $((END-START))s $(ls $OUT | tr '\n' ' ')"
