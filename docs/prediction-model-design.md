# Prediction Model Design: Train/Validation/Test Split & Hive Delay-Probability Model

## 1. Overview & Honest Model Positioning

In Phase 8, we developed and deployed a **Hadoop-native flight delay prediction model** built entirely within Apache Hive on YARN. 

### Academic & Technical Clarification
- **What this model IS**: A scalable, count-based **historical conditional probability estimator with hierarchical back-off** implemented entirely in HiveQL over HDFS. It calculates empirical delay probabilities $p = \frac{\text{delayed}}{n}$ across granular feature intersections.
- **What this model is NOT**: It is **not** an iterative statistical learning or gradient-boosted machine learning model (such as XGBoost or Spark MLlib Random Forests). Because the project operates under a strict **Hadoop-only constraint** (prohibiting Spark, Spark MLlib, and external Python ML libraries), this HiveQL conditional probability model serves as the curriculum's pure Big Data Hadoop substitute.

---

## 2. Feature Engineering & Leakage Controls

### 2.1 Pre-Departure Feature Definitions
To prevent data leakage, all features used for conditioning are known **strictly prior to scheduled flight departure**:
- **`carrier`**: 2-letter IATA airline code.
- **`origin`**: Origin airport IATA code.
- **`dest`**: Destination airport IATA code.
- **`flight_month`**: Calendar month of departure (1–12).
- **`hour_bucket`**: 4-hour scheduled departure time block:
  $$\text{hour\_bucket} = \text{dep\_hour DIV } 4$$
  - `Bucket 0`: 00:00 – 03:59 (Night)
  - `Bucket 1`: 04:00 – 07:59 (Early Morning)
  - `Bucket 2`: 08:00 – 11:59 (Late Morning)
  - `Bucket 3`: 12:00 – 15:59 (Afternoon)
  - `Bucket 4`: 16:00 – 19:59 (Evening)
  - `Bucket 5`: 20:00 – 23:59 (Late Night)

### 2.2 Leakage Prevention Rules
- **No In-Flight or Post-Flight Metrics**: Columns such as `dep_delay`, `arr_delay`, `taxi_out`, `air_time`, or cause minutes (`carrier_delay`, `weather_delay`, etc.) are **strictly excluded**.
- **Cancellation Filter**: Cancelled flights (`cancelled = 1`) are excluded from model training, validation, and testing because an unoperated flight does not possess an arrival delay.
- **Temporal Integrity**: The test partition is reserved exclusively from the latest chronological year (2010), ensuring zero future-to-past data leakage.

---

## 3. Dataset Split Design

The full dataset of **12,648,365 operated flights** was partitioned into three distinct sets via `src/analytics/prediction/01_create_split.hql`:

```sql
CASE WHEN `year` = 2010 THEN 'test'
     WHEN pmod(hash(fl_date, carrier, flight_num, origin, dest, crs_dep_time), 10) = 9 THEN 'validation'
     ELSE 'train' END AS split_set
```

### 3.1 Split Partition Details
| Split Set | Data Year | Partitioning Strategy | Operated Flights | Delayed Flights | Delay Rate (`delay_pct`) | Purpose |
|---|---|---|---|---|---|---|
| **`train`** | 2009 | Deterministic hash (~90% of pre-test) | **5,693,875** | 1,052,851 | **18.49%** | Compute all conditional probability tables |
| **`validation`** | 2009 | Deterministic hash (~10% of pre-test) | **633,102** | 117,650 | **18.58%** | Choose optimal classification threshold in Phase 9 |
| **`test`** | 2010 | Full temporal hold-out (latest year) | **6,321,388** | 1,174,884 | **18.59%** | Unbiased final model evaluation in Phase 9 |
| **Total** | — | — | **12,648,365** | **2,345,385** | **18.54%** | 100% reconciliation with Phase 5 |

> **Evaluation Caveat**: The validation set is sampled from the same operating year (2009) as the training set, meaning threshold tuning in Phase 9 will reflect in-distribution operational conditions. The 2010 test set provides the true out-of-period temporal generalization test.

### 3.2 Majority-Class Baseline Accuracy
On the test set (year 2010), **18.59%** of flights are delayed and **81.41%** are on-time.
A naive majority-class classifier that predicts "on-time" for every flight achieves an accuracy of **81.41%**. In Phase 9, our model must surpass this baseline on test data.

