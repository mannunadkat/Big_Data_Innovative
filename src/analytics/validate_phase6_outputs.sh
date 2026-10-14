#!/bin/bash
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
F="$ROOT/screenshots/26-hive-partition-rowcounts.txt"
TOTAL=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/ {s+=$2} END{print s+0}' "$F")
CANC=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/ {s+=$3} END{print s+0}' "$F")
echo "Reference totals from phase 5 validation: rows=$TOTAL cancelled=$CANC"
fail=0
check() {
  got=$(awk -F, -v c="$3" 'NR>1 {s+=$c} END{print s+0}' "$2")
  if [ "$got" = "$4" ]; then echo "OK   $1: $got"; else echo "FAIL $1: got $got expected $4"; fail=1; fi
}
check "delay_by_month total_flights"       "$ROOT/output/time_analysis/delay_by_month.csv" 2 "$TOTAL"
check "delay_by_year_month total_flights"  "$ROOT/output/time_analysis/delay_by_year_month.csv" 3 "$TOTAL"
check "delay_by_day_of_week total_flights" "$ROOT/output/time_analysis/delay_by_day_of_week.csv" 3 "$TOTAL"
check "delay_by_dep_hour total_flights"    "$ROOT/output/time_analysis/delay_by_dep_hour.csv" 3 "$TOTAL"
check "cancellation_by_reason cancelled"   "$ROOT/output/cancellation_analysis/cancellation_by_reason.csv" 3 "$CANC"
check "cancellation_by_month total_flights" "$ROOT/output/cancellation_analysis/cancellation_by_month.csv" 2 "$TOTAL"
check "cancellation_by_month cancelled"    "$ROOT/output/cancellation_analysis/cancellation_by_month.csv" 3 "$CANC"
check "cancellation_by_carrier total_flights" "$ROOT/output/cancellation_analysis/cancellation_by_carrier.csv" 3 "$TOTAL"
check "cancellation_by_carrier cancelled"  "$ROOT/output/cancellation_analysis/cancellation_by_carrier.csv" 4 "$CANC"
check "weather_by_month total_flights"     "$ROOT/output/weather_analysis/weather_by_month.csv" 2 "$TOTAL"
exit $fail
