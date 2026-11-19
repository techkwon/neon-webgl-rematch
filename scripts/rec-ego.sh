#!/bin/zsh
# usage: rec-ego.sh <task> <model> <seconds> [actions.json]  -> rec/<task>-<model>.mp4  (Ego Lite only)
# needs: python3 -m http.server 8765 --bind 127.0.0.1 --directory $B/runs  (started by caller)
B=./samples
T=$1; M=$2; S=$3; A=$4
[[ -f $B/runs/$T/$M/index.html ]] || { echo "missing $T/$M"; exit 1; }
O=$B/rec/tmp-$T-$M
mkdir -p $B/rec
ACTS='[]'; [[ -n $A ]] && ACTS=$(cat $A)
SCRIPT=$B/rec/.rec-$T-$M.mjs
print -r -- "const CFG = {url: \"http://127.0.0.1:${REC_PORT:-8765}/$T/$M/index.html\", outdir: \"$O\", secs: $S, actions: $ACTS, space: \"hydrogen bench recording\"};" > $SCRIPT
cat $B/scripts/record-ego.tpl.mjs >> $SCRIPT
ego-browser nodejs < $SCRIPT 2>&1 | grep -v "ego-browser:notice" || exit 1
rm -f $SCRIPT
[[ -f $O/frames.ffconcat ]] || { echo "no frames $T/$M"; exit 1; }
ffmpeg -y -loglevel error -f concat -safe 0 -i $O/frames.ffconcat -vf "fps=30,scale=1280:800:flags=lanczos,format=yuv420p" -c:v libx264 -crf 16 -preset medium -t $S $B/rec/$T-$M.mp4
cp $O/last.png $B/rec/$T-$M.png; cp $O/report.json $B/rec/$T-$M.json; rm -rf "${O:?}/f"
ffprobe -v error -show_entries format=duration -of csv=p=0 $B/rec/$T-$M.mp4
