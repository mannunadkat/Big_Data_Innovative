#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="$ROOT/output/prediction_results"
P="$ROOT/output/prediction_model"
PF="$ROOT/src/analytics/prediction/predict_flight.sh"
read C O D M B <<< "$(awk -F, 'NR==2{print $1,$2,$3,$4,$5}' "$P/model_l1_most_common.csv")"
read C2 O2 D2 M2 B2 <<< "$(awk -F, 'NR==2{print $1,$2,$3,$4,$5}' "$P/model_l1_highest_risk.csv")"
{
  echo "### Demo 1: the most common carrier/route/month/time combination in the training data"
  "$PF" "$C" "$O" "$D" "$M" $((B*4+1))
  echo
  echo "### Demo 2: the highest-risk combination (at least 200 training flights)"
  "$PF" "$C2" "$O2" "$D2" "$M2" $((B2*4+1))
  echo
  echo "### Demo 3: a combination never seen in training (expect fallback to the global rate)"
  "$PF" XX AAA BBB 1 10
} 2>&1 | tee "$OUT/demo_predictions.txt"
cp "$OUT/demo_predictions.txt" "$ROOT/screenshots/53-predict-flight-demo.txt"
