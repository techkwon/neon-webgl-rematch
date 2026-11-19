#!/bin/zsh
B=./samples
export REC_PORT=18765
for M in neon hydrogen sonnet sol; do for T in ski turing labbench; do
  [[ -f $B/rec/$T-$M.mp4 ]] && continue; [[ -f $B/runs/$T/$M/index.html ]] || continue
  case $T in ski) $B/scripts/rec-ego.sh $T $M 22 $B/scripts/act-ski.json;; turing) $B/scripts/rec-ego.sh $T $M 18 $B/scripts/act-turing.json;; *) $B/scripts/rec-ego.sh $T $M 18 $B/scripts/act-orbit.json;; esac
  echo "REC $T $M"; done; done; echo "REC DEMO DONE"
