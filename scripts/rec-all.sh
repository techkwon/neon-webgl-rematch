#!/bin/zsh
# usage: rec-all.sh <model...>   records every finished task for those models that has no rec/<task>-<model>.mp4 yet
B=./samples
for M in "$@"; do
  for T in water globe store city blackhole; do
    [[ -f $B/rec/$T-$M.mp4 ]] && continue
    [[ -f $B/runs/$T/$M/index.html ]] || continue
    case $T in
      store) $B/scripts/rec-ego.sh $T $M 28 $B/scripts/act-store.json ;;
      city)  $B/scripts/rec-ego.sh $T $M 24 $B/scripts/act-city.json ;;
      globe) $B/scripts/rec-ego.sh $T $M 18 $B/scripts/act-globe.json ;;
      *)     $B/scripts/rec-ego.sh $T $M 18 $B/scripts/act-orbit.json ;;
    esac
    echo "REC $T $M"
  done
done
echo "REC-ALL DONE $*"
