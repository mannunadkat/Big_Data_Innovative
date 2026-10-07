# Cluster Setup Log

## Cluster Architecture
- Master Node: namenode + resourcemanager + historyserver containers
- Worker Node 1: datanode1 + nodemanager1
- Worker Node 2: datanode2 + nodemanager2
- Orchestrated via Docker Compose (config/docker-compose.yml, config/hadoop.env)
- Verified live: `hdfs dfsadmin -report` shows 2 live DataNodes;
  `yarn node -list` shows 2 active NodeManagers.
