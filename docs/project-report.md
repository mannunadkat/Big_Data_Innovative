# Airline Flight Delay Analytics & Prediction: Final Project Report

## 1. Problem Statement and Objectives
Commercial airline delays impose billions of dollars in annual economic costs, waste passenger time, and disrupt global supply chains. Understanding the underlying root causes of flight delays and predicting delay risks prior to departure are fundamental challenges in aviation operations.

The objective of this project is to build an end-to-end, big data analytics and prediction pipeline to process multi-year, large-scale US commercial flight records using strictly the core **Apache Hadoop ecosystem (HDFS, MapReduce, Hive)**. The system:
- Ingests and stores multi-gigabyte flight datasets across a distributed filesystem with replication.
- Cleans and structures raw flight logs into an analytics-ready schema using distributed MapReduce.
- Executes comprehensive analytical queries across airline performance, airport delays, temporal patterns, flight cancellations, route risks, and severe weather impacts.
- Develops and evaluates a Hadoop-native historical delay prediction model with hierarchical back-off on YARN.

---

## 2. Dataset and Cleaning Rules
- **Dataset Name**: US Department of Transportation (DOT) Bureau of Transportation Statistics (BTS) Airline On-Time Performance dataset.
- **Source**: US DOT / BTS database: https://www.kaggle.com/datasets/yuanyuwendymu/airline-delay-and-cancellation-data-2009-2018 (only the files `2009.csv` and `2010.csv` from that dataset were used; referenced in [`dataset/raw/DATASET_SOURCE.md`](../dataset/raw/DATASET_SOURCE.md)).
- **Ingested Years & Row Counts** (derived from [`screenshots/26-hive-partition-rowcounts.txt`](../screenshots/26-hive-partition-rowcounts.txt)):
  - **Year 2009**: 6,414,015 raw records (87,038 cancelled, 1,170,501 delayed, 6,326,977 operated).
  - **Year 2010**: 6,434,643 raw records (113,255 cancelled, 1,174,884 delayed, 6,321,388 operated).
  - **Total Dataset Size**: **12,848,658** total flight records (**12,648,365** operated flights, **200,293** cancelled flights).
- **Cleaning & Standardization Rules** (defined in [`docs/data-dictionary.md`](data-dictionary.md)):
  1. Standardized 23 comma-separated output columns.
  2. Missing delay minutes (`DepDelay`, `ArrDelay`, cause delays) imputed to `0.0`.
  3. Cancelled flights kept with `dep_delay = 0` and `arr_delay = 0` to preserve operational volume without distorting delay sums.
  4. Derived scheduled departure hour `dep_hour` (0–23) from `CRSDepTime`.
  5. Target label `is_delayed = 1` defined as: **`cancelled = 0 AND arr_delay >= 15.0`**; otherwise `0`.

---

## 3. Architecture Overview
The system is built on a 3-node containerized Hadoop cluster executed across 7 Docker containers on a single physical host. The architecture decouples distributed storage (HDFS with replication factor 2 across two worker DataNodes) from distributed compute (YARN ResourceManagers and NodeManagers). Apache Hive runs on the master node with an embedded Apache Derby metastore, executing all analytical queries and model joins as MapReduce jobs on YARN.

Complete architectural diagrams and technical details are documented in [`docs/architecture.md`](architecture.md).

---

## 4. Implementation by Stage
1. **Ingestion (`src/ingestion/`)**: Automated bash scripts verify raw CSV integrity and stream yearly partitions into HDFS under `/flights/raw/year=YYYY/`.
2. **Data Cleaning (`src/processing/`)**: A Hadoop Streaming MapReduce job (`clean_mapper.py`, map-only) reads raw records and writes 23-column cleaned text partitions into `/flights/cleaned/year=YYYY/`.
3. **Hive Warehouse Setup (`src/analytics/`)**: Creates external partitioned table `flights_cleaned` and reference table `carriers_ref`.
4. **Analytics Query Suites**:
   - `run_airline_airport_analytics.sh`: Computes delay statistics by carrier and origin/destination airports.
   - `run_time_route_cancel_weather.sh`: Analyzes monthly, day-of-week, hourly, route, cancellation, and weather delay patterns.
5. **Custom Java MapReduce Job (`src/processing/mapreduce/`)**: `CarrierMonthDelay.java` aggregates operated flights, delayed flights, and total delay minutes by carrier, year, and month. Cross-checked against HiveQL output (`screenshots/38-mr-vs-hive-crosscheck.txt`), confirming 0 differences across 388 carrier-month keys.
6. **Prediction Model Build (`src/analytics/prediction/`)**: Creates deterministic train/validation/test split table (`flights_split`) and generates 5 conditional probability model tables (`model_l1` to `model_l4`, `model_global`) with support threshold $n \ge 30$.
7. **Scoring and Evaluation**: Validation sweep determines optimal threshold (`0.18`), followed by one-time evaluation on the 2010 test set.

---

## 5. Key Analytical Findings
All findings are derived directly from the empirical CSV results in `output/`:
- **Overall Operational Volume & Delay Rate**: Across 2009–2010, the cluster processed **12,648,365 operated flights**, of which **2,345,385 arrived 15+ minutes late**, representing an overall delay rate of **18.54%**.
- **Airlines**:
  - *Top 3 Most Delay-Prone*: Comair (OH, **25.85%**), Atlantic Southeast Airlines (EV, **22.69%**), JetBlue Airways (B6, **21.72%**).
  - *Top 3 Least Delay-Prone*: Hawaiian Airlines (HA, **7.49%**), Alaska Airlines (AS, **13.72%**), United Air Lines (UA, **15.27%**).
