#!/bin/bash
# Usage: final-verification.sh <label>   (for example before-restart or after-restart)
set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LABEL="${1:-run}"
OUT="$ROOT/screenshots/final/$LABEL"
mkdir -p "$OUT"
fail=0
ok()   { echo "OK   $1"; }
bad()  { echo "FAIL $1"; fail=1; }
warn() { echo "WARN $1"; }
echo "Final verification [$LABEL] at $(date '+%Y-%m-%d %H:%M:%S')" | tee "$OUT/00-run-info.txt"

echo "--- containers ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tee "$OUT/01-docker-ps.txt"
UP=$(docker ps --format '{{.Names}}' | grep -cE '^(namenode|resourcemanager|historyserver|datanode1|datanode2|nodemanager1|nodemanager2)$')
[ "$UP" = "7" ] && ok "all 7 cluster containers are up" || bad "only $UP of 7 cluster containers are up"

echo "--- HDFS cluster status ---"
docker exec namenode hdfs dfsadmin -report > "$OUT/02-hdfs-dfsadmin-report.txt" 2>&1
grep -E "Configured Capacity|^DFS Used|Live datanodes|^Name:|^Hostname" "$OUT/02-hdfs-dfsadmin-report.txt" | head -n 30
LIVE=$(grep -m1 "Live datanodes" "$OUT/02-hdfs-dfsadmin-report.txt" | grep -o '([0-9]*)' | tr -d '()')
[ "$LIVE" = "2" ] && ok "HDFS reports 2 live DataNodes" || bad "HDFS live DataNodes: ${LIVE:-none}"
DN_USED=$(grep '^DFS Used:' "$OUT/02-hdfs-dfsadmin-report.txt" | tail -n 2 | awk '{print $3}')
NDN=$(echo "$DN_USED" | grep -c .)
ZERO=$(echo "$DN_USED" | awk '$1+0<=0{n++} END{print n+0}')
if [ "$NDN" = "2" ] && [ "$ZERO" = "0" ]; then ok "both DataNodes hold data (DFS Used > 0)"; else bad "DataNode usage check failed (values: $(echo $DN_USED))"; fi

echo "--- YARN cluster status ---"
docker exec resourcemanager yarn node -list -all > "$OUT/03-yarn-node-list.txt" 2>&1
tail -n 8 "$OUT/03-yarn-node-list.txt"
RUN=$(grep -c RUNNING "$OUT/03-yarn-node-list.txt")
[ "$RUN" = "2" ] && ok "YARN reports 2 RUNNING NodeManagers" || bad "YARN RUNNING NodeManagers: $RUN"

echo "--- daemons per node (jps) ---"
JPS="$OUT/04-jps-all-nodes.txt"
: > "$JPS"
for c in namenode resourcemanager historyserver datanode1 datanode2 nodemanager1 nodemanager2; do
  echo "== $c ==" >> "$JPS"
  docker exec $c jps >> "$JPS" 2>&1 || echo "(jps failed on $c)" >> "$JPS"
done
cat "$JPS"
NNC=$(grep -cE ' NameNode$' "$JPS"); DNC=$(grep -cE ' DataNode$' "$JPS")
RMC=$(grep -cE ' ResourceManager$' "$JPS"); NMC=$(grep -cE ' NodeManager$' "$JPS")
if [ "$NNC" = "1" ] && [ "$DNC" = "2" ] && [ "$RMC" = "1" ] && [ "$NMC" = "2" ]; then ok "daemons: 1 NameNode, 2 DataNodes, 1 ResourceManager, 2 NodeManagers"; else warn "daemon counts NameNode=$NNC DataNode=$DNC ResourceManager=$RMC NodeManager=$NMC"; fi

