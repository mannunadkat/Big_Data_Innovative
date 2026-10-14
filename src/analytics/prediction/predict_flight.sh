#!/bin/bash
# Usage: predict_flight.sh <CARRIER> <ORIGIN> <DEST> <MONTH 1-12> <SCHEDULED_DEP_HOUR 0-23>
set -e
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
if [ $# -ne 5 ]; then echo "Usage: $0 <CARRIER> <ORIGIN> <DEST> <MONTH 1-12> <SCHEDULED_DEP_HOUR 0-23>" >&2; exit 2; fi
C=$(echo "$1" | tr 'a-z' 'A-Z'); O=$(echo "$2" | tr 'a-z' 'A-Z'); D=$(echo "$3" | tr 'a-z' 'A-Z')
MONTH="$4"; HOUR="$5"
[[ "$C" =~ ^[A-Z0-9]{2}$ ]] || { echo "Carrier must be a 2-character code (for example AA)" >&2; exit 2; }
[[ "$O" =~ ^[A-Z]{3}$ ]] || { echo "Origin must be a 3-letter airport code (for example JFK)" >&2; exit 2; }
[[ "$D" =~ ^[A-Z]{3}$ ]] || { echo "Destination must be a 3-letter airport code (for example LAX)" >&2; exit 2; }
[[ "$MONTH" =~ ^([1-9]|1[0-2])$ ]] || { echo "Month must be a plain integer 1-12" >&2; exit 2; }
[[ "$HOUR" =~ ^([0-9]|1[0-9]|2[0-3])$ ]] || { echo "Hour must be a plain integer 0-23" >&2; exit 2; }
BUCKET=$((HOUR / 4))
THR=$(cat "$ROOT/output/prediction_results/chosen_threshold.txt")
TMPD=$(mktemp -d)
Q="$TMPD/predict_query_$$.hql"
cat > "$Q" <<EOF
USE flightdb;
SET hive.cli.print.header=false;
SELECT t.lvl, t.n, t.p FROM (
  SELECT 1 AS rnk, 'L1' AS lvl, n, p FROM model_l1 WHERE carrier='$C' AND origin='$O' AND dest='$D' AND flight_month=$MONTH AND hour_bucket=$BUCKET
  UNION ALL SELECT 2, 'L2', n, p FROM model_l2 WHERE carrier='$C' AND origin='$O' AND flight_month=$MONTH AND hour_bucket=$BUCKET
  UNION ALL SELECT 3, 'L3', n, p FROM model_l3 WHERE origin='$O' AND hour_bucket=$BUCKET
  UNION ALL SELECT 4, 'L4', n, p FROM model_l4 WHERE carrier='$C' AND hour_bucket=$BUCKET
  UNION ALL SELECT 5, 'GLOBAL', n, p FROM model_global
) t ORDER BY t.rnk LIMIT 1;
EOF
RES=$("$ROOT/scripts/hive-exec.sh" "$Q" 2>/dev/null | tr '\t' ',' | tail -n 1)
rm -rf "$TMPD"
if ! echo "$RES" | grep -Eq '^(L[1-4]|GLOBAL),[0-9]+,[0-9.]+'; then echo "Could not read a model row (got: $RES)" >&2; exit 1; fi
IFS=, read -r LVL N P <<< "$RES"
PCT=$(awk -v p="$P" 'BEGIN{printf "%.1f", p*100}')
if awk -v p="$P" -v t="$THR" 'BEGIN{exit !(p>=t)}'; then VERDICT="LIKELY DELAYED (15+ minutes late)"; else VERDICT="LIKELY ON TIME"; fi
echo "Flight: $C $O -> $D, month $MONTH, scheduled departure hour $HOUR (time bucket $BUCKET)"
echo "Model level used: $LVL (based on $N historical flights)"
echo "Estimated probability of arriving 15+ minutes late: $PCT%"
echo "Decision threshold (chosen on validation data): $THR"
echo "Prediction: $VERDICT"
echo "Note: a statistical estimate from historical frequencies, not a guarantee."
