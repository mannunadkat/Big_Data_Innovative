# Pipeline Orchestrator

## Purpose
`pipeline/run_pipeline.sh` orchestrates the complete Airline Flight Delay Analytics & Prediction workflow end-to-end: from raw CSV ingestion to HDFS, MapReduce data cleaning, Hive table definitions, distributed SQL analytics, custom Java MapReduce processing, historical probability model building, validation/test scoring, single-flight demo predictions, visualization chart generation, and cluster verification.

## Prerequisites
- **Docker & Docker Compose**: Installed and running on the host machine.
- **Raw Data Files**: Yearly CSV files named `YYYY.csv` (e.g., `2009.csv`, `2010.csv`) placed in `dataset/raw/`.
- **Free Disk Space**: At least 10–15 GB free disk space recommended for Docker containers, local volumes, and HDFS blocks.
- **Network**: No active internet access is required during pipeline execution, except for the initial download of the Apache Hive binary in `scripts/setup-hive.sh` if not already cached.

---

## Pipeline Stages

| Stage Number | Stage Name | What It Runs | Main Output Location |
|:---:|:---|:---|:---|
| 1 | `cluster` | `scripts/start-cluster.sh` | 7 Docker containers running on host |
| 2 | `ingest` | `src/ingestion/ingest_to_hdfs.sh`<br>`src/ingestion/verify_ingestion.sh` | HDFS `/flights/raw/year=YYYY` |
| 3 | `clean` | `src/processing/run_cleaning.sh`<br>`src/processing/verify_cleaning.sh` | HDFS `/flights/cleaned/year=YYYY` |
| 4 | `hive_tables` | `scripts/setup-hive.sh`<br>`src/analytics/00_create_tables.hql`<br>`src/analytics/queries/validation_counts.hql` | Hive tables: `flights_cleaned`, `carriers_ref` |
| 5 | `analytics_airline_airport` | `src/analytics/run_airline_airport_analytics.sh` | `output/airline_airport/*.csv` |
| 6 | `analytics_time_route_cancel_weather` | `src/analytics/run_time_route_cancel_weather.sh`<br>`src/analytics/validate_phase6_outputs.sh` | `output/time_analysis/*.csv`<br>`output/route_analysis/*.csv`<br>`output/cancellation_analysis/*.csv`<br>`output/weather_analysis/*.csv` |
| 7 | `mapreduce` | `src/processing/mapreduce/build_mr_job.sh`<br>`src/processing/mapreduce/run_mr_job.sh`<br>`src/analytics/crosscheck_mr_vs_hive.sh`<br>`src/processing/mapreduce/validate_mr_output.sh` | HDFS `/flights/mr_output`<br>`output/mapreduce/carrier_month_delay.csv` |
| 8 | `model_build` | `src/analytics/prediction/run_model_build.sh`<br>`src/analytics/prediction/validate_model_build.sh` | Hive tables: `flights_split`, `model_l1` to `model_l4`, `model_global`<br>`output/prediction_model/*.csv` |
| 9 | `scoring` | `src/analytics/prediction/run_scoring_and_eval.sh`<br>`src/analytics/prediction/validate_scoring.sh`<br>`src/analytics/prediction/run_prediction_demo.sh` | Hive table: `flights_scored`<br>`output/prediction_results/*.csv` |
| 10 | `charts` | `src/analytics/make_charts.sh` | `output/charts/*.png` (13 charts) |
| 11 | `verify` | `scripts/final-verification.sh pipeline-run` | `screenshots/final/pipeline-run/` |

---

## Usage Instructions

```bash
# 1. List all available stages
./pipeline/run_pipeline.sh --list

# 2. Execute a single specific stage
./pipeline/run_pipeline.sh --stage charts

# 3. Resume execution from a specific stage onward
./pipeline/run_pipeline.sh --from model_build

# 4. Run the entire pipeline end-to-end
./pipeline/run_pipeline.sh --all
```

---

## Execution Duration & Operational Notes
- **Stage Timing Guide (Approximate & Machine-Dependent)**:
  - `cluster`, `ingest`, `charts`, and `verify` are quick (each taking a few seconds to 1–2 minutes).
  - `clean` runs MapReduce streaming jobs across multi-gigabyte raw files and takes several minutes.
  - The Hive analytics query stages (`analytics_airline_airport`, `analytics_time_route_cancel_weather`), the custom Java `mapreduce` job, and the `model_build` and `scoring` stages execute distributed MapReduce jobs on YARN and take the longest time.
- **Idempotency & Re-runnability**: Stages are designed to be safely re-runnable.
- **Metastore Concurrency Constraint**: Apache Hive uses an embedded Derby metastore inside the `namenode` container. Embedded Derby supports **only ONE active Hive session at a time**. Never run multiple pipeline stages or background Hive queries concurrently.
