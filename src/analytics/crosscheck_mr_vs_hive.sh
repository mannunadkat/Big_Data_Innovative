#!/bin/bash
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/output/mapreduce"
LOGS="$ROOT/screenshots/hive-logs"
REPORT="$ROOT/screenshots/38-mr-vs-hive-crosscheck.txt"
MR="$OUT/carrier_month_delay.csv"
HIVE_CSV="$OUT/hive_carrier_month_delay.csv"
mkdir -p "$OUT" "$LOGS"
START=$SECONDS
"$ROOT/scripts/hive-exec.sh" "$ROOT/src/analytics/queries/mr_crosscheck_carrier_month.hql" 2> "$LOGS/mr_crosscheck_carrier_month.log" | tr '\t' ',' | grep -E '^[A-Za-z0-9]+,[0-9]{4},[0-9]+,' | LC_ALL=C sort -t, -k1,1 -k2,2n -k3,3n > "$HIVE_CSV"
HIVE_SECS=$((SECONDS-START))
TMP="$(mktemp -d)"
tail -n +2 "$MR" | cut -d, -f1-8 > "$TMP/mr.txt"
cut -d, -f1-8 "$HIVE_CSV" > "$TMP/hive.txt"
{
  echo "Hive cross-check query elapsed seconds: $HIVE_SECS"
  echo "MapReduce groups (rows): $(wc -l < "$TMP/mr.txt")"
  echo "Hive groups (rows):      $(wc -l < "$TMP/hive.txt")"
  echo "Compared columns: carrier, year, month, total_flights, cancelled_flights, operated_flights, delayed_flights, sum_arr_delay_min"
} | tee "$REPORT"
if diff "$TMP/mr.txt" "$TMP/hive.txt" > "$OUT/crosscheck_diff.txt"; then
  echo "RESULT: MATCH - the MapReduce output is identical to the Hive output" | tee -a "$REPORT"
  rm -rf "$TMP"
else
  echo "RESULT: MISMATCH - first differences:" | tee -a "$REPORT"
  head -n 20 "$OUT/crosscheck_diff.txt" | tee -a "$REPORT"
  rm -rf "$TMP"
  exit 1
fi
