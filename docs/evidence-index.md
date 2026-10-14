# Evidence Index

This document maps the five core big data engineering deliverables required for academic evaluation to concrete evidence files, execution logs, and output artifacts that exist in this repository.

---

## 1. Deliverables Evidence Matrix

| Requirement | Deliverable Focus | Evidence Files in Repository |
|:---|:---|:---|
| **1. Node Configuration** | 3-node cluster topology, environment variables, daemon assignments, and container setup | - [`config/docker-compose.yml`](../config/docker-compose.yml)<br>- [`config/hadoop.env`](../config/hadoop.env)<br>- [`docs/cluster-setup.md`](cluster-setup.md)<br>- [`screenshots/docker-ps.txt`](../screenshots/docker-ps.txt)<br>- [`screenshots/jps-all.txt`](../screenshots/jps-all.txt) |
| **2. Cluster Status** | Live DataNodes, running NodeManagers, daemon processes, and UI proofs | - [`screenshots/01-hdfs-dfsadmin-report.txt`](../screenshots/01-hdfs-dfsadmin-report.txt)<br>- [`screenshots/02-yarn-node-list.txt`](../screenshots/02-yarn-node-list.txt)<br>- [`screenshots/03-docker-ps.txt`](../screenshots/03-docker-ps.txt)<br>- [`screenshots/11-namenode-ui-datanodes.png`](../screenshots/11-namenode-ui-datanodes.png)<br>- [`screenshots/13-resourcemanager-ui-job.png`](../screenshots/13-resourcemanager-ui-job.png)<br>- [`screenshots/final/before-restart/01-docker-ps.txt`](../screenshots/final/before-restart/01-docker-ps.txt)<br>- [`screenshots/final/before-restart/02-hdfs-dfsadmin-report.txt`](../screenshots/final/before-restart/02-hdfs-dfsadmin-report.txt)<br>- [`screenshots/final/before-restart/03-yarn-node-list.txt`](../screenshots/final/before-restart/03-yarn-node-list.txt)<br>- [`screenshots/final/before-restart/04-jps-all-nodes.txt`](../screenshots/final/before-restart/04-jps-all-nodes.txt)<br>- [`screenshots/final/after-restart/01-docker-ps.txt`](../screenshots/final/after-restart/01-docker-ps.txt)<br>- [`screenshots/final/after-restart/02-hdfs-dfsadmin-report.txt`](../screenshots/final/after-restart/02-hdfs-dfsadmin-report.txt)<br>- [`screenshots/final/after-restart/03-yarn-node-list.txt`](../screenshots/final/after-restart/03-yarn-node-list.txt)<br>- [`screenshots/final/after-restart/04-jps-all-nodes.txt`](../screenshots/final/after-restart/04-jps-all-nodes.txt) |
| **3. Storage Distribution** | HDFS block placement, replication factor 2 across both DataNodes, and filesystem health | - Raw data: [`screenshots/14-hdfs-raw-ls.txt`](../screenshots/14-hdfs-raw-ls.txt), [`screenshots/15-hdfs-raw-du.txt`](../screenshots/15-hdfs-raw-du.txt), [`screenshots/16-hdfs-raw-fsck.txt`](../screenshots/16-hdfs-raw-fsck.txt)<br>- Cleaned data: [`screenshots/19-hdfs-cleaned-du.txt`](../screenshots/19-hdfs-cleaned-du.txt)<br>- Split tables: [`screenshots/44-hdfs-model-tables-du.txt`](../screenshots/44-hdfs-model-tables-du.txt), [`screenshots/45-hdfs-flights-split-fsck.txt`](../screenshots/45-hdfs-flights-split-fsck.txt)<br>- Scored data: [`screenshots/50-hdfs-flights-scored-du.txt`](../screenshots/50-hdfs-flights-scored-du.txt), [`screenshots/50b-hdfs-flights-scored-fsck.txt`](../screenshots/50b-hdfs-flights-scored-fsck.txt)<br>- Final checks: [`screenshots/final/before-restart/05-hdfs-flights-du.txt`](../screenshots/final/before-restart/05-hdfs-flights-du.txt), [`screenshots/final/before-restart/06-hdfs-fsck-summary.txt`](../screenshots/final/before-restart/06-hdfs-fsck-summary.txt), [`screenshots/final/after-restart/05-hdfs-flights-du.txt`](../screenshots/final/after-restart/05-hdfs-flights-du.txt), [`screenshots/final/after-restart/06-hdfs-fsck-summary.txt`](../screenshots/final/after-restart/06-hdfs-fsck-summary.txt) |
| **4. Distributed Execution** | MapReduce jobs, YARN task containers, and query execution logs | - Verification job: [`screenshots/08-mapreduce-wordcount-log.txt`](../screenshots/08-mapreduce-wordcount-log.txt)<br>- Cleaning streaming jobs: [`screenshots/18-clean-job-2009.log`](../screenshots/18-clean-job-2009.log), [`screenshots/18-clean-job-2010.log`](../screenshots/18-clean-job-2010.log)<br>- Custom Java MR: [`screenshots/35-mr-carrier-month-delay-job.log`](../screenshots/35-mr-carrier-month-delay-job.log), [`screenshots/41-mr-container-nodes.txt`](../screenshots/41-mr-container-nodes.txt), [`screenshots/42-resourcemanager-ui-mr-job.png`](../screenshots/42-resourcemanager-ui-mr-job.png)<br>- Hive on YARN queries: [`screenshots/hive-logs/`](../screenshots/hive-logs/)<br>- YARN App tracking: [`screenshots/27-yarn-applications-hive.txt`](../screenshots/27-yarn-applications-hive.txt), [`screenshots/31-yarn-applications-phase6.txt`](../screenshots/31-yarn-applications-phase6.txt), [`screenshots/39-yarn-applications-mr.txt`](../screenshots/39-yarn-applications-mr.txt), [`screenshots/46-yarn-applications-phase8.txt`](../screenshots/46-yarn-applications-phase8.txt), [`screenshots/51-yarn-applications-phase9.txt`](../screenshots/51-yarn-applications-phase9.txt), [`screenshots/final/yarn-applications-tail.txt`](../screenshots/final/yarn-applications-tail.txt) |
| **5. Analytics & Prediction Outputs** | CSV result tables, visual charts, and documentation reports | - Result CSVs: [`output/airline_airport/`](../output/airline_airport/), [`output/time_analysis/`](../output/time_analysis/), [`output/route_analysis/`](../output/route_analysis/), [`output/cancellation_analysis/`](../output/cancellation_analysis/), [`output/weather_analysis/`](../output/weather_analysis/), [`output/mapreduce/`](../output/mapreduce/), [`output/prediction_model/`](../output/prediction_model/), [`output/prediction_results/`](../output/prediction_results/)<br>- Visualization Charts: [`output/charts/`](../output/charts/) (13 PNGs)<br>- Reports: [`docs/hive-and-airline-airport-analytics.md`](hive-and-airline-airport-analytics.md), [`docs/time-route-cancellation-weather-analytics.md`](time-route-cancellation-weather-analytics.md), [`docs/custom-mapreduce-job.md`](custom-mapreduce-job.md), [`docs/prediction-results.md`](prediction-results.md), [`docs/analytics-charts.md`](analytics-charts.md) |

