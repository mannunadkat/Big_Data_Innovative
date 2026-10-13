#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER=3.1.3
TARBALL=apache-hive-$VER-bin.tar.gz
URL=https://archive.apache.org/dist/hive/hive-$VER/$TARBALL
if docker exec namenode test -x /opt/hive-data/apache-hive-$VER-bin/bin/hive; then
  echo "Hive already installed in the hive_data volume."
else
  TMP="$(mktemp -d)"
  echo "Downloading $URL (a few hundred MB) ..."
  curl -fL --retry 3 -o "$TMP/$TARBALL" "$URL"
  docker cp "$TMP/$TARBALL" namenode:/opt/hive-data/$TARBALL
  docker exec namenode bash -c "cd /opt/hive-data && tar xzf $TARBALL && rm -f $TARBALL"
  rm -rf "$TMP"
fi
docker exec namenode mkdir -p /opt/hive-data/conf
docker cp "$ROOT/config/hive/hive-env.sh" namenode:/opt/hive-data/hive-env.sh
docker cp "$ROOT/config/hive/hive-site.xml" namenode:/opt/hive-data/conf/hive-site.xml
docker cp "$ROOT/scripts/hive-bootstrap-inside.sh" namenode:/tmp/hive-bootstrap-inside.sh
docker exec namenode bash /tmp/hive-bootstrap-inside.sh
docker cp "$ROOT/dataset/reference/carriers.csv" namenode:/tmp/carriers.csv
docker exec namenode hdfs dfs -put -f /tmp/carriers.csv /flights/reference/carriers/carriers.csv
docker exec namenode bash -c "source /opt/hive-data/hive-env.sh && hive --version" 2>&1 | head -n 5
