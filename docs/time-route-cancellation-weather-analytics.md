# Time, Route, Cancellation, and Weather Analytics (Hive on YARN)

## 1. Overview & Purpose

In Phase 6, we expanded the analytical scope of the Airline Flight Delay Analytics system by running 12 comprehensive analytical queries across four core operational themes:
1. **Time-Based Delay Analytics** (month, year-month, day-of-week, departure hour).
2. **Route-Wise Delay Analytics** (highest delay rates and highest traffic volume).
3. **Cancellation Analytics** (breakdown by cause, carrier, origin airport, and seasonality).
4. **Weather Impact Analytics** (weather delay intensity by airport and monthly distribution).

All queries executed using **Apache Hive 3.1.3** running on the distributed **MapReduce on YARN** execution engine over the partitioned table `flightdb.flights_cleaned` (12,848,658 total flight records across 2009 and 2010).

---

## 2. Query Catalog & Output Artifacts

| Theme | Query File | Target Output CSV | Description |
|---|---|---|---|
| **Time** | `src/analytics/queries/delay_by_month.hql` | `output/time_analysis/delay_by_month.csv` | Monthly delay rates and average arrival delays |
| **Time** | `src/analytics/queries/delay_by_year_month.hql` | `output/time_analysis/delay_by_year_month.csv` | Annual-monthly operational trends |
| **Time** | `src/analytics/queries/delay_by_day_of_week.hql` | `output/time_analysis/delay_by_day_of_week.csv` | Day-of-week delay variation (Mon–Sun) |
| **Time** | `src/analytics/queries/delay_by_dep_hour.hql` | `output/time_analysis/delay_by_dep_hour.csv` | Hourly departure delay patterns & time buckets |
| **Route** | `src/analytics/queries/route_worst_delays.hql` | `output/route_analysis/route_worst_delays.csv` | Top 25 routes with highest delay % ($\ge 2,000$ flights) |
| **Route** | `src/analytics/queries/route_busiest.hql` | `output/route_analysis/route_busiest.csv` | Top 25 busiest routes by scheduled volume |
| **Cancellation** | `src/analytics/queries/cancellation_by_reason.hql` | `output/cancellation_analysis/cancellation_by_reason.csv` | Cancellation distribution across official FAA codes |
| **Cancellation** | `src/analytics/queries/cancellation_by_carrier.hql` | `output/cancellation_analysis/cancellation_by_carrier.csv` | Airline cancellation rates joined with carrier names |
| **Cancellation** | `src/analytics/queries/cancellation_by_airport.hql` | `output/cancellation_analysis/cancellation_by_airport.csv` | Top 25 airports with highest cancel % ($\ge 10,000$ dep) |
| **Cancellation** | `src/analytics/queries/cancellation_by_month.hql` | `output/cancellation_analysis/cancellation_by_month.csv` | Monthly cancellation breakdown by reason category |
| **Weather** | `src/analytics/queries/weather_by_airport.hql` | `output/weather_analysis/weather_by_airport.csv` | Weather delay minutes per 1,000 flights ($\ge 10,000$ dep) |
| **Weather** | `src/analytics/queries/weather_by_month.hql` | `output/weather_analysis/weather_by_month.csv` | Seasonal weather delay share and weather cancels |

---

## 3. Metric Definitions & Filtering Rules

- **`delay_pct`**: Calculated as:
  $$\text{delay\_pct} = 100.0 \times \frac{\sum \text{is\_delayed}}{\sum (\text{CASE WHEN cancelled = 0 THEN 1 ELSE 0 END})}$$
  Per FAA standard, `is_delayed = 1` indicates an arrival delay $\ge 15.0$ minutes on an operated flight.
- **`cancel_pct`**: Calculated as:
  $$\text{cancel\_pct} = 100.0 \times \frac{\sum \text{cancelled}}{\text{COUNT}(*)}$$
- **Volume Thresholds**:
  - Route rankings require $\ge 2,000$ scheduled flights over the 2-year period to eliminate low-sample statistical noise.
  - Airport rankings require $\ge 10,000$ departures.
