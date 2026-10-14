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
Phase 6 of 10 complete: time, route, cancellation and weather analytics on Hive/YARN.
- Full writeup & findings: [`docs/time-route-cancellation-weather-analytics.md`](docs/time-route-cancellation-weather-analytics.md)
- Phase 5 Hive setup & airline/airport writeup: [`docs/hive-and-airline-airport-analytics.md`](docs/hive-and-airline-airport-analytics.md)
- Generated CSV datasets:
  - [`output/time_analysis/`](output/time_analysis/) — Delay by month, year-month, day of week, and departure hour
  - [`output/route_analysis/`](output/route_analysis/) — Worst delayed routes and busiest routes
  - [`output/cancellation_analysis/`](output/cancellation_analysis/) — Cancellation by reason, carrier, airport, and month
  - [`output/weather_analysis/`](output/weather_analysis/) — Weather delay intensity by airport and monthly distribution
  - [`output/airline_airport/`](output/airline_airport/) — Phase 5 airline and airport delay summaries

