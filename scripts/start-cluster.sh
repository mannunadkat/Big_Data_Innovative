#!/bin/bash
set -e
cd "$(dirname "$0")/../config"
docker-compose up -d
echo "Waiting for HDFS to leave safe mode..."
docker exec namenode hdfs dfsadmin -safemode wait
echo "Cluster is up."
docker ps --format "table {{.Names}}\t{{.Status}}"