- **Time Buckets (by scheduled departure hour `dep_hour`)**:
  - `Night (00-05)`: Hours 0, 1, 2, 3, 4, 5
  - `Morning (06-11)`: Hours 6, 7, 8, 9, 10, 11
  - `Afternoon (12-17)`: Hours 12, 13, 14, 15, 16, 17
  - `Evening (18-23)`: Hours 18, 19, 20, 21, 22, 23
- **Cause-Minutes Caveat**:
  The US DOT only collects cause delay minutes (carrier, weather, NAS, security, late aircraft) for flights delayed by $\ge 15$ minutes; on-time or non-delayed flights have these fields cleaned to 0. Therefore, weather delay shares (`weather_share_pct`) represent the fraction of *reported cause delay minutes*, not total elapsed flight time.

---

## 4. Empirical Results Summary

All figures below are extracted directly from the verified CSV outputs in `output/`:

### 4.1 Temporal Trends (Time Analysis)
- **Month Analysis**:
  - **Worst Month**: **December (Month 12)** with **25.38%** delay rate (261,783 delayed / 1,031,373 operated; avg arrival delay: +9.28 min). June (22.31%) and July (21.58%) follow as secondary summer peaks.
  - **Best Month**: **September (Month 9)** with **13.44%** delay rate (avg arrival delay: +0.16 min), closely followed by November (13.48%, avg arrival delay: -1.09 min).
- **Day of Week**:
  - **Worst Day**: **Friday (Day 5)** with **19.89%** delay rate (372,253 delayed / 1,871,592 operated; avg arrival delay: +5.80 min), followed by Thursday (19.63%) and Monday (19.53%).
  - **Best Day**: **Saturday (Day 6)** with **16.07%** delay rate (246,917 delayed / 1,536,259 operated; avg arrival delay: +1.69 min), followed by Tuesday (17.20%).
- **Departure Hour & Diurnal Cascading Trend**:
  - **Worst Departure Hour**: **Hour 20 (8 PM)** with **25.87%** delay rate (119,813 delayed / 463,165 operated; avg departure delay: +14.14 min, avg arrival delay: +9.33 min).
  - **Best Departure Hour**: **Hour 5 (5 AM)** with **8.57%** delay rate (9,630 delayed / 112,389 operated; avg departure delay: +0.53 min, avg arrival delay: -2.21 min).
  - **Time Bucket Trend**: Delays compound progressively across the operating day:
    - *Night (00–05)*: Baseline reset period (avg 8.57%–13.85% delay, except low-volume 2 AM red-eyes).
    - *Morning (06–11)*: Low to moderate delays (9.54% at 6 AM rising to 15.63% at 11 AM).
    - *Afternoon (12–17)*: Rapid accumulation (17.51% at 12 PM climbing to 24.31% at 5 PM).
    - *Evening (18–23)*: Peak congestion window (25.35% at 6 PM, peaking at 25.87% at 8 PM, remaining above 23% until midnight).

### 4.2 Route Congestion & Volume (Route Analysis)
- **Top 5 Worst Routes by Delay Rate ($\ge 2,000$ flights)**:
  1. **MEM $\rightarrow$ EWR (Memphis to Newark)**: **39.83%** delay rate (2,289 flights, avg arr delay: +24.59 min, 946 mi)
  2. **CVG $\rightarrow$ EWR (Cincinnati to Newark)**: **39.23%** delay rate (4,226 flights, avg arr delay: +24.65 min, 569 mi)
  3. **DTW $\rightarrow$ JFK (Detroit to New York JFK)**: **37.86%** delay rate (2,493 flights, avg arr delay: +17.48 min, 508 mi)
  4. **CVG $\rightarrow$ JFK (Cincinnati to New York JFK)**: **37.12%** delay rate (2,080 flights, avg arr delay: +17.80 min, 589 mi)
  5. **CHS $\rightarrow$ EWR (Charleston to Newark)**: **34.74%** delay rate (2,069 flights, avg arr delay: +22.22 min, 628 mi)
  *(Notice: All 5 worst routes in the entire United States fly into the New York metro terminal area: EWR or JFK)*.
