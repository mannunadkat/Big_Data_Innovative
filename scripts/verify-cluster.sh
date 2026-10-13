#!/bin/bash
# Captures cluster health proofs into screenshots/ as text files
OUT="$(dirname "$0")/../screenshots"
mkdir -p "$OUT"
echo "== HDFS report ==" | tee "$OUT/01-hdfs-dfsadmin-report.txt"
docker exec namenode hdfs dfsadmin -report | tee -a "$OUT/01-hdfs-dfsadmin-report.txt"
echo "== YARN nodes ==" | tee "$OUT/02-yarn-node-list.txt"
docker exec resourcemanager yarn node -list -all | tee -a "$OUT/02-yarn-node-list.txt"
echo "== Containers ==" | tee "$OUT/03-docker-ps.txt"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tee -a "$OUT/03-docker-ps.txt"
