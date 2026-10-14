#!/bin/bash
# Orchestrates the whole project: raw CSVs -> HDFS -> cleaning -> Hive -> analytics -> MapReduce -> model -> scoring -> charts
# Usage:
#   ./pipeline/run_pipeline.sh --list
#   ./pipeline/run_pipeline.sh --stage <name>
#   ./pipeline/run_pipeline.sh --from <name>     (run <name> and every later stage)
#   ./pipeline/run_pipeline.sh --all
set -e
set -o pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
STAGES=(cluster ingest clean hive_tables analytics_airline_airport analytics_time_route_cancel_weather mapreduce model_build scoring charts verify)
stage_cluster() { ./scripts/start-cluster.sh; }
stage_ingest() { ./src/ingestion/ingest_to_hdfs.sh; ./src/ingestion/verify_ingestion.sh; }
stage_clean() { ./src/processing/run_cleaning.sh; ./src/processing/verify_cleaning.sh; }
stage_hive_tables() {
  ./scripts/setup-hive.sh
  ./scripts/hive-exec.sh src/analytics/00_create_tables.hql
  ./scripts/hive-exec.sh src/analytics/queries/validation_counts.hql 2>/dev/null
}
stage_analytics_airline_airport() { ./src/analytics/run_airline_airport_analytics.sh; }
stage_analytics_time_route_cancel_weather() { ./src/analytics/run_time_route_cancel_weather.sh; ./src/analytics/validate_phase6_outputs.sh; }
stage_mapreduce() {
  ./src/processing/mapreduce/build_mr_job.sh
  ./src/processing/mapreduce/run_mr_job.sh
  ./src/analytics/crosscheck_mr_vs_hive.sh
  ./src/processing/mapreduce/validate_mr_output.sh
}
stage_model_build() { ./src/analytics/prediction/run_model_build.sh; ./src/analytics/prediction/validate_model_build.sh; }
stage_scoring() {
  ./src/analytics/prediction/run_scoring_and_eval.sh
  ./src/analytics/prediction/validate_scoring.sh
  ./src/analytics/prediction/run_prediction_demo.sh
}
stage_charts() { ./src/analytics/make_charts.sh; }
stage_verify() { ./scripts/final-verification.sh pipeline-run; }
list_stages() { local i=1; for s in "${STAGES[@]}"; do echo "$i. $s"; i=$((i+1)); done; }
usage() { sed -n '2,8p' "$0"; echo; list_stages; }
valid() { local s; for s in "${STAGES[@]}"; do if [ "$s" = "$1" ]; then return 0; fi; done; return 1; }
run_stage() { echo; echo "######## STAGE: $1 ########"; "stage_$1"; }
case "${1:-}" in
  --list) list_stages ;;
  --stage)
    if ! valid "${2:-}"; then echo "Unknown or missing stage name"; usage; exit 2; fi
    run_stage "$2" ;;
  --from)
    if ! valid "${2:-}"; then echo "Unknown or missing stage name"; usage; exit 2; fi
    started=0
    for s in "${STAGES[@]}"; do
      if [ "$s" = "$2" ]; then started=1; fi
      if [ "$started" = "1" ]; then run_stage "$s"; fi
    done ;;
  --all) for s in "${STAGES[@]}"; do run_stage "$s"; done ;;
  *) usage; exit 2 ;;
esac
echo; echo "Pipeline finished."
