#!/bin/zsh
B=./samples
for J in hydrogen sonnet sol neon; do
 ( for t in ski turing labbench; do
     [[ -f $B/judge-neon/$t/vote-$J.json ]] && continue
     for a in 1 2 3; do zsh $B/scripts/judge_neon.sh $t $J && break; echo "retry $t $J"; done
   done; echo "JUDGE DONE $J" ) &
done
wait; echo "ALL JUDGE DONE"
