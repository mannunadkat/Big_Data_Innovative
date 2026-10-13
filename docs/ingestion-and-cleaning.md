# Flight Delay Ingestion & Cleaning Report

## Overview
Phase 4 implements scalable ingestion of raw Kaggle flight delay data (2009–2010) into Apache HDFS partitioned by year, verifies block placement and replication across both DataNodes, and executes distributed map-only Hadoop Streaming cleaning jobs using Python.

---

## 1. Commands Executed

### Ingestion to HDFS
```bash
./src/ingestion/ingest_to_hdfs.sh
```
- Creates HDFS directory `/flights/raw/year=YYYY/`.
- Copies local raw CSVs (`dataset/raw/2009.csv`, `2010.csv`) into the NameNode container and uploads them to HDFS.

### Ingestion Verification
```bash
./src/ingestion/verify_ingestion.sh
```
- Verifies directory tree, disk usage (`du -h`), block placement and locations (`hdfs fsck`), and DataNode capacity (`hdfs dfsadmin -report`).

### Python Bootstrap on Workers
```bash
./src/processing/ensure_python.sh
```
- Verifies presence of Python 3 on worker NodeManagers (`nodemanager1`, `nodemanager2`) and installs it via `apt-get` if missing.

### Distributed Hadoop Streaming Cleaning
```bash
./src/processing/run_cleaning.sh
```
- Submits MapReduce jobs (`flight-clean-2009`, `flight-clean-2010`) to YARN using `hadoop-streaming-3.2.1.jar` with `clean_mapper.py` and zero reducers (`mapreduce.job.reduces=0`).

### Cleaned Data Verification
```bash
./src/processing/verify_cleaning.sh
```
- Validates cleaned file sizes, samples output rows, counts cleaned records, and compares against MapReduce counters.

---

## 2. Ingestion & Storage Distribution Proof

| Dataset / Year | Raw File Size | HDFS Total Size (Repl=2) | Number of Blocks | Block Size | Replication Factor | Placement |
|---|---|---|---|---|---|---|
| `2009.csv` | 755.9 MB (792,609,318 B) | 1.5 GB | 6 blocks | 128 MB (last: 121.5 MB) | 2 | datanode1 + datanode2 |
| `2010.csv` | 757.4 MB (794,152,224 B) | 1.5 GB | 6 blocks | 128 MB (last: 123.0 MB) | 2 | datanode1 + datanode2 |

- **Fsck Health Status**: `HEALTHY` (12 validated replicated blocks, 0 missing, 0 corrupt).
- **Block Allocation**: Every block has `Live_repl=2` located on both `172.18.0.3:9866` (datanode1) and `172.18.0.5:9866` (datanode2).
- **DataNode DFS Usage**: Exactly balanced at ~1.50 GB DFS used per DataNode.

---

## 3. Cleaning Execution & Record Reconciliation

The cleaning job transforms raw records into 23 structured fields, drops malformed/diverted rows with missing arrival delay, preserves cancelled flights (setting delay to 0), and derives `dep_hour`, `day_of_week`, and the DOT binary delay target `is_delayed`.

### Cleaning Rules & Logic
- **HeaderSkipped**: First row containing column headers.
- **CancelledKept**: Cancelled flights retained with departure/arrival delays set to 0.
- **DroppedMissingDelay**: Non-cancelled flights missing arrival/departure delays (predominantly diverted flights).
- **Reconciliation Formula**: `ReadRecords = WrittenRecords + DroppedMissingDelay + HeaderSkipped`.

### Reconciliation Summary Table

| Metric / Counter | Year 2009 | Year 2010 | Combined (Total) |
|---|---|---|---|
| **Raw Lines (ReadRecords)** | 6,429,339 | 6,450,118 | **12,879,457** |
| **Header Skipped** | 1 | 1 | 2 |
| **Dropped Missing Delay** | 15,323 | 15,474 | 30,797 |
| **Cleaned Rows Written** | 6,414,015 | 6,434,643 | **12,848,658** |
| **Cancelled Flights Kept** | 87,038 | 113,255 | 200,293 |
| **HDFS Output Size (Repl=2)** | 957.8 MB | 962.0 MB | ~1.92 GB |
| **HDFS Part Files** | 6 (`part-00000`..`05`) | 6 (`part-00000`..`05`) | 12 part files |
| **HDFS `wc -l` Verification** | 6,414,015 (Exact Match) | 6,434,643 (Exact Match) | **12,848,658 (100% Match)** |
| **Job Status** | `SUCCEEDED` (0 reducers) | `SUCCEEDED` (0 reducers) | All Jobs Succeeded |

---

## 4. Evidence Artifacts

The following proof files are captured in `screenshots/`:
- `14-hdfs-raw-ls.txt`: Recursive listing of `/flights/raw` in HDFS.
- `15-hdfs-raw-du.txt`: Disk usage per year partition in HDFS.
- `16-hdfs-raw-fsck.txt`: Complete block location report demonstrating dual-DataNode distribution.
- `17-hdfs-report-after-ingest.txt`: Cluster capacity and DataNode DFS usage after ingestion.
- `18-clean-job-2009.log`: Full Hadoop Streaming execution log and counters for year 2009.
- `18-clean-job-2010.log`: Full Hadoop Streaming execution log and counters for year 2010.
- `19-hdfs-cleaned-du.txt`: Disk usage and file listings of `/flights/cleaned`.
- `20-cleaned-sample.txt`: First 5 rows of cleaned data per year partition.
- `21-cleaning-summary.txt`: Cleaned line counts reconciled against MapReduce cleaning counters.
- `22-namenode-ui-browse-raw.png`: NameNode web UI file browser showing blocks and replication.
- `23-resourcemanager-ui-clean-jobs.png`: ResourceManager web UI showing completed cleaning applications.
