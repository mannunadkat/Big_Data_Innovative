#!/bin/bash
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="$ROOT/output/prediction_model"
LOGS="$ROOT/screenshots/hive-logs"
Q="$ROOT/src/analytics/prediction"
mkdir -p "$OUT" "$LOGS"
YEARS=$(docker exec namenode hdfs dfs -ls /flights/cleaned | grep -o 'year=[0-9]*' | cut -d= -f2 | sort -n)
if [ -z "$YEARS" ]; then echo "No year partitions found in /flights/cleaned"; exit 1; fi
NYEARS=$(echo "$YEARS" | wc -l | tr -d ' ')
if [ "$NYEARS" -lt 2 ]; then echo "Need at least 2 years of data for a temporal test split"; exit 1; fi
TEST_YEAR=$(echo "$YEARS" | tail -n 1)
MIN_SUPPORT=30
echo "$TEST_YEAR" > "$OUT/test_year.txt"
echo "Years: $(echo $YEARS) | test year: $TEST_YEAR | min_support: $MIN_SUPPORT"
echo "=== building split table ==="
"$ROOT/scripts/hive-exec-vars.sh" "$Q/01_create_split.hql" --hivevar test_year=$TEST_YEAR 2> "$LOGS/p8_01_create_split.log"
echo "=== building model tables ==="
"$ROOT/scripts/hive-exec-vars.sh" "$Q/02_build_model.hql" --hivevar min_support=$MIN_SUPPORT 2> "$LOGS/p8_02_build_model.log"
for q in split_summary model_level_stats model_global model_l4 model_l3 model_l1_most_common model_l1_highest_risk; do
  echo "=== report: $q ==="
  "$ROOT/scripts/hive-exec.sh" "$Q/queries/$q.hql" 2> "$LOGS/p8_$q.log" | tr '\t' ',' > "$OUT/$q.csv"
  head -n 4 "$OUT/$q.csv"
  wc -l < "$OUT/$q.csv"
done
echo "Model build complete."
