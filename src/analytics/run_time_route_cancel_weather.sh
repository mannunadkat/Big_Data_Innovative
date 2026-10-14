#!/bin/bash
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOGS="$ROOT/screenshots/hive-logs"
mkdir -p "$LOGS"
JOBS=(
  "time_analysis:delay_by_month"
  "time_analysis:delay_by_year_month"
  "time_analysis:delay_by_day_of_week"
  "time_analysis:delay_by_dep_hour"
  "route_analysis:route_worst_delays"
  "route_analysis:route_busiest"
  "cancellation_analysis:cancellation_by_reason"
  "cancellation_analysis:cancellation_by_carrier"
  "cancellation_analysis:cancellation_by_airport"
  "cancellation_analysis:cancellation_by_month"
  "weather_analysis:weather_by_airport"
  "weather_analysis:weather_by_month"
)
for j in "${JOBS[@]}"; do
  dir="${j%%:*}"
  q="${j##*:}"
  mkdir -p "$ROOT/output/$dir"
  echo "=== $q ==="
  "$ROOT/scripts/hive-exec.sh" "$ROOT/src/analytics/queries/$q.hql" 2> "$LOGS/$q.log" | tr '\t' ',' > "$ROOT/output/$dir/$q.csv"
  head -n 4 "$ROOT/output/$dir/$q.csv"
  wc -l < "$ROOT/output/$dir/$q.csv"
done
echo "Analytics complete."