echo "--- storage distribution ---"
docker exec namenode hdfs dfs -du -h /flights > "$OUT/05-hdfs-flights-du.txt" 2>&1
cat "$OUT/05-hdfs-flights-du.txt"
FS=$(mktemp)
docker exec namenode hdfs fsck /flights -files -blocks -locations > "$FS" 2>&1
grep -E "Status:|Number of data-nodes|Total blocks|Average block replication|Default replication|Under-replicated|Corrupt|Missing" "$FS" | tee "$OUT/06-hdfs-fsck-summary.txt"
head -n 60 "$FS" > "$OUT/06b-hdfs-fsck-excerpt.txt"
grep -q "Status: HEALTHY" "$FS" && ok "fsck: /flights is HEALTHY" || bad "fsck: /flights is not HEALTHY"
AVGREP=$(grep -m1 "Average block replication" "$FS" | awk '{print $NF}')
if awk -v r="${AVGREP:-0}" 'BEGIN{exit !(r>=1.99)}'; then ok "average block replication $AVGREP"; else bad "average block replication ${AVGREP:-unknown}"; fi
rm -f "$FS"

echo "--- Hive tables ---"
TQ=$(mktemp)
printf 'USE flightdb;\nSHOW TABLES;\n' > "$TQ"
"$ROOT/scripts/hive-exec.sh" "$TQ" 2>/dev/null > "$OUT/07-hive-tables.txt"
rm -f "$TQ"
cat "$OUT/07-hive-tables.txt"
for t in flights_cleaned carriers_ref flights_split model_l1 model_l2 model_l3 model_l4 model_global flights_scored; do
  if grep -qx "$t" "$OUT/07-hive-tables.txt"; then ok "Hive table $t exists"; else bad "Hive table $t missing"; fi
done

echo "--- row counts: Hive vs the committed phase 5 reference ---"
RC=$(mktemp)
"$ROOT/scripts/hive-exec.sh" "$ROOT/src/analytics/queries/validation_counts.hql" 2>/dev/null > "$RC"
cp "$RC" "$OUT/08-hive-validation-counts.txt"
cat "$RC"
A=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/' "$RC")
B=$(awk -F'\t' 'NR>1 && $1 ~ /^[0-9]+$/' "$ROOT/screenshots/26-hive-partition-rowcounts.txt")
if [ -n "$A" ] && [ "$A" = "$B" ]; then ok "per-year row, cancelled and delayed counts equal the phase 5 reference"; else bad "row counts differ from screenshots/26"; fi
rm -f "$RC"

echo "--- reproducibility: re-run one analytics query and compare with the committed CSV ---"
AS=$(mktemp)
"$ROOT/scripts/hive-exec.sh" "$ROOT/src/analytics/queries/airline_delay_summary.hql" 2>/dev/null | tr '\t' ',' | LC_ALL=C sort > "$AS"
LC_ALL=C sort "$ROOT/output/airline_airport/airline_delay_summary.csv" > "$AS.ref"
cp "$AS" "$OUT/09-airline-delay-summary-rerun.csv"
if [ -s "$AS" ] && diff -q "$AS" "$AS.ref" > /dev/null; then ok "airline_delay_summary re-run is identical to the committed output (line order ignored)"; else bad "airline_delay_summary re-run differs from output/airline_airport/airline_delay_summary.csv"; fi
rm -f "$AS" "$AS.ref"

echo "--- prediction check: single-flight predictor vs the committed demo ---"
read C O D M B <<< "$(awk -F, 'NR==2{print $1,$2,$3,$4,$5}' "$ROOT/output/prediction_model/model_l1_most_common.csv")"
"$ROOT/src/analytics/prediction/predict_flight.sh" "$C" "$O" "$D" "$M" $((B*4+1)) > "$OUT/10-predict-flight.txt" 2>&1
cat "$OUT/10-predict-flight.txt"
NOW=$(grep -m1 "Estimated probability" "$OUT/10-predict-flight.txt")
REF=$(grep -m1 "Estimated probability" "$ROOT/output/prediction_results/demo_predictions.txt")
if [ -n "$NOW" ] && [ "$NOW" = "$REF" ]; then ok "predictor output equals the committed demo 1"; else bad "predictor output differs from the committed demo (now: $NOW | ref: $REF)"; fi

echo
if [ "$fail" = "0" ]; then echo "ALL CHECKS PASSED [$LABEL]"; else echo "SOME CHECKS FAILED [$LABEL]"; fi
exit $fail
