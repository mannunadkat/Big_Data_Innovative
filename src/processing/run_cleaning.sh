#!/bin/bash
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
JAR=/opt/hadoop-3.2.1/share/hadoop/tools/lib/hadoop-streaming-3.2.1.jar
mkdir -p "$ROOT/screenshots"
"$ROOT/src/processing/ensure_python.sh"
docker cp "$ROOT/src/processing/clean_mapper.py" namenode:/tmp/clean_mapper.py
docker exec namenode hdfs dfs -mkdir -p /flights/cleaned
years=$(docker exec namenode hdfs dfs -ls /flights/raw | grep -o 'year=[0-9]*' | cut -d= -f2)
for y in $years; do
  echo "=== Cleaning year $y ==="
  docker exec namenode hdfs dfs -rm -r -f /flights/cleaned/year=$y
  docker exec namenode hadoop jar $JAR \
    -D mapreduce.job.reduces=0 \
    -D mapreduce.output.textoutputformat.separator="" \
    -D mapreduce.job.name="flight-clean-$y" \
    -files /tmp/clean_mapper.py \
    -mapper "python3 clean_mapper.py" \
    -input /flights/raw/year=$y \
    -output /flights/cleaned/year=$y 2>&1 | tee "$ROOT/screenshots/18-clean-job-$y.log"
done
echo "Cleaning complete."
