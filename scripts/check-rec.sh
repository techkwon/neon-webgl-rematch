#!/bin/zsh
# usage: check-rec.sh <model> <out.jpg>  -> rows = tasks, 4 frames each (2s, 6s, 11s, end-2s)
B=./samples
M=$1; OUT=$2; TMP=$(mktemp -d)
for T in water globe store city blackhole; do
  V=$B/rec/$T-$M.mp4; [[ -f $V ]] || continue
  D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 $V)
  i=0; for t in 2 6 11 $((D-2)); do ffmpeg -y -loglevel error -ss $t -i $V -frames:v 1 -vf scale=480:-1 $TMP/$T-$i.jpg; i=$((i+1)); done
  ffmpeg -y -loglevel error -i $TMP/$T-0.jpg -i $TMP/$T-1.jpg -i $TMP/$T-2.jpg -i $TMP/$T-3.jpg -filter_complex hstack=4 $TMP/row-$T.jpg
done
ROWS=($TMP/row-*.jpg)
ffmpeg -y -loglevel error $(for r in $ROWS; do print -n -- "-i $r "; done) -filter_complex vstack=${#ROWS} $OUT
rm -rf "${TMP:?}"
