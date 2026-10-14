#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
docker exec namenode bash -c "rm -rf /tmp/mrbuild && mkdir -p /tmp/mrbuild/classes"
docker cp "$ROOT/src/processing/mapreduce/CarrierMonthDelay.java" namenode:/tmp/mrbuild/CarrierMonthDelay.java
docker exec namenode bash -c 'cd /tmp/mrbuild && javac -classpath "$(hadoop classpath)" -d classes CarrierMonthDelay.java && jar cf carrier-month-delay.jar -C classes . && ls -l carrier-month-delay.jar && jar tf carrier-month-delay.jar'
echo "Build complete."
