#!/bin/bash
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
OUT="$ROOT/output/mapreduce"
LOG="$ROOT/screenshots/35-mr-carrier-month-delay-job.log"
HDFS_OUT=/flights/mr_output/carrier_month_delay
mkdir -p "$OUT" "$ROOT/screenshots"
docker exec namenode hdfs dfs -mkdir -p /flights/mr_output
docker exec namenode hdfs dfs -rm -r -f -skipTrash "$HDFS_OUT"
START=$SECONDS
docker exec namenode bash -c "hadoop jar /tmp/mrbuild/carrier-month-delay.jar flightdelay.CarrierMonthDelay '/flights/cleaned/year=*' $HDFS_OUT" 2>&1 | tee "$LOG"
echo "MR job elapsed seconds: $((SECONDS-START))" | tee -a "$LOG"
docker exec namenode hdfs dfs -ls -h "$HDFS_OUT" | tee "$ROOT/screenshots/36-mr-output-hdfs-ls.txt"
HEADER="carrier,year,month,total_flights,cancelled_flights,operated_flights,delayed_flights,sum_arr_delay_min,delay_pct,avg_arr_delay_min"
{ echo "$HEADER"; docker exec namenode bash -c "hdfs dfs -cat $HDFS_OUT/part-r-*" | LC_ALL=C sort -t, -k1,1 -k2,2n -k3,3n; } > "$OUT/carrier_month_delay.csv"
grep -E "Launched map tasks|Launched reduce tasks|Data-local map tasks|Rack-local map tasks|Map input records|Map output records|Combine input records|Combine output records|Reduce input groups|Reduce output records|MalformedLines|BadNumberLines|ParsedRecords|completed successfully|MR job elapsed" "$LOG" | tee "$ROOT/screenshots/37-mr-counters-summary.txt"
wc -l "$OUT/carrier_month_delay.csv"
head -n 5 "$OUT/carrier_month_delay.csv"
