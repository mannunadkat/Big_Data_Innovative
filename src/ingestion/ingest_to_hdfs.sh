#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RAW_DIR="$ROOT/dataset/raw"
HDFS_RAW="/flights/raw"
shopt -s nullglob
files=("$RAW_DIR"/*.csv)
if [ ${#files[@]} -eq 0 ]; then echo "No CSV files in $RAW_DIR"; exit 1; fi
docker exec namenode hdfs dfs -mkdir -p "$HDFS_RAW"
for f in "${files[@]}"; do
  base=$(basename "$f" .csv)
  year="$base"
  echo "Ingesting $f -> $HDFS_RAW/year=$year/"
  docker cp "$f" namenode:/tmp/$base.csv
  docker exec namenode hdfs dfs -mkdir -p "$HDFS_RAW/year=$year"
  docker exec namenode hdfs dfs -put -f /tmp/$base.csv "$HDFS_RAW/year=$year/$base.csv"
  docker exec namenode rm -f /tmp/$base.csv
done
echo "Ingestion complete."
