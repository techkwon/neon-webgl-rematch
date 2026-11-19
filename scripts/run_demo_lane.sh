#!/bin/zsh
# one model, Google's Neon launch demos (prompts written from the blog descriptions) in order
M=$1; W=$2
for T in ski turing labbench; do ${0:A:h}/run_one.sh $M $T $W; done
echo "LANE DONE $M"
