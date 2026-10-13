#!/bin/bash
set -e
source /opt/hive-data/hive-env.sh
# Hive 3.1.3 ships guava-19, which breaks on Hadoop 3.2.1 (NoSuchMethodError).
# Replace it with the guava jar Hadoop itself uses.
if ls $HIVE_HOME/lib/guava-19*.jar >/dev/null 2>&1; then
  rm -f $HIVE_HOME/lib/guava-19*.jar
  cp $(ls $HADOOP_HOME/share/hadoop/hdfs/lib/guava-*.jar | head -n 1) $HIVE_HOME/lib/
fi
# Initialise the embedded Derby metastore once
if [ ! -d /opt/hive-data/metastore_db ]; then
  schematool -dbType derby -initSchema
fi
hdfs dfs -mkdir -p /user/hive/warehouse /tmp/hive /flights/reference/carriers
hdfs dfs -chmod -R 777 /user/hive/warehouse /tmp/hive