---

## 4. Hierarchical Probability Tables with Back-Off

To ensure both granular specificity and universal coverage, we construct 5 hierarchical probability tables with a minimum support threshold of $\text{min\_support} = 30$ flights:

1. **Level 1 (`model_l1`)**: `carrier, origin, dest, flight_month, hour_bucket` (Granular route + time + airline)
2. **Level 2 (`model_l2`)**: `carrier, origin, flight_month, hour_bucket` (Carrier outbound hub seasonality)
3. **Level 3 (`model_l3`)**: `origin, hour_bucket` (Airport hourly congestion baseline)
4. **Level 4 (`model_l4`)**: `carrier, hour_bucket` (Carrier operational time-of-day baseline)
5. **Level 5 (`model_global`)**: Global training delay probability ($p = 0.1849$)

### Back-Off Scoring Strategy (for Phase 9)
When scoring a flight, the engine selects the probability estimate from the most specific table that satisfies $n \ge 30$:
$$\hat{p} = \text{COALESCE}(p_{L1}, p_{L2}, p_{L3}, p_{L4}, p_{\text{global}})$$

### 4.2 Model Level Statistics (`output/prediction_model/model_level_stats.csv`)
| Model Level | Feature Keys | Unique Keys ($n \ge 30$) | Training Flights Covered | Coverage % | Min $p$ | Avg $p$ over Keys | Max $p$ |
|---|---|---|---|---|---|---|---|
| **L1** | `carrier+origin+dest+month+hour_bucket` | 51,512 | 2,966,427 | 52.10% | 0.0000 | 0.1821 | 0.9130 |
| **L2** | `carrier+origin+month+hour_bucket` | 30,028 | 5,177,163 | 90.92% | 0.0000 | 0.1816 | 0.8421 |
| **L3** | `origin+hour_bucket` | 1,201 | 5,693,449 | 99.99% | 0.0000 | 0.1780 | 0.5410 |
| **L4** | `carrier+hour_bucket` | 103 | 5,693,860 | 99.9997% | 0.0150 | 0.1855 | 0.3457 |
| **GLOBAL** | Overall training baseline | 1 | 5,693,875 | 100.00% | 0.1849 | 0.1849 | 0.1849 |

---

## 5. Empirical Probabilities & Key Insights

### 5.1 Level 4 (`carrier + hour_bucket`) Extremes
- **Top 5 Highest Risk Combinations**:
  1. **Hawaiian Airlines (HA) — Night (Hour Bucket 0)**: $p = \mathbf{0.3457}$ ($n = 324$, 112 delayed)
  2. **Atlantic Southeast (EV) — Evening (Hour Bucket 4)**: $p = \mathbf{0.3435}$ ($n = 57,423$, 19,726 delayed)
  3. **Comair (OH) — Evening (Hour Bucket 4)**: $p = \mathbf{0.3367}$ ($n = 32,515$, 10,947 delayed)
  4. **Comair (OH) — Late Night (Hour Bucket 5)**: $p = \mathbf{0.3138}$ ($n = 10,281$, 3,226 delayed)
  5. **AirTran (FL) — Evening (Hour Bucket 4)**: $p = \mathbf{0.3059}$ ($n = 55,415$, 16,953 delayed)
- **Top 5 Lowest Risk Combinations**:
  1. **Hawaiian Airlines (HA) — Early Morning (Bucket 1)**: $p = \mathbf{0.0150}$ ($n = 8,799$, 132 delayed)
  2. **Hawaiian Airlines (HA) — Late Night (Bucket 5)**: $p = \mathbf{0.0423}$ ($n = 6,291$, 266 delayed)
  3. **Southwest Airlines (WN) — Early Morning (Bucket 1)**: $p = \mathbf{0.0445}$ ($n = 126,902$, 5,647 delayed)
  4. **Hawaiian Airlines (HA) — Evening (Bucket 4)**: $p = \mathbf{0.0613}$ ($n = 14,163$, 868 delayed)
  5. **Frontier Airlines (F9) — Early Morning (Bucket 1)**: $p = \mathbf{0.0855}$ ($n = 12,578$, 1,076 delayed)