- **Top 3 Busiest Routes**:
  1. **OGG $\rightarrow$ HNL (Kahului to Honolulu)**: **25,292** flights (153 cancelled, 7.74% delay, avg arr delay: +0.96 min)
  2. **HNL $\rightarrow$ OGG (Honolulu to Kahului)**: **24,560** flights (123 cancelled, 6.83% delay, avg arr delay: +0.80 min)
  3. **LAX $\rightarrow$ SFO (Los Angeles to San Francisco)**: **24,172** flights (589 cancelled, 26.82% delay, avg arr delay: +10.60 min)

### 4.3 Cancellation Breakdown
- **Cancellation Reasons (200,293 total cancellations)**:
  - **Weather (B)**: **93,158** cancellations (**46.51%** — dominant driver)
  - **Carrier (A)**: **77,724** cancellations (**38.81%**)
  - **National Air System (C)**: **29,352** cancellations (**14.65%**)
  - **Security (D)**: **59** cancellations (**0.03%**)
- **Top 3 Carriers with Highest Cancellation Rate**:
  1. **Comair (OH)**: **3.61%** (10,753 cancelled / 297,910 total)
  2. **American Eagle Airlines (MQ)**: **2.62%** (22,770 cancelled / 870,480 total)
  3. **Pinnacle Airlines (9E)**: **2.35%** (12,247 cancelled / 522,122 total)
- **Top 5 Origin Airports with Highest Cancellation Rate ($\ge 10,000$ departures)**:
  1. **LGA (New York LaGuardia)**: **4.12%** (8,332 cancelled / 202,349 total; 3,469 weather cancels)
  2. **CID (Cedar Rapids)**: **3.44%** (535 cancelled / 15,571 total; 271 weather cancels)
  3. **DCA (Washington Reagan National)**: **3.27%** (5,172 cancelled / 158,223 total; 2,657 weather cancels)
  4. **BTV (Burlington)**: **3.13%** (396 cancelled / 12,649 total; 228 weather cancels)
  5. **XNA (Northwest Arkansas)**: **3.12%** (859 cancelled / 27,523 total; 386 weather cancels)
- **Peak Weather Cancellation Month**:
  - **December (Month 12)** recorded the highest absolute weather cancellations at **22,070 flights**, closely followed by **February (Month 2)** with **22,053 flights**.

### 4.4 Weather Impact Analysis
- **Top 5 Airports with Highest Weather Delay Intensity (Minutes per 1,000 Flights)**:
  1. **JFK (New York JFK)**: **1,257.9 min / 1,000 flights** (290,684 weather delay min across 231,082 departures; 4,515 flights affected)
  2. **BTR (Baton Rouge)**: **1,185.5 min / 1,000 flights** (20,972 weather delay min across 17,691 departures)
  3. **MIA (Miami International)**: **1,127.4 min / 1,000 flights** (149,996 weather delay min across 133,041 departures)
  4. **LFT (Lafayette)**: **1,110.3 min / 1,000 flights** (11,792 weather delay min across 10,621 departures)
  5. **DFW (Dallas/Fort Worth)**: **1,051.5 min / 1,000 flights** (558,118 weather delay min across 530,760 departures)
- **Peak Weather Share Month**:
  - **January (Month 1)** recorded the highest weather share of cause minutes at **5.83%** (625,591 weather delay min, 40.5 avg min per affected flight), followed by December at **5.31%** (768,712 min) and June at **5.22%** (739,436 min).

---

## 5. Output Validation & Reconciliation

The automated test script `src/analytics/validate_phase6_outputs.sh` validated all 10 major output counts against reference HDFS partition totals (`screenshots/26-hive-partition-rowcounts.txt`):

```text
Reference totals from phase 5 validation: rows=12848658 cancelled=200293
OK   delay_by_month total_flights: 12848658
OK   delay_by_year_month total_flights: 12848658
OK   delay_by_day_of_week total_flights: 12848658
OK   delay_by_dep_hour total_flights: 12848658
OK   cancellation_by_reason cancelled: 200293
OK   cancellation_by_month total_flights: 12848658
OK   cancellation_by_month cancelled: 200293
OK   cancellation_by_carrier total_flights: 12848658
OK   cancellation_by_carrier cancelled: 200293
OK   weather_by_month total_flights: 12848658
```

