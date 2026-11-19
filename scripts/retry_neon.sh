#!/bin/zsh
# Re-run Neon tasks that failed (rc != 0 or no index.html) once the lane is done. Failed attempts are kept in runs-failed-neon/.
B=${0:A:h}; W=$1
until grep -q "LANE DONE neon" $B/logs/lane-neon.log; do sleep 20; done
for try in 1 2; do
  for T in water globe store city blackhole; do
    O=$B/runs/$T/neon
    if [[ -f $O/index.html ]] && grep -q '"rc":0' $O/meta.json; then continue; fi
    mkdir -p $B/runs-failed-neon/$T-try$try; mv $O/* $B/runs-failed-neon/$T-try$try/ 2>/dev/null
    rm -rf "${W:?}/$T/neon"
    $B/run_one.sh neon $T $W
  done
done
echo "RETRY DONE"
