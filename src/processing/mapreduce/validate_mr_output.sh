#!/bin/bash
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
F="$ROOT/screenshots/26-hive-partition-rowcounts.txt"
LOG="$ROOT/screenshots/35-mr-carrier-month-delay-job.log"
CSV="$ROOT/output/mapreduce/carrier_month_delay.csv"
TOTAL=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/ {s+=$2} END{print s+0}' "$F")
CANC=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/ {s+=$3} END{print s+0}' "$F")
YEARS=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/ {n++} END{print n+0}' "$F")
echo "Reference from phase 5: rows=$TOTAL cancelled=$CANC years=$YEARS"
fail=0
ok()  { echo "OK   $1"; }
bad() { echo "FAIL $1"; fail=1; }
counter() { grep -m1 "$1" "$LOG" | sed 's/.*=//' | tr -d ' \r'; }
MAPIN=$(counter "Map input records")
CIN=$(counter "Combine input records")
COUT=$(counter "Combine output records")
MAL=$(counter "MalformedLines"); MAL=${MAL:-0}
BADN=$(counter "BadNumberLines"); BADN=${BADN:-0}
S_TOTAL=$(awk -F, 'NR>1{s+=$4} END{print s+0}' "$CSV")
S_CANC=$(awk -F, 'NR>1{s+=$5} END{print s+0}' "$CSV")
BADROWS=$(awk -F, 'NR>1 && ($5+$6!=$4 || $9<0 || $9>100) {n++} END{print n+0}' "$CSV")
DISTINCT_YEARS=$(awk -F, 'NR>1{print $2}' "$CSV" | sort -u | wc -l | tr -d ' ')
[ "$MAPIN" = "$TOTAL" ]   && ok "Map input records $MAPIN = Hive row total $TOTAL" || bad "Map input records $MAPIN vs expected $TOTAL"
[ "$S_TOTAL" = "$TOTAL" ] && ok "sum(total_flights) $S_TOTAL = $TOTAL" || bad "sum(total_flights) $S_TOTAL vs $TOTAL"
[ "$S_CANC" = "$CANC" ]   && ok "sum(cancelled) $S_CANC = $CANC" || bad "sum(cancelled) $S_CANC vs $CANC"
[ "$BADROWS" = "0" ]      && ok "every row: cancelled+operated=total and 0<=delay_pct<=100" || bad "$BADROWS inconsistent rows"
[ "$DISTINCT_YEARS" = "$YEARS" ] && ok "years in output: $DISTINCT_YEARS" || bad "years in output $DISTINCT_YEARS vs $YEARS"
[ "$MAL" = "0" ] && [ "$BADN" = "0" ] && ok "no malformed or bad-number lines" || bad "MalformedLines=$MAL BadNumberLines=$BADN"
if [ -n "$CIN" ] && [ -n "$COUT" ] && [ "$CIN" -gt "$COUT" ]; then ok "combiner effective: $CIN records in, $COUT out"; else bad "combiner did not reduce records (in=$CIN out=$COUT)"; fi
exit $fail