All 10 tests passed with 100% exact equality.

---

## 6. Distributed YARN Execution Proofs

Every query was compiled into one or more MapReduce stages and executed across both worker NodeManagers on YARN (`screenshots/31-yarn-applications-phase6.txt`, `screenshots/32-yarn-nodes-phase6.txt`).

### 6.1 Time Analysis Group: `delay_by_month.log`
```text
Starting Job = job_1791880720726_0025, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0025/
Hadoop job information for Stage-1: number of mappers: 3; number of reducers: 4
2026-10-14 07:09:17,535 Stage-1 map = 0%,  reduce = 0%
2026-10-14 07:10:26,825 Stage-1 map = 100%,  reduce = 6%, Cumulative CPU 12.68 sec
2026-10-14 07:10:33,123 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 21.04 sec
MapReduce Total cumulative CPU time: 21 seconds 40 msec
Ended Job = job_1791880720726_0025
Status: SUCCEEDED
```

### 6.2 Route Analysis Group: `route_worst_delays.log`
```text
Starting Job = job_1791880720726_0033, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0033/
Hadoop job information for Stage-1: number of mappers: 3; number of reducers: 4
2026-10-14 07:14:42,692 Stage-1 map = 0%,  reduce = 0%
2026-10-14 07:14:55,234 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 17.82 sec
2026-10-14 07:15:04,680 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 30.01 sec
MapReduce Total cumulative CPU time: 30 seconds 10 msec
Ended Job = job_1791880720726_0033
Starting Job = job_1791880720726_0034, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0034/
Hadoop job information for Stage-2: number of mappers: 1; number of reducers: 1
2026-10-14 07:15:28,315 Stage-2 map = 100%,  reduce = 100%, Cumulative CPU 2.55 sec
Status: SUCCEEDED
```

### 6.3 Cancellation Analysis Group: `cancellation_by_reason.log`
```text
Starting Job = job_1791880720726_0037, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0037/
Hadoop job information for Stage-1: number of mappers: 3; number of reducers: 4
2026-10-14 07:16:58,984 Stage-1 map = 0%,  reduce = 0%
2026-10-14 07:17:11,552 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 8.75 sec
2026-10-14 07:17:20,030 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 21.04 sec
MapReduce Total cumulative CPU time: 21 seconds 40 msec
Ended Job = job_1791880720726_0037
Starting Job = job_1791880720726_0038, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0038/
Hadoop job information for Stage-2: number of mappers: 1; number of reducers: 1
2026-10-14 07:17:45,764 Stage-2 map = 100%,  reduce = 100%, Cumulative CPU 2.97 sec
Status: SUCCEEDED
```

### 6.4 Weather Analysis Group: `weather_by_month.log`
```text
Starting Job = job_1791880720726_0049, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0049/
Hadoop job information for Stage-1: number of mappers: 3; number of reducers: 4
2026-10-14 07:24:09,068 Stage-1 map = 0%,  reduce = 0%
2026-10-14 07:24:26,121 Stage-1 map = 100%,  reduce = 0%, Cumulative CPU 24.74 sec
2026-10-14 07:24:36,841 Stage-1 map = 100%,  reduce = 100%, Cumulative CPU 39.14 sec
MapReduce Total cumulative CPU time: 39 seconds 140 msec
Ended Job = job_1791880720726_0049
Starting Job = job_1791880720726_0050, Tracking URL = http://resourcemanager:8088/proxy/application_1791880720726_0050/
Hadoop job information for Stage-2: number of mappers: 1; number of reducers: 1
2026-10-14 07:24:57,417 Stage-2 map = 100%,  reduce = 0%, Cumulative CPU 1.15 sec
Status: SUCCEEDED
```

### 6.5 Evidence Artifacts
- `screenshots/31-yarn-applications-phase6.txt`: Complete list of 50 YARN application IDs and states.
- `screenshots/32-yarn-nodes-phase6.txt`: Live NodeManager status report showing 2 healthy nodes.
- `screenshots/33-resourcemanager-ui-phase6-jobs.png`: Web UI capture of ResourceManager Applications page.
