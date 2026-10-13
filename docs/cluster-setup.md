# Cluster Setup Log

## Cluster Architecture
- Master Node: namenode + resourcemanager + historyserver containers
- Worker Node 1: datanode1 + nodemanager1
- Worker Node 2: datanode2 + nodemanager2
- Orchestrated via Docker Compose (config/docker-compose.yml, config/hadoop.env)
- Verified live: `hdfs dfsadmin -report` shows 2 live DataNodes;
  `yarn node -list` shows 2 active NodeManagers.

## Cluster Operations
- Start: scripts/start-cluster.sh  |  Stop: scripts/stop-cluster.sh
- Health proofs: scripts/verify-cluster.sh (writes to screenshots/)

## Storage Distribution Proof
- Uploaded a ~10 MB file to /demo/wc.txt with a 1 MB block size (~10 blocks)
- `hdfs fsck -files -blocks -locations` shows every block replicated on both
  DataNodes (replication factor 2, 2 DataNodes)
- Result: 10,600,000 bytes split into 11 blocks (10 x 1 MB + 1 x 114,240 B), every
  block `Live_repl=2` with locations on both 172.18.0.3 (datanode1) and
  172.18.0.5 (datanode2). DFS Used after upload: 10.26 MB on each DataNode.
- Note: with replication factor 2 and exactly 2 DataNodes, every block necessarily
  lives on both nodes (full mirroring). Adding more DataNodes would spread blocks
  so that each node holds only a subset.
- Evidence: screenshots/04 to 07

## Distributed Processing Proof
- Ran Hadoop MapReduce WordCount on /demo/wc.txt via YARN
- Multiple map tasks (one per block) executed across the NodeManagers
- Result: job_1791876482993_0001 FINISHED / SUCCEEDED; 11 map tasks (one per
  block) + 1 reduce task; 7 distinct words, each counted 200000 times
- Evidence: screenshots/08 to 10 (plus UI screenshots 11 to 13)
  - 11 / 11b: NameNode UI overview + summary (2 live nodes, 0 dead)
  - 13 / 13b: ResourceManager UI, word count application FINISHED / SUCCEEDED
    (cluster metrics show 2 active nodes)