---

## 2. Evidence Files Index

| File Name | Description |
|:---|:---|
| `screenshots/01-hdfs-dfsadmin-report.txt` | Initial cluster dfsadmin report showing 2 live DataNodes and configured storage |
| `screenshots/02-yarn-node-list.txt` | Initial YARN node list showing both NodeManagers RUNNING |
| `screenshots/03-docker-ps.txt` | Initial docker ps output showing 7 healthy containers |
| `screenshots/04-hdfs-ls-demo.txt` | HDFS listing proving basic directory structure creation |
| `screenshots/05-hdfs-du-demo.txt` | HDFS du output demonstrating initial file storage |
| `screenshots/06-hdfs-fsck-block-locations.txt` | HDFS fsck report showing block distribution across both DataNode containers |
| `screenshots/07-hdfs-report-after-upload.txt` | HDFS report confirming DataNode disk usage after initial file upload |
| `screenshots/08-mapreduce-wordcount-log.txt` | Console log from smoke-test MapReduce WordCount execution on YARN |
| `screenshots/09-mapreduce-wordcount-output.txt` | Result output from WordCount job |
| `screenshots/10-yarn-application-list.txt` | YARN application list confirming completion of the WordCount MapReduce job |
| `screenshots/11-namenode-ui-datanodes.png` | NameNode web interface displaying live DataNodes |
| `screenshots/11a-namenode-ui-overview.png` | NameNode web interface overview tab |
| `screenshots/11b-namenode-ui-summary-live-nodes.png` | NameNode web interface summary table showing live DataNodes |
| `screenshots/11c-namenode-ui-volume-failures.png` | NameNode web interface confirming zero volume failures |
| `screenshots/13-resourcemanager-ui-job.png` | ResourceManager web interface showing SUCCEEDED MapReduce job |
| `screenshots/13b-resourcemanager-ui-job-detail.png` | ResourceManager web interface showing detailed task breakdown |
| `screenshots/14-hdfs-raw-ls.txt` | HDFS listing of raw flight data partitioned by `year=2009` and `year=2010` |
| `screenshots/15-hdfs-raw-du.txt` | HDFS disk usage of raw flight data (1.5 GB raw, 3.0 GB replicated) |
| `screenshots/16-hdfs-raw-fsck.txt` | HDFS fsck report confirming 24 blocks of raw data replicated across both DataNodes |
| `screenshots/17-hdfs-report-after-ingest.txt` | HDFS report showing balanced storage across both DataNodes after raw ingestion |
| `screenshots/18-clean-job-2009.log` | MapReduce streaming job log for cleaning 2009 flight dataset |
| `screenshots/18-clean-job-2010.log` | MapReduce streaming job log for cleaning 2010 flight dataset |
| `screenshots/19-hdfs-cleaned-du.txt` | HDFS disk usage of cleaned flight data (947.6 MB cleaned, 1.9 GB replicated) |
| `screenshots/20-cleaned-sample.txt` | 10-line sample of cleaned 23-column CSV records on HDFS |
| `screenshots/21-cleaning-summary.txt` | Data cleaning validation summary verifying record counts and column structure |
| `screenshots/24-hive-install.txt` | Log confirming Hive 3.1.3 installation and Derby metastore initialization |
| `screenshots/25-hive-tables-and-partitions.txt` | Hive CLI output listing created tables and registered year partitions |
| `screenshots/26-hive-partition-rowcounts.txt` | Reference row counts by year in Hive (6,414,015 in 2009; 6,434,643 in 2010) |
| `screenshots/27-yarn-applications-hive.txt` | YARN application list after initial Hive analytics queries |
| `screenshots/28-yarn-nodes-after-hive.txt` | YARN node status confirming both NodeManagers healthy after Hive analytics |
| `screenshots/29-resourcemanager-ui-hive-jobs.png` | ResourceManager UI displaying completed Hive MapReduce jobs |
| `screenshots/30-namenode-ui-browse-cleaned.png` | NameNode UI browsing HDFS directory `/flights/cleaned` |
| `screenshots/31-yarn-applications-phase6.txt` | YARN application list after time, route, cancellation, and weather Hive queries |
| `screenshots/32-yarn-nodes-phase6.txt` | YARN node list confirming healthy NodeManagers after Phase 6 queries |
| `screenshots/33-resourcemanager-ui-phase6-jobs.png` | ResourceManager UI showing completed Phase 6 Hive analytics jobs |
| `screenshots/35-mr-carrier-month-delay-job.log` | Complete execution log of custom Java MapReduce job (`CarrierMonthDelay`) |
| `screenshots/36-mr-output-hdfs-ls.txt` | HDFS listing of `/flights/mr_output` showing output part file |
| `screenshots/37-mr-counters-summary.txt` | Custom MapReduce counters summary (records read, operated, delayed, cancelled) |
| `screenshots/38-mr-vs-hive-crosscheck.txt` | Exact cross-check verification confirming 0 differences between MapReduce and Hive |
| `screenshots/39-yarn-applications-mr.txt` | YARN application list showing finished `carrier-month-delay` MapReduce job |
| `screenshots/40-yarn-nodes-mr.txt` | YARN node status following MapReduce execution |
| `screenshots/41-mr-container-nodes.txt` | YARN container assignment proving mappers and reducers ran across both workers |
| `screenshots/42-resourcemanager-ui-mr-job.png` | ResourceManager UI displaying custom Java MapReduce application |
| `screenshots/43-namenode-ui-mr-output.png` | NameNode UI browsing `/flights/mr_output` |
| `screenshots/44-hdfs-model-tables-du.txt` | HDFS disk usage for `flights_split` (337.2 MB, 674.5 MB replicated) |
| `screenshots/45-hdfs-flights-split-fsck.txt` | HDFS fsck report confirming `flights_split` is HEALTHY across both DataNodes |
| `screenshots/46-yarn-applications-phase8.txt` | YARN application list showing model building MapReduce jobs |
| `screenshots/47-yarn-nodes-phase8.txt` | YARN node list following model table build |
| `screenshots/50-hdfs-flights-scored-du.txt` | HDFS disk usage for `flights_scored` (263.3 MB, 526.7 MB replicated) |
| `screenshots/50b-hdfs-flights-scored-fsck.txt` | HDFS fsck report confirming `flights_scored` 4 blocks replicated across both DataNodes |
| `screenshots/51-yarn-applications-phase9.txt` | YARN application list showing scoring join and evaluation query jobs |
| `screenshots/52-yarn-nodes-phase9.txt` | YARN node list following scoring evaluation |
| `screenshots/53-predict-flight-demo.txt` | Output transcript of the 3 single-flight demo predictions |
| `screenshots/final/before-restart/` | Verification proofs before restart (containers, HDFS, YARN, jps, fsck, Hive) |
| `screenshots/final/after-restart/` | Verification proofs after cluster restart confirming persistence and reproducibility |
| `screenshots/final/yarn-applications-tail.txt` | YARN applications tail proof confirming distributed MapReduce execution |
