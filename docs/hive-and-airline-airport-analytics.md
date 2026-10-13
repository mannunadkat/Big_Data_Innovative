# Hive Setup & Airline/Airport Delay Analytics

## 1. Overview & Architecture

In Phase 5, **Apache Hive 3.1.3** was integrated into the Hadoop cluster to provide structured SQL querying (HiveQL) over cleaned flight records stored in HDFS. 

### Architecture Specifications
- **Host Container**: Master node (`namenode` container).
- **Metastore**: Embedded Derby RDBMS stored on a dedicated Docker persistent named volume (`hive_data` mounted at `/opt/hive-data`). Metastore tables are persisted in `/opt/hive-data/metastore_db` across container restarts.
- **Binary Directory**: `/opt/hive-data/apache-hive-3.1.3-bin`.
- **Execution Engine**: **MapReduce on YARN** (`mapreduce.framework.name = yarn`). Local mode is strictly disabled so all queries execute as distributed MapReduce jobs on YARN NodeManagers.
- **Scratch Directories**: Hive job scratch directories configured on HDFS at `/tmp/hive` and `/user/hive/warehouse` with world-writable `777` permissions.
- **Metastore Concurrency**: Embedded Derby allows a single active Hive connection at a time. All CLI invocations and automated analytics scripts are executed sequentially.

---

## 2. DDL & Data Modeling

Hive tables are defined within the database `flightdb`.

### 2.1 External Partitioned Table: `flightdb.flights_cleaned`
Mapped directly over HDFS partitioned directories at `/flights/cleaned`:
```sql
CREATE DATABASE IF NOT EXISTS flightdb;
USE flightdb;

CREATE EXTERNAL TABLE IF NOT EXISTS flights_cleaned (
    fl_date               STRING,
    month                 INT,
    day_of_month          INT,
    day_of_week           INT,
    carrier               STRING,
    flight_num            STRING,
    origin                STRING,
    dest                  STRING,
    crs_dep_time          INT,
    dep_hour              INT,
    dep_delay             DOUBLE,
    arr_delay             DOUBLE,
    cancelled             INT,
    cancellation_code     STRING,
    diverted              INT,
    distance              DOUBLE,
    carrier_delay         DOUBLE,
    weather_delay         DOUBLE,
    nas_delay             DOUBLE,
    security_delay        DOUBLE,
    late_aircraft_delay   DOUBLE,
    is_delayed            INT
)
PARTITIONED BY (`year` INT)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/flights/cleaned';
```
Partition discovery and catalog registration are performed using:
```sql
MSCK REPAIR TABLE flights_cleaned;
```
This registers partitions `year=2009` and `year=2010` pointing to their respective HDFS subdirectories.

### 2.2 Dimension Table: `flightdb.carriers_ref`
A managed lookup table mapping 2-letter IATA carrier codes to full airline names:
```sql
CREATE TABLE IF NOT EXISTS carriers_ref (
    carrier_code  STRING,
    carrier_name  STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE;

LOAD DATA LOCAL INPATH '/tmp/carriers.csv' OVERWRITE INTO TABLE carriers_ref;
```

---

## 3. Analytics Design & Metric Definitions

The analytics suite executes 6 analytical queries targeting airline-level and airport-level operational metrics:

1. **`airline_delay_summary`**: Aggregate operational and delay statistics by airline across both years joined with `carriers_ref`.
2. **`airline_delay_by_year`**: Annual comparison of delay percentage and average arrival delay to uncover year-over-year operational trends.
3. **`airline_delay_causes`**: Decomposition of cumulative delay minutes into the 5 standard DOT/FAA categories: Carrier Delay, Weather Delay, NAS (National Airspace System) Delay, Security Delay, and Late Aircraft Delay.
4. **`airport_origin_delays`**: Departure delay rates and average delay minutes for origin airports with $\ge 10,000$ departures, identifying the most congested departure hubs.
5. **`airport_dest_delays`**: Arrival delay rates and average delay minutes for destination airports with $\ge 10,000$ arrivals, identifying terminal airspace bottlenecks.
6. **`airport_dep_vs_arr`**: Full departure vs. arrival delay comparison for top airports, highlighting asymmetric hubs (airports where outbound delays exceed inbound delays or vice versa).

