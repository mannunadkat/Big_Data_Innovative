#!/bin/bash
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="$ROOT/output/prediction_results"
LOGS="$ROOT/screenshots/hive-logs"
Q="$ROOT/src/analytics/prediction"
mkdir -p "$OUT" "$LOGS"
GP=$(docker exec namenode bash -c "source /opt/hive-data/hive-env.sh && hive -S -e 'SELECT CAST(p AS STRING) FROM flightdb.model_global' 2>/dev/null" | tail -n 1 | tr -d '\r')
if ! echo "$GP" | grep -Eq '^0\.[0-9]+$'; then echo "Could not read the global probability (got: $GP)"; exit 1; fi
echo "Global train delay probability: $GP"
echo "=== scoring validation + test flights (5 back-off joins on YARN) ==="
"$ROOT/scripts/hive-exec-vars.sh" "$Q/03_score.hql" --hivevar global_p=$GP 2> "$LOGS/p9_03_score.log"
echo "=== validation threshold sweep ==="
"$ROOT/scripts/hive-exec-vars.sh" "$Q/queries/threshold_sweep.hql" --hivevar split_name=validation 2> "$LOGS/p9_sweep_validation.log" | tr '\t' ',' > "$OUT/threshold_sweep_validation.csv"
CHOSEN=$(awk -F, 'NR>1 && $8 ~ /^[0-9.]+$/ && $8+0 > best {best=$8+0; thr=$1} END{print thr}' "$OUT/threshold_sweep_validation.csv")
if ! echo "$CHOSEN" | grep -Eq '^0\.[0-9]+$'; then echo "Could not choose a threshold (got: $CHOSEN)"; exit 1; fi
echo "$CHOSEN" > "$OUT/chosen_threshold.txt"
echo "Threshold chosen on VALIDATION (maximum F1): $CHOSEN"
echo "=== test threshold sweep (reference only, NOT used to choose anything) ==="
"$ROOT/scripts/hive-exec-vars.sh" "$Q/queries/threshold_sweep.hql" --hivevar split_name=test 2> "$LOGS/p9_sweep_test.log" | tr '\t' ',' > "$OUT/threshold_sweep_test.csv"
for q in test_metrics level_usage_test carrier_performance_test hour_bucket_performance_test; do
  echo "=== $q ==="
  "$ROOT/scripts/hive-exec-vars.sh" "$Q/queries/$q.hql" --hivevar threshold=$CHOSEN 2> "$LOGS/p9_$q.log" | tr '\t' ',' > "$OUT/$q.csv"
  head -n 4 "$OUT/$q.csv"
done
for q in calibration_test scored_counts; do
  echo "=== $q ==="
  "$ROOT/scripts/hive-exec.sh" "$Q/queries/$q.hql" 2> "$LOGS/p9_$q.log" | tr '\t' ',' > "$OUT/$q.csv"
  head -n 4 "$OUT/$q.csv"
done
echo "Scoring and evaluation complete."
