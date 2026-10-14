# Custom Java MapReduce Job & Hive Cross-Check

## 1. Overview & Syllabus Alignment

In Phase 7, we developed and executed a custom Java MapReduce application (`flightdelay.CarrierMonthDelay`) on the Hadoop cluster. This directly fulfills the academic curriculum requirement for native **Hadoop MapReduce development** alongside the Python Hadoop Streaming data-cleaning pipeline (Phase 4) and declarative Apache Hive analytics (Phases 5 & 6).

The MapReduce job aggregates delay statistics per `(carrier, year, month)` across all cleaned records on HDFS. To rigorously prove correctness, its output was cross-checked record-for-record against an equivalent HiveQL analytical query.

---

## 2. MapReduce Job Architecture & Design

### 2.1 Input Data & Key-Value Contracts
- **Input Path**: HDFS glob `/flights/cleaned/year=*` spanning all 12 partitioned data blocks (12,848,658 records, ~993.7 MB uncompressed CSV).
- **Mapper (`DelayMapper`)**:
  - Parses each CSV line into 23 comma-delimited columns.
  - Extracts `carrier` (index 5), `year` (index 1), and `month` (index 2) to form the composite key: `Text(carrier + "," + year + "," + month)`.
  - Extracts operational flags: `cancelled` (index 13), `is_delayed` (index 22), and `arr_delay` (index 12).
  - Emits:
    $$\text{Key} = \text{carrier,year,month}$$
    $$\text{Value} = \text{"1,cancelled,operated,delayed,arrSum"}$$
  - Increments custom Hadoop user counters: `ParsedRecords`, `MalformedLines`, and `BadNumberLines`.

### 2.2 In-Mapper Combiner Optimization (`SumCombiner`)
- The map output value comprises 5 numerical integers: `total_flights`, `cancelled_flights`, `operated_flights`, `delayed_flights`, and `sum_arr_delay_min`.
- Because addition is both **associative and commutative**, the combiner uses identical aggregation logic as the partial reduction:
  $$(a + b) + c = a + (b + c) \quad \text{and} \quad a + b = b + a$$
- **Shuffle Optimization**: The combiner reduced intermediate records from **12,848,658** down to just **610** records before network transmission, slashing shuffle network I/O from 274.5 MB to 23.3 KB (a **99.995% reduction** in shuffled records).

### 2.3 Reducer (`DelayReducer`)
- Configured with `job.setNumReduceTasks(2)` to demonstrate distributed partition reduction across the cluster.
- Aggregates the 5 numerical sums for each unique `(carrier, year, month)` key.
- Computes derived operational metrics:
  $$\text{delay\_pct} = 100.0 \times \frac{\text{delayed}}{\text{operated}} \quad (\text{if operated} > 0)$$
  $$\text{avg\_arr\_delay\_min} = \frac{\text{sum\_arr\_delay}}{\text{operated}} \quad (\text{if operated} > 0)$$
- Formats output as comma-separated values using `mapreduce.output.textoutputformat.separator = ","`.

---

## 3. Build & Execution Workflow

All scripts reside in `src/processing/mapreduce/` and `src/analytics/`:

1. **Compilation & Packaging**:
   ```bash
   ./src/processing/mapreduce/build_mr_job.sh
   ```
   Compiles `CarrierMonthDelay.java` inside the `namenode` container against the local Hadoop 3.2.1 classpath (`javac -classpath "$(hadoop classpath)"`) and packages it into `/tmp/mrbuild/carrier-month-delay.jar`.

2. **Cluster Execution on YARN**:
   ```bash
   ./src/processing/mapreduce/run_mr_job.sh
   ```
   Submits `flightdelay.CarrierMonthDelay` to YARN via `hadoop jar`. Output is written to HDFS at `/flights/mr_output/carrier_month_delay` (`part-r-00000` and `part-r-00001`), retrieved, sorted, and saved to `output/mapreduce/carrier_month_delay.csv`.

3. **Hive Cross-Check**:
   ```bash
   ./src/analytics/crosscheck_mr_vs_hive.sh
   ```
   Executes an identical `GROUP BY carrier, year, flight_month` Hive query on YARN and performs an automated diff against the MapReduce output.

4. **Automated Consistency Validation**:
   ```bash
   ./src/processing/mapreduce/validate_mr_output.sh
   ```

---

## 4. Execution Metrics & Counters Summary

### 4.1 Hadoop MapReduce Job Counters (`job_1791880720726_0053`)
Counters captured in `screenshots/37-mr-counters-summary.txt`:

