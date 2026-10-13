#!/bin/bash
OUT="$(cd "$(dirname "$0")/../.." && pwd)/screenshots"
mkdir -p "$OUT"
docker exec namenode hdfs dfs -ls -R -h /flights/raw | tee "$OUT/14-hdfs-raw-ls.txt"
docker exec namenode hdfs dfs -du -h /flights/raw | tee "$OUT/15-hdfs-raw-du.txt"
docker exec namenode hdfs fsck /flights/raw -files -blocks -locations > "$OUT/16-hdfs-raw-fsck.txt"
head -n 60 "$OUT/16-hdfs-raw-fsck.txt"
tail -n 25 "$OUT/16-hdfs-raw-fsck.txt"
docker exec namenode hdfs dfsadmin -report | tee "$OUT/17-hdfs-report-after-ingest.txt"