- **Top 5 Worst Origin Airports (Departure Delays)**:
  1. Chicago Midway (MDW): **25.45%** (12.38 min avg departure delay)
  2. Miami International (MIA): **24.34%** (13.14 min avg departure delay)
  3. Houston Hobby (HOU): **24.33%** (12.02 min avg departure delay)
  4. Newark Liberty (EWR): **22.38%** (13.10 min avg departure delay)
  5. San Francisco (SFO): **21.38%** (11.75 min avg departure delay)
- **Temporal Trends**:
  - *Months*: December was the worst month (**25.38%** delay rate); September was the best (**13.44%** delay rate).
  - *Days of Week*: Friday was the worst travel day (**19.89%** delay rate); Saturday was the best (**16.07%** delay rate).
- **Flight Cancellations**:
  - Out of 200,293 cancellations, **Adverse Weather (Code B)** was the dominant cause at **46.51%** (93,158 flights), followed by **Carrier-controllable issues (Code A)** at **38.81%** (77,724 flights).
- **High-Volume Routes with Highest Delay Share ($\ge 2,000$ flights)**:
  1. Memphis to Newark (MEM-EWR): **39.83%** (24.59 min avg delay)
  2. Cincinnati to Newark (CVG-EWR): **39.23%** (24.65 min avg delay)
  3. Detroit to JFK (DTW-JFK): **37.86%** (17.48 min avg delay)
- **Airports with Highest Weather Delay Impact**:
  - New York JFK: **1,257.9** weather delay minutes per 1,000 departures.
  - Baton Rouge (BTR): **1,185.5** weather delay minutes per 1,000 departures.
  - Miami (MIA): **1,127.4** weather delay minutes per 1,000 departures.

---

## 6. Flight Delay Prediction Evaluation
The delay predictor is a **count-based conditional probability estimator with hierarchical back-off** built in HiveQL on YARN (the Hadoop-native substitute for Spark MLlib; not an iterative ML model).

### Evaluation Protocol & Leakage Controls
- Evaluated on **6,321,388 operated test flights** from the held-out temporal year **2010**.
- Decision threshold selected on the **2009 validation set** only: **`0.18`** (maximizing validation F1 = 0.3743).
- Test set evaluated once with no subsequent tuning.

### Test Performance Metrics (`test_metrics.csv`)
```
Confusion Matrix:
  TP = 742,226    |  FP = 2,544,707
  FN = 432,658    |  TN = 2,601,797
Total Test Flights = 6,321,388
```
- **Accuracy**: **0.5290** (52.90%)
- **Precision**: **0.2258** (22.58%)
- **Recall**: **0.6317** (63.17%)
- **F1 Score**: **0.3327**
- **Test Delay Rate**: 18.59%
- **Majority-Class Baseline Accuracy (Always On Time)**: **0.8141** (81.41%)
- **Always-Delayed Baseline F1**: **0.3135**
- **Precision Lift over Base Rate**: **1.215x**

### Baseline Comparison & Limitations
- The model beats the naive always-delayed baseline F1 (**0.3327 vs 0.3135**) and provides a **1.215x lift** in precision.
- Overall accuracy (**0.5290**) does **not** beat the majority baseline accuracy (**0.8141**). In minority-class classification (18.59% delay prevalence), choosing a threshold to maximize F1 (0.18) prioritizes capturing almost two-thirds of all delays (63.17% recall) at the cost of higher false positives.
- Feature set is restricted to carrier, route, month, and scheduled time; real-time weather and inbound aircraft delays are not available prior to flight scheduling.

---

## 7. Distributed Execution Evidence
All operations executed in distributed mode across HDFS and YARN. Verification script `scripts/final-verification.sh` confirmed:
- **Before-Restart Verification**: All checks passed ([`screenshots/final/before-restart-console.txt`](../screenshots/final/before-restart-console.txt)).
- **After-Restart Verification**: All checks passed ([`screenshots/final/after-restart-console.txt`](../screenshots/final/after-restart-console.txt)).
- Storage integrity: HDFS reports `/flights` is **HEALTHY** with average block replication factor **2.0** stored across both DataNodes.
- Full evidence cross-references are indexed in [`docs/evidence-index.md`](evidence-index.md).

---

## 8. Challenges Encountered & Resolutions
1. **Container Resource Allocation**: During multi-table Hive joins across 12.8M rows, YARN containers required explicit heap boundaries. Container memory was configured via `config/hadoop.env` to prevent container thrashing.
2. **Embedded Derby Metastore Concurrency**: Hive utilizes an embedded Derby metastore inside the `namenode` container, which acquires an exclusive file lock on `metastore_db`. All analytics queries and scoring jobs were orchestrated sequentially to prevent metastore lock contention.
3. **Reproducibility Across Reboots**: Verified that all HDFS blocks, Hive tables, and generated partitions survive complete cluster stop and restart cycles without data corruption or block loss.

---

## 9. Limitations & Future Work
- **Containerized Cluster on Single Machine**: While demonstrating complete distributed Hadoop protocols, all containers share host CPU, RAM, and physical disk bandwidth.
- **Pre-Departure Feature Limits**: Features are limited to schedule metadata. Live convective weather radar feeds, airport surface congestion metrics, and upstream aircraft delay propagation were not present in the historical DOT dataset.
- **Future Work**: Implementing machine learning algorithms using Apache Spark MLlib or Apache Mahout on a multi-machine physical bare-metal cluster to incorporate real-time feature streaming.

---

## 10. How to Reproduce
The entire pipeline can be reproduced using the orchestrator script:
```bash
# 1. Start cluster
./pipeline/run_pipeline.sh --stage cluster

# 2. Run complete end-to-end pipeline
./pipeline/run_pipeline.sh --all

# 3. Execute final verification suite
./scripts/final-verification.sh manual-run
```
Detailed instructions are provided in [`pipeline/README.md`](../pipeline/README.md).
