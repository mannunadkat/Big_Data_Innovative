# Airline Flight Delay Analytics & Prediction

## Overview
A Big Data Analytics project analyzing large-scale US airline flight records to
identify patterns in flight delays and cancellations, and to predict whether a
given flight is likely to be delayed. Built entirely on the Hadoop ecosystem
(HDFS, MapReduce, Hive) executed across a 3-node cluster (1 master, 2 workers).
Apache Spark and Apache Pig are intentionally NOT used in this implementation.

## Objectives
- Analyze delay patterns by airline, airport, month, time-of-day, and route
- Analyze weather-related delay impact
- Analyze cancellation patterns
- Build a Hadoop-native (Hive-based historical probability) delay-prediction model

## Tech Stack
- Hadoop HDFS — distributed storage
- Hadoop MapReduce (Java / Hadoop Streaming) — distributed processing and data cleaning
- Apache Hive — SQL-style analytics on HDFS data
- 3-node cluster: 1 master (NameNode + ResourceManager), 2 workers (DataNode + NodeManager)

## Dataset
US DOT Airline On-Time Performance dataset (source: [add exact Kaggle/DOT link here]).
Fields used include: airline/carrier, origin, destination, scheduled/actual
departure & arrival times, departure delay, arrival delay, cancelled flag,
cancellation reason, weather delay minutes.

## Repository Structure
- `dataset/` — raw and cleaned data references (large files kept out of git; live on HDFS)
- `src/ingestion/` — scripts to load data into HDFS
- `src/processing/` — cleaning jobs (Hadoop Streaming / MapReduce)
- `src/analytics/` — Hive queries / MapReduce jobs for each analysis
- `scripts/` — cluster start/stop and utility scripts
- `config/` — Hadoop cluster config files (core-site.xml, hdfs-site.xml, etc.)
- `output/` — analytics results, charts, prediction outputs
- `screenshots/` — cluster status, job execution, output proofs
- `docs/` — setup docs, architecture notes, prediction model writeup
- `pipeline/` — end-to-end pipeline orchestration scripts

## Team
- Mann — [role: cluster setup / MapReduce jobs / prediction model — fill in]
- [Teammate name] — [role — fill in]

## Status
Phase 5 of 10 complete: Apache Hive 3.1.3 installed on the master node (YARN / MapReduce engine), external partitioned tables created over 12,848,658 cleaned flight records, and 6 airline/airport analytics queries executed to CSV.
- Full writeup & findings: [`docs/hive-and-airline-airport-analytics.md`](docs/hive-and-airline-airport-analytics.md)
- Generated CSV datasets: [`output/airline_airport/`](output/airline_airport/)
  - `airline_delay_summary.csv` — Airline delay rankings and operating volume
  - `airline_delay_by_year.csv` — Year-over-year carrier performance (2009 vs 2010)
  - `airline_delay_causes.csv` — Root-cause delay minute decomposition
  - `airport_origin_delays.csv` — Most congested departure airports
  - `airport_dest_delays.csv` — Most congested arrival airports
  - `airport_dep_vs_arr.csv` — Outbound vs inbound delay comparison

