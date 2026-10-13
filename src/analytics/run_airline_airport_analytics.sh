#!/bin/bash
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/output/airline_airport"
LOGS="$ROOT/screenshots/hive-logs"
mkdir -p "$OUT" "$LOGS"
for q in airline_delay_summary airline_delay_by_year airline_delay_causes airport_origin_delays airport_dest_delays airport_dep_vs_arr; do
  echo "=== $q ==="
  "$ROOT/scripts/hive-exec.sh" "$ROOT/src/analytics/queries/$q.hql" 2> "$LOGS/$q.log" | tr '\t' ',' > "$OUT/$q.csv"
  head -n 5 "$OUT/$q.csv"
  wc -l < "$OUT/$q.csv"
done
echo "Analytics complete."