### 5.2 Level 1 Granular Key Insights
- **Most Common L1 Keys**:
  1. `HA, OGG -> HNL, month 9, bucket 3`: $n = 432$, $p = 0.0602$
  2. `HA, HNL -> OGG, month 9, bucket 3`: $n = 426$, $p = 0.0235$
  3. `WN, DAL -> HOU, month 9, bucket 4`: $n = 384$, $p = 0.2500$
  4. `WN, HOU -> DAL, month 9, bucket 3`: $n = 370$, $p = 0.0703$
  5. `WN, HOU -> DAL, month 9, bucket 4`: $n = 370$, $p = 0.1676$
- **Highest Risk L1 Keys ($n \ge 200$)**:
  1. `EV, CHA -> ATL, month 9, bucket 3`: $n = 202$, $p = \mathbf{0.5446}$
  2. `MQ, LIT -> DFW, month 9, bucket 4`: $n = 208$, $p = \mathbf{0.3942}$
  3. `DL, LGA -> ATL, month 9, bucket 4`: $n = 200$, $p = \mathbf{0.3900}$
  4. `WN, MDW -> STL, month 9, bucket 4`: $n = 244$, $p = \mathbf{0.3525}$
  5. `MQ, DFW -> LIT, month 9, bucket 3`: $n = 212$, $p = \mathbf{0.3491}$

---

## 6. Automated Validation Results (`validate_model_build.sh`)

All assertions executed and passed cleanly:

```text
Reference from phase 5: rows=12848658 cancelled=200293 operated=12648365 test_year=2010
OK   train+validation+test rows 12648365 = operated flights 12648365
OK   test = year 2010 only; train and validation contain only earlier years
OK   exactly one test year row
OK   validation share of pre-test data is 8-12%
OK   every split delay_pct is between 5 and 40
OK   5 model levels present
OK   all probabilities within [0,1]
OK   every level has at least one key
OK   GLOBAL covers all 5693875 train rows
OK   no level covers more than the train rows
OK   L4 covers at least 99% of train rows
OK   model_global n = train rows
OK   highest-risk keys all have n >= 200
```

---

## 7. Distributed Storage & Processing Proofs

### 7.1 HDFS Storage & FSCK Block Verification
- **Table Path**: `/user/hive/warehouse/flightdb.db/flights_split`
- **Total Table Size**: 353,591,649 bytes (337.2 MB uncompressed text)
- **HDFS Replication**: Factor 2 (DFS Used = 674.4 MB)
- **Block Layout**:
  - `000000_1`: 121,853,897 bytes on `172.18.0.3:9866` (datanode1) & `172.18.0.5:9866` (datanode2)
  - `000001_1`: 114,749,686 bytes on `172.18.0.3:9866` (datanode1) & `172.18.0.5:9866` (datanode2)
  - `000002_0`: 116,988,066 bytes on `172.18.0.3:9866` (datanode1) & `172.18.0.5:9866` (datanode2)
- **Status**: `HEALTHY`, 0 missing blocks, 0 corrupt blocks, full two-node mirroring.

### 7.2 YARN Log Excerpts
- **Split Table Job (`job_1791880720726_0057`)**:
  - Tracking URL: `http://resourcemanager:8088/proxy/application_1791880720726_0057/`
  - Map Tasks: 3, Reduce Tasks: 0 (Map-only)
  - Cumulative CPU: 30.53 seconds | Final Status: `SUCCEEDED`
- **Model Tables Job (`job_1791880720726_0059`)**:
  - Tracking URL: `http://resourcemanager:8088/proxy/application_1791880720726_0059/`
  - Map Tasks: 1, Reduce Tasks: 2
  - Cumulative CPU: 15.26 seconds | Final Status: `SUCCEEDED`

### Evidence Artifacts
- `screenshots/44-hdfs-model-tables-du.txt`: HDFS `du -h` storage footprint across all model tables.
- `screenshots/45-hdfs-flights-split-fsck.txt`: Complete FSCK block health and location report for `flights_split`.
- `screenshots/46-yarn-applications-phase8.txt`: YARN application status list showing Phase 8 jobs completed.
- `screenshots/47-yarn-nodes-phase8.txt`: NodeManager cluster report.
- `screenshots/48-resourcemanager-ui-phase8-jobs.png`: Web UI capture of ResourceManager applications page.
- `screenshots/49-namenode-ui-model-tables.png`: Web UI capture of HDFS file explorer showing model tables.