### Standard Metric Definition: `is_delayed`
Per FAA / US DOT standards, a flight is classified as delayed (`is_delayed = 1`) if and only if:
- The flight was **not cancelled** (`cancelled = 0`).
- The flight's arrival delay was $\ge 15$ minutes (`arr_delay >= 15.0`).
- Cancelled flights are tracked separately under `cancelled_flights` and have delay minutes zeroed out during ingestion.

---

## 4. Key Findings & Empirical Results

The analytics suite processed **12,848,658 total flights** across 2009 and 2010.

### 4.1 Airline Delay Rankings
- **Top 3 Worst Airlines by Delay Rate**:
  1. **Comair (OH)**: **25.85%** delayed (74,217 delayed / 287,157 operated; avg dep delay: +10.30 min; avg arr delay: +9.11 min)
  2. **Atlantic Southeast Airlines (EV)**: **22.69%** delayed (136,927 delayed / 603,347 operated; avg dep delay: +11.49 min; avg arr delay: +8.03 min)
  3. **JetBlue Airways (B6)**: **21.72%** delayed (84,242 delayed / 387,857 operated; avg dep delay: +10.26 min; avg arr delay: +5.78 min)
  *(Delta Air Lines (DL) followed closely at 20.58% delay rate across 1,136,678 operated flights)*.

- **Top 3 Best Airlines by Delay Rate**:
  1. **Hawaiian Airlines (HA)**: **7.49%** delayed (10,495 delayed / 140,068 operated; avg dep delay: -0.70 min; avg arr delay: +0.54 min)
  2. **Alaska Airlines (AS)**: **13.72%** delayed (37,234 delayed / 271,302 operated; avg dep delay: +2.35 min; avg arr delay: -0.53 min)
  3. **United Air Lines (UA)**: **15.27%** delayed (107,916 delayed / 706,611 operated; avg dep delay: +7.09 min; avg arr delay: -1.38 min)

### 4.2 Airport Hub Congestion Rankings ($\ge 10,000$ operations)
- **Top Worst Origin Airports (Departure Delays)**:
  1. **MDW (Chicago Midway)**: **25.45%** departure delay rate, avg dep delay +12.38 min
  2. **MIA (Miami International)**: **24.34%** departure delay rate, avg dep delay +13.14 min
  3. **HOU (Houston Hobby)**: **24.33%** departure delay rate, avg dep delay +12.02 min
  4. **EWR (Newark Liberty)**: **22.38%** departure delay rate, avg dep delay +13.10 min

- **Top Worst Destination Airports (Arrival Delays)**:
  1. **EWR (Newark Liberty)**: **28.48%** arrival delay rate, avg arr delay +13.44 min
  2. **SFO (San Francisco International)**: **25.52%** arrival delay rate, avg arr delay +8.86 min
  3. **LGA (New York LaGuardia)**: **25.12%** arrival delay rate, avg arr delay +7.75 min
  4. **JFK (New York JFK)**: **23.50%** arrival delay rate, avg arr delay +6.81 min

*Observation: The New York metro airspace (EWR, LGA, JFK) exhibits the highest structural arrival delays in the United States.*

### 4.3 Root Cause Analysis (Total Delay Minutes Across All Carriers)
| Delay Cause | Total Delay Minutes | Percentage of Total |
|---|---|---|
| **Late Aircraft Delay** | **47,786,973 min** | **37.69%** (Dominant cause) |
| **Carrier Delay** | 37,320,665 min | 29.44% |
| **NAS Delay** | 35,476,094 min | 27.98% |
| **Weather Delay** | 6,010,627 min | 4.74% |
| **Security Delay** | 182,419 min | 0.14% |
| **Total Cause Delay Minutes** | **126,776,778 min** | **100.00%** |

*Takeaway: Downstream reactionary delays ("Late Aircraft Delay") form the single largest component of delay minutes across all commercial airlines, showing strong cascading effects across network schedules.*

### 4.4 Significant Year-over-Year Shifts (2009 vs 2010)
- **Alaska Airlines (AS)** achieved notable improvement: delay rate dropped from **15.77% in 2009** down to **11.68% in 2010** (-4.09 percentage points), with average arrival delay shifting from +1.32 min to -2.37 min (arriving ahead of schedule on average).
- **Pinnacle Airlines (9E)** experienced significant degradation: delay rate rose from **15.09% in 2009** up to **18.90% in 2010** (+3.81 percentage points), with average arrival delay rising from +0.95 min to +3.87 min.

