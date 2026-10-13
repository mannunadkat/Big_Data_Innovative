#!/bin/bash
OUT="$(cd "$(dirname "$0")/../.." && pwd)/screenshots"
docker exec namenode hdfs dfs -du -h /flights/cleaned | tee "$OUT/19-hdfs-cleaned-du.txt"
docker exec namenode hdfs dfs -ls -R /flights/cleaned | grep -v "_SUCCESS" | tee -a "$OUT/19-hdfs-cleaned-du.txt"
for y in $(docker exec namenode hdfs dfs -ls /flights/raw | grep -o 'year=[0-9]*' | cut -d= -f2); do
  echo "== year $y sample ==" | tee -a "$OUT/20-cleaned-sample.txt"
  docker exec namenode bash -c "hdfs dfs -cat /flights/cleaned/year=$y/part-* | head -n 5" | tee -a "$OUT/20-cleaned-sample.txt"
  echo "cleaned row count year $y:" | tee -a "$OUT/21-cleaning-summary.txt"
  docker exec namenode bash -c "hdfs dfs -cat /flights/cleaned/year=$y/part-* | wc -l" | tee -a "$OUT/21-cleaning-summary.txt"
  echo "counters year $y:" | tee -a "$OUT/21-cleaning-summary.txt"
  grep -A 14 "Cleaning" "$OUT/18-clean-job-$y.log" | tee -a "$OUT/21-cleaning-summary.txt"
done