| Counter Category | Metric | Recorded Value |
|---|---|---|
| **Job Setup** | Launched Map Tasks | **12** (1 per HDFS block split) |
| **Job Setup** | Launched Reduce Tasks | **2** |
| **Locality** | Rack-local Map Tasks | **12** |
| **Map Framework** | Map Input Records | **12,848,658** |
| **Map Framework** | Map Output Records | **12,848,658** |
| **Combiner** | Combine Input Records | **12,848,658** |
| **Combiner** | Combine Output Records | **610** |
| **Reduce Framework** | Reduce Input Groups | **425** |
| **Reduce Framework** | Reduce Output Records | **425** |
| **User Counters** | `FlightDelay.ParsedRecords` | **12,848,658** |
| **User Counters** | `FlightDelay.MalformedLines` | **0** |
| **User Counters** | `FlightDelay.BadNumberLines` | **0** |

### 4.2 Runtime Performance Comparison
- **Custom Java MapReduce Job**: **56 seconds**
- **Hive Cross-Check Query (MapReduce on YARN)**: **41 seconds**

---

## 5. Cross-Check Against Hive & Validation Results

### 5.1 Automated Cross-Check Report (`screenshots/38-mr-vs-hive-crosscheck.txt`)
```text
Hive cross-check query elapsed seconds: 41
MapReduce groups (rows):      425
Hive groups (rows):           425
Compared columns: carrier, year, month, total_flights, cancelled_flights, operated_flights, delayed_flights, sum_arr_delay_min
RESULT: MATCH - the MapReduce output is identical to the Hive output
```
Every single numerical value across all 425 carrier-year-month groups matched identically between the native Java MapReduce output and HiveQL query output.

### 5.2 Validator Assertions (`validate_mr_output.sh`)
```text
Reference from phase 5: rows=12848658 cancelled=200293 years=2
OK   Map input records 12848658 = Hive row total 12848658
OK   sum(total_flights) 12848658 = 12848658
OK   sum(cancelled) 200293 = 200293
OK   every row: cancelled+operated=total and 0<=delay_pct<=100
OK   years in output: 2
OK   no malformed or bad-number lines
OK   combiner effective: 12848658 records in, 610 out
```

---

## 6. Empirical Findings (Carrier-Month Delay Aggregation)

From the generated dataset `output/mapreduce/carrier_month_delay.csv`:
- **Total Flights Processed**: **12,848,658**
- **Total Unique Carrier-Year-Month Partitions**: **425**
- **Top 5 Carrier-Months with Highest Delay % ($\ge 1,000$ operated flights)**:
  1. **Comair (OH) — January 2009**: **39.39%** delay rate (11,902 operated, 4,688 delayed, avg arrival delay: +19.70 min)
  2. **Comair (OH) — June 2009**: **36.53%** delay rate (13,276 operated, 4,850 delayed, avg arrival delay: +18.83 min)
  3. **JetBlue Airways (B6) — December 2010**: **35.70%** delay rate (16,517 operated, 5,897 delayed, avg arrival delay: +20.38 min)
  4. **Atlantic Southeast Airlines (EV) — March 2009**: **35.59%** delay rate (24,034 operated, 8,553 delayed, avg arrival delay: +20.25 min)
  5. **Comair (OH) — May 2009**: **32.80%** delay rate (14,165 operated, 4,646 delayed, avg arrival delay: +13.83 min)

---

## 7. Distributed Processing & Container Allocation Proof

Application ID `application_1791880720726_0053` ran across both worker nodes in the cluster (`screenshots/41-mr-container-nodes.txt`):
- **Worker 1 (`6cb2f39cce7e_44715` / `nodemanager1`)**: Allocated **11 containers** (Containers 3, 4, 6, 7, 9, 10, 11, 12, 13, 14, 15).
- **Worker 2 (`e8fa0dbb44aa_41485` / `nodemanager2`)**: Allocated **4 containers** (Containers 1, 2, 5, 8).
- **Conclusion**: Both distinct physical worker nodes executed map and reduce containers, confirming distributed processing under YARN.

### Evidence Artifacts
- `screenshots/35-mr-carrier-month-delay-job.log`: Full execution log of the MapReduce job.
- `screenshots/36-mr-output-hdfs-ls.txt`: HDFS file listing of `/flights/mr_output/carrier_month_delay`.
- `screenshots/37-mr-counters-summary.txt`: Extracted summary of MapReduce framework and user counters.
- `screenshots/38-mr-vs-hive-crosscheck.txt`: Comparison report showing 100% MATCH against Hive.
- `screenshots/39-yarn-applications-mr.txt`: YARN applications list showing `application_1791880720726_0053` SUCCEEDED.
- `screenshots/40-yarn-nodes-mr.txt`: YARN node report showing 2 active NodeManagers.
- `screenshots/41-mr-container-nodes.txt`: Container breakdown proving multi-node scheduling.
- `screenshots/42-resourcemanager-ui-mr-job.png`: ResourceManager Web UI screenshot of finished job.
- `screenshots/43-namenode-ui-mr-output.png`: NameNode HDFS File Browser screenshot showing output part files.
