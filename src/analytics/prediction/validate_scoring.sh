#!/bin/bash
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
R="$ROOT/output/prediction_results"
P="$ROOT/output/prediction_model"
fail=0
ok()   { echo "OK   $1"; }
bad()  { echo "FAIL $1"; fail=1; }
warn() { echo "WARN $1"; }
for f in scored_counts.csv threshold_sweep_validation.csv threshold_sweep_test.csv test_metrics.csv level_usage_test.csv calibration_test.csv carrier_performance_test.csv hour_bucket_performance_test.csv chosen_threshold.txt; do
  if [ -s "$R/$f" ]; then ok "$f exists and is non-empty"; else bad "$f missing or empty"; fi
done
[ "$fail" = "0" ] || exit 1
CHOSEN=$(cat "$R/chosen_threshold.txt")
A=$(awk -F, 'NR>1 && ($1=="validation"||$1=="test"){print $1","$2","$3","$4}' "$R/scored_counts.csv" | sort)
B=$(awk -F, 'NR>1 && ($1=="validation"||$1=="test"){print $1","$2","$3","$4}' "$P/split_summary.csv" | sort)
if [ -n "$A" ] && [ "$A" = "$B" ]; then ok "scored rows and delayed counts equal the phase 8 split summary (validation, test)"; else bad "scored counts differ from the phase 8 split summary"; fi
TESTROWS=$(awk -F, 'NR>1 && $1=="test"{s+=$3} END{print s+0}' "$P/split_summary.csv")
TESTDPCT=$(awk -F, 'NR>1 && $1=="test"{r+=$3; d+=$4} END{printf "%.2f", 100.0*d/r}' "$P/split_summary.csv")
read TP FP FN TN TOT ACC PREC REC F1 DPCT BACC BF1 LIFT <<< "$(awk -F, 'NR==2{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13}' "$R/test_metrics.csv")"
echo "Test metrics at threshold $CHOSEN: tp=$TP fp=$FP fn=$FN tn=$TN rows=$TOT acc=$ACC prec=$PREC recall=$REC f1=$F1 baseline_acc=$BACC baseline_f1=$BF1 lift=$LIFT"
if [ "$TOT" = "$((TP+FP+FN+TN))" ] && [ "$TOT" = "$TESTROWS" ]; then ok "confusion matrix sums to $TOT = test rows"; else bad "confusion matrix total $TOT vs test rows $TESTROWS"; fi
if awk -v a="$ACC" -v tp="$TP" -v tn="$TN" -v t="$TOT" 'BEGIN{d=a-(tp+tn)/t; if(d<0)d=-d; exit !(d<0.0002)}'; then ok "accuracy matches the confusion matrix"; else bad "accuracy does not match the confusion matrix"; fi
if awk -v a="$DPCT" -v b="$TESTDPCT" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d<0.011)}'; then ok "test delay_pct $DPCT matches the split summary ($TESTDPCT)"; else bad "test delay_pct $DPCT vs split summary $TESTDPCT"; fi
SW=$(awk -F, -v t="$CHOSEN" 'NR>1 && $1+0==t+0 {print $2","$3","$4","$5}' "$R/threshold_sweep_test.csv")
if [ "$SW" = "$TP,$FP,$FN,$TN" ]; then ok "test metrics equal the test sweep row at the chosen threshold"; else bad "test metrics ($TP,$FP,$FN,$TN) differ from the sweep row ($SW)"; fi
for s in validation test; do
  N=$(awk -F, 'NR>1{n++} END{print n+0}' "$R/threshold_sweep_$s.csv")
  if [ "$N" = "23" ]; then ok "$s sweep has 23 thresholds"; else bad "$s sweep has $N rows"; fi
done
MAXF1=$(awk -F, 'NR>1 && $8 ~ /^[0-9.]+$/ && $8+0>m {m=$8+0} END{print m+0}' "$R/threshold_sweep_validation.csv")
F1AT=$(awk -F, -v t="$CHOSEN" 'NR>1 && $1+0==t+0 {print $8+0}' "$R/threshold_sweep_validation.csv")
if awk -v a="$MAXF1" -v b="$F1AT" 'BEGIN{exit !(a==b && b>0)}'; then ok "chosen threshold $CHOSEN has the maximum validation F1 ($MAXF1)"; else bad "chosen threshold F1 $F1AT vs validation maximum $MAXF1"; fi
LV=$(awk -F, 'NR>1{s+=$2} END{print s+0}' "$R/level_usage_test.csv")
LP=$(awk -F, 'NR>1{s+=$3} END{print s+0}' "$R/level_usage_test.csv")
LBAD=$(awk -F, 'NR>1 && $1 !~ /^(GLOBAL|L1|L2|L3|L4)$/ {n++} END{print n+0}' "$R/level_usage_test.csv")
if [ "$LV" = "$TOT" ]; then ok "level usage covers all $TOT test flights"; else bad "level usage flights $LV vs $TOT"; fi
if awk -v p="$LP" 'BEGIN{exit !(p>=99.9 && p<=100.1)}'; then ok "level usage percentages sum to $LP"; else bad "level usage percentages sum to $LP"; fi
if [ "$LBAD" = "0" ]; then ok "only known back-off levels used"; else bad "$LBAD unknown level labels"; fi
CV=$(awk -F, 'NR>1{s+=$2} END{print s+0}' "$R/calibration_test.csv")
CBAD=$(awk -F, 'NR>1 && ($3<0 || $3>1 || $4<0 || $4>1) {n++} END{print n+0}' "$R/calibration_test.csv")
if [ "$CV" = "$TOT" ]; then ok "calibration bins cover all $TOT test flights"; else bad "calibration flights $CV vs $TOT"; fi
if [ "$CBAD" = "0" ]; then ok "calibration probabilities and rates within [0,1]"; else bad "$CBAD calibration rows out of range"; fi
NC=$(awk -F, 'NR>1{n++} END{print n+0}' "$R/carrier_performance_test.csv")
NH=$(awk -F, 'NR>1{n++} END{print n+0}' "$R/hour_bucket_performance_test.csv")
if [ "$NC" -ge 1 ] && [ "$NC" -le 12 ]; then ok "carrier performance rows: $NC"; else bad "carrier performance rows: $NC"; fi
if [ "$NH" = "6" ]; then ok "hour bucket performance rows: 6"; else bad "hour bucket performance rows: $NH"; fi
if [ "$CHOSEN" = "0.06" ] || [ "$CHOSEN" = "0.50" ]; then warn "chosen threshold $CHOSEN is at the edge of the sweep grid"; fi
if awk -v a="$ACC" -v b="$BACC" 'BEGIN{exit !(a>b)}'; then ok "accuracy $ACC beats the majority baseline $BACC"; else warn "accuracy $ACC does not beat the majority baseline $BACC (expected when delays are the minority class and the threshold maximises F1; judge the model on precision, recall, F1 and lift instead)"; fi
if awk -v a="$F1" -v b="$BF1" 'BEGIN{exit !(a>b)}'; then ok "F1 $F1 beats the always-delayed baseline $BF1"; else warn "F1 $F1 does not beat the always-delayed baseline $BF1"; fi
if awk -v a="$LIFT" 'BEGIN{exit !(a>1.0)}'; then ok "precision lift over the base delay rate: $LIFT"; else warn "precision lift is $LIFT (not above 1.0)"; fi
exit $fail
