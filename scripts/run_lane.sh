#!/bin/zsh
# one model, all five tasks in order
M=$1; W=$2
for T in water globe store city blackhole; do ${0:A:h}/run_one.sh $M $T $W; done
echo "LANE DONE $M"
