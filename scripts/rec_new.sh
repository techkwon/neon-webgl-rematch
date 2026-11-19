#!/bin/zsh
# Record Neon + GPT-6.2 Sol runs as they become available (same actions/lengths as ep.9 via rec-all.sh).
B=${0:A:h}
export REC_PORT=18765
until grep -q "RETRY DONE" $B/logs/retry-neon.log && grep -q "LANE DONE sol" $B/logs/lane-sol.log; do
  $B/scripts/rec-all.sh hydrogen sonnet sol neon; sleep 60
done
$B/scripts/rec-all.sh hydrogen sonnet sol neon
echo "REC NEW DONE"
