#!/bin/bash
# Usage: hive-exec-vars.sh <file.hql> [--hivevar name=value ...]
set -e
f="$1"
shift
b=$(basename "$f")
docker cp "$f" namenode:/tmp/"$b"
docker exec namenode bash -c "source /opt/hive-data/hive-env.sh && hive $* -f /tmp/$b"
