#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration
sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml


service sshd start
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
$HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh start historyserver

# install Tez
export PATH=$HADOOP_PREFIX/sbin:$HADOOP_PREFIX/bin:$PATH
hdfs dfsadmin -safemode wait
hadoop fs -mkdir -p /apps/tez
hadoop fs -copyFromLocal /root/tez/apache-tez-0.8.5-bin/share/tez.tar.gz /apps/apache-tez-0.8.5-bin.tar.gz
export TEZ_CONF_DIR=/usr/local/hadoop/etc/hadoop/
export TEZ_JARS=/root/tez/apache-tez-0.8.5-bin
export HADOOP_CLASSPATH=${TEZ_CONF_DIR}:${TEZ_JARS}/*:${TEZ_JARS}/lib/*

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
