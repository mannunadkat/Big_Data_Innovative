#!/bin/bash
set -e
f="$1"
b=$(basename "$f")
docker cp "$f" namenode:/tmp/"$b"
docker exec namenode bash -c "source /opt/hive-data/hive-env.sh && hive -f /tmp/$b"
