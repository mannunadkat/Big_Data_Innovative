#!/bin/bash
export HADOOP_HOME=/opt/hadoop-3.2.1
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/etc/hadoop}
export HIVE_HOME=/opt/hive-data/apache-hive-3.1.3-bin
export HIVE_CONF_DIR=/opt/hive-data/conf
export HADOOP_OPTS="$HADOOP_OPTS -Dderby.stream.error.file=/tmp/derby.log"
export HADOOP_CLIENT_OPTS="-Xmx1g $HADOOP_CLIENT_OPTS"
export PATH=$HIVE_HOME/bin:$HADOOP_HOME/bin:$PATH