---

## 5. Distributed Execution & Row Count Reconciliation

### 5.1 End-to-End Row Count Reconciliation Table
| Stage / Metric | Year 2009 | Year 2010 | Combined / Verified Total |
|---|---|---|---|
| **Raw Kaggle CSV Ingested** | 6,429,069 | 6,450,485 | 12,879,554 rows |
| **Hadoop Cleaning Filtered Out** | 15,054 | 15,842 | 30,896 corrupt rows |
| **Cleaned Partitions on HDFS** | 6,414,015 | 6,434,643 | **12,848,658 rows** |
| **Hive Table `flights_cleaned`** | 6,414,015 | 6,434,643 | **12,848,658 rows** |
| **Cancelled Flights** | 87,038 | 113,255 | **200,293 flights** |
| **Operated Flights** | 6,326,977 | 6,321,388 | **12,648,365 flights** |
| **Delayed Flights (`is_delayed = 1`)** | 1,170,501 | 1,174,884 | **2,345,385 flights** |
| **Sum of `airline_delay_summary.csv`** | — | — | **12,848,658 rows** (100% exact match) |
| **Overall Flight Delay Rate** | 18.50% | 18.59% | **18.54%** |

### 5.2 YARN Distributed Processing Log Excerpt
Execution evidence from `screenshots/hive-logs/airline_delay_summary.log`:
```text
Starting Job = job_1791880720726_0007, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0007/
2026-10-13 10:11:53,834 Stage-1 map = 0%,  reduce = 0%
2026-10-13 10:12:08,554 Stage-1 map = 50%,  reduce = 0%, Cumulative CPU 22.44 sec
2026-10-13 10:12:10,637 Stage-1 map = 75%,  reduce = 0%, Cumulative CPU 33.43 sec
2026-10-13 10:12:12,706 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 34.61 sec
2026-10-13 10:12:18,090 Stage-1 map = 100%,  reduce = 25%, Cumulative CPU 42.2 sec
2026-10-13 10:12:26,497 Stage-1 map = 100%,  reduce = 50%, Cumulative CPU 57.58 sec
2026-10-13 10:12:28,587 Stage-1 map = 100%,  reduce = 75%, Cumulative CPU 73.44 sec
2026-10-13 10:12:33,880 Stage-1 map = 100%,  reduce = 98%, Cumulative CPU 93.68 sec
2026-10-13 10:12:37,072 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 97.39 sec
MapReduce Total cumulative CPU time: 1 minutes 37 seconds 390 msec
Ended Job = job_1791880720726_0007
Stage-Stage-1: Map: 4  Reduce: 4   Cumulative CPU: 97.39 sec   HDFS Read: 993729810 HDFS Write: 1701 SUCCESS
Stage-Stage-2: Map: 1  Reduce: 1   Cumulative CPU: 2.72 sec   HDFS Read: 14643 HDFS Write: 1488 SUCCESS
Stage-Stage-3: Map: 1  Reduce: 1   Cumulative CPU: 2.32 sec   HDFS Read: 11910 HDFS Write: 1509 SUCCESS
Status: SUCCEEDED
```

Both NodeManagers (`nodemanager1` and `nodemanager2`) actively scheduled containers, and all 24 YARN applications completed with final status `SUCCEEDED`.

---

## 6. Reproducibility Instructions

To reproduce table creation and run the analytical queries:

1. **Start the Cluster & Verify Services**:
   ```bash
   ./scripts/start-cluster.sh
   ./scripts/verify-cluster.sh
   ```

2. **Access Hive CLI**:
   Execute interactive Hive queries or scripts through the host helper script:
   ```bash
   ./scripts/hive-exec.sh -e "SHOW TABLES IN flightdb;"
   ```

3. **Execute the Complete Analytics Pipeline**:
   ```bash
   ./src/analytics/run_airline_airport_analytics.sh
   ```
   Outputs are generated in `output/airline_airport/` as clean CSV files, and query logs are preserved in `screenshots/hive-logs/`.
