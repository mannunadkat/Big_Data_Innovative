# Viva Live Demonstration Script

This numbered guide provides the exact sequence of commands and inspection steps for the project evaluation and viva demonstration.

---

## Live Demonstration Sequence

### Step 1: Start and Verify the Cluster
```bash
./scripts/start-cluster.sh
```
* **What it proves**: Launches the 3-node containerized Hadoop cluster and confirms that HDFS has exited safe mode.
* **What to point at**: The console output displaying `Safe mode is OFF` and all 7 containers in `healthy` status.

---

### Step 2: HDFS Node Status & Health
```bash
docker exec namenode hdfs dfsadmin -report
```
* **What it proves**: Verifies that the NameNode recognizes both DataNodes and that HDFS storage is active.
* **What to point at**: The `Live datanodes (2)` header and the balanced `DFS Used` values on both worker IP addresses (`172.18.0.3` and `172.18.0.5`).

---

### Step 3: YARN Cluster Node Registration
```bash
docker exec resourcemanager yarn node -list -all
```
* **What it proves**: Verifies that the ResourceManager has registered both NodeManager worker containers for distributed compute.
* **What to point at**: `Total Nodes: 2` with both node IDs displaying state `RUNNING`.

---

### Step 4: Cleaned Data Partition Structure on HDFS
```bash
docker exec namenode hdfs dfs -ls -R -h /flights/cleaned
```
* **What it proves**: Proves that the cleaned flight records are stored in HDFS and partitioned by `year=2009` and `year=2010`.
* **What to point at**: The directory paths `/flights/cleaned/year=2009` and `/flights/cleaned/year=2010` showing 23-column cleaned part files.

---

### Step 5: HDFS Block Replication & Multi-Node Distribution
```bash
docker exec namenode hdfs fsck /flights/cleaned -files -blocks -locations
```
* **What it proves**: Demonstrates distributed storage and block replication (`replication=2`).
* **What to point at**: The block location listings explicitly showing both DataNodes (`172.18.0.3:9866` and `172.18.0.5:9866`) for every block, with overall status `HEALTHY`.

---

### Step 6: Distributed Hive Analytics Query Execution
```bash
./scripts/hive-exec.sh src/analytics/queries/airline_delay_summary.hql
```
* **What it proves**: Demonstrates real-time distributed SQL analytics over HDFS data using MapReduce on YARN.
* **What to point at**: The console log printing `Launching Job ... Tracking URL = http://resourcemanager:8088/proxy/application_...` showing map/reduce progress percentages and final aggregation results.

---

### Step 7: Single-Flight Prediction Tool & Back-off Fallback
```bash
# 7a. Known flight (L1 level match): Hawaiian Airlines OGG -> HNL in September at 13:00 (Bucket 3)
./src/analytics/prediction/predict_flight.sh HA OGG HNL 9 13

# 7b. Unseen flight (falls back to global historical rate)
./src/analytics/prediction/predict_flight.sh XX AAA BBB 1 10
```
* **What it proves**: Demonstrates the interactive flight delay predictor querying Hive model tables on the cluster.
* **What to point at**: 
  - In 7a, point out `Model level used: L1 (based on 432 historical flights)`, estimated probability `6.0%`, decision threshold `0.18`, and verdict `LIKELY ON TIME`.
  - In 7b, point out `Model level used: GLOBAL (based on 5693875 historical flights)`, estimated probability `18.5%`, and verdict `LIKELY DELAYED`.

---

### Step 8: Analytics Visualizations and Prediction Results
* **Action**: Open [`output/charts/`](../output/charts/) and [`docs/prediction-results.md`](prediction-results.md).
* **What it proves**: Confirms the analytical conclusions (delay share by airline, airport, month, route, and weather) and the honest model evaluation on the 2010 test set.
* **What to point at**: The 13 generated charts, the test confusion matrix (6,321,388 flights), test recall of `63.17%`, precision lift of `1.215x`, and the calibration curve.

---

### Step 9: Web UIs for Real-Time Cluster Monitoring
* **NameNode Web UI**: [http://localhost:9870](http://localhost:9870)  
  *Point at*: `Datanodes` tab (2 live nodes) and `Utilities -> Browse the file system` showing `/flights/raw`, `/flights/cleaned`, and `/flights/mr_output`.
* **ResourceManager Web UI**: [http://localhost:8088](http://localhost:8088)  
  *Point at*: `Nodes` tab (2 active NodeManagers) and `Applications` view showing finished MapReduce applications with state `SUCCEEDED`.

---

> [!TIP]
> ### Viva Troubleshooting Guide ("If Something Goes Wrong")
> 1. **DataNodes slow to register**: If `hdfs dfsadmin -report` shows 0 or 1 DataNode immediately after cluster start, wait 30–60 seconds. DataNodes require approximately 20–30 seconds after container start to perform handshake and block reporting to NameNode.
> 2. **Hive Metastore Lock**: If Hive prints an error mentioning Derby locks or `metastore_db`, verify that no other terminal or script is running a Hive query. Embedded Derby allows **only ONE active session at a time**.
> 3. **Memory Limits**: Ensure Docker has at least 8 GB of RAM allocated in Docker Desktop settings to comfortably support 7 concurrent containers.
