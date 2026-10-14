#!/bin/bash
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="$ROOT/output/prediction_model"
F="$ROOT/screenshots/26-hive-partition-rowcounts.txt"
TOTAL=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/ {s+=$2} END{print s+0}' "$F")
CANC=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/ {s+=$3} END{print s+0}' "$F")
OPER=$((TOTAL-CANC))
TEST_YEAR=$(cat "$OUT/test_year.txt")
echo "Reference from phase 5: rows=$TOTAL cancelled=$CANC operated=$OPER test_year=$TEST_YEAR"
fail=0
ok()   { echo "OK   $1"; }
bad()  { echo "FAIL $1"; fail=1; }
warn() { echo "WARN $1"; }
S="$OUT/split_summary.csv"
SUMALL=$(awk -F, 'NR>1{s+=$3} END{print s+0}' "$S")
TRAIN=$(awk -F, 'NR>1 && $1=="train"{s+=$3} END{print s+0}' "$S")
VAL=$(awk -F, 'NR>1 && $1=="validation"{s+=$3} END{print s+0}' "$S")
TEST=$(awk -F, 'NR>1 && $1=="test"{s+=$3} END{print s+0}' "$S")
[ "$SUMALL" = "$OPER" ] && ok "train+validation+test rows $SUMALL = operated flights $OPER" || bad "split rows $SUMALL vs operated flights $OPER"
VIOL=$(awk -F, -v ty="$TEST_YEAR" 'NR>1 && (($1=="test" && $2!=ty) || ($1!="test" && $2>=ty)) {n++} END{print n+0}' "$S")
[ "$VIOL" = "0" ] && ok "test = year $TEST_YEAR only; train and validation contain only earlier years" || bad "$VIOL split/year violations"
NTEST=$(awk -F, 'NR>1 && $1=="test"{n++} END{print n+0}' "$S")
[ "$NTEST" = "1" ] && ok "exactly one test year row" || bad "test year rows: $NTEST"
awk -v v="$VAL" -v t="$TRAIN" 'BEGIN{r=v/(v+t); exit !(r>=0.08 && r<=0.12)}' && ok "validation share of pre-test data is 8-12%" || bad "validation share outside 8-12% (val=$VAL train=$TRAIN)"
awk -F, 'NR>1 && ($5<5 || $5>40) {n++} END{exit n+0}' "$S" && ok "every split delay_pct is between 5 and 40" || warn "a split delay_pct is outside 5-40 (check the data)"
L="$OUT/model_level_stats.csv"
NL=$(awk -F, 'NR>1{n++} END{print n+0}' "$L")
[ "$NL" = "5" ] && ok "5 model levels present" || bad "model levels present: $NL"
BADP=$(awk -F, 'NR>1 && ($4<0 || $6>1 || $5<0 || $5>1) {n++} END{print n+0}' "$L")
[ "$BADP" = "0" ] && ok "all probabilities within [0,1]" || bad "$BADP levels with probabilities outside [0,1]"
EMPTY=$(awk -F, 'NR>1 && $2<=0 {n++} END{print n+0}' "$L")
[ "$EMPTY" = "0" ] && ok "every level has at least one key" || bad "$EMPTY empty levels"
GCOV=$(awk -F, '$1=="GLOBAL"{print $3}' "$L")
[ "$GCOV" = "$TRAIN" ] && ok "GLOBAL covers all $TRAIN train rows" || bad "GLOBAL covers $GCOV vs train rows $TRAIN"
OVER=$(awk -F, -v t="$TRAIN" 'NR>1 && $3>t {n++} END{print n+0}' "$L")
[ "$OVER" = "0" ] && ok "no level covers more than the train rows" || bad "$OVER levels cover more than the train rows"
L4COV=$(awk -F, '$1 ~ /^L4/{print $3}' "$L")
awk -v c="$L4COV" -v t="$TRAIN" 'BEGIN{exit !(c/t>=0.99)}' && ok "L4 covers at least 99% of train rows" || warn "L4 covers less than 99% of train rows"
GN=$(awk -F, 'NR>1{print $1}' "$OUT/model_global.csv")
[ "$GN" = "$TRAIN" ] && ok "model_global n = train rows" || bad "model_global n $GN vs train rows $TRAIN"
R="$OUT/model_l1_highest_risk.csv"
LOW=$(awk -F, 'NR>1 && $6<200 {n++} END{print n+0}' "$R")
[ "$LOW" = "0" ] && ok "highest-risk keys all have n >= 200" || bad "$LOW highest-risk keys with n < 200"
exit $fail
