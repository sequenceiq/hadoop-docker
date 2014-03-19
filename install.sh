#!/bin/bash

# install packages
yum install -y curl which tar sudo openssh-server openssh-clients rsync

# passwordless ssh
ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
service sshd start

# java
curl -LO 'http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
rpm -i jdk-7u51-linux-x64.rpm
rm jdk-7u51-linux-x64.rpm
export JAVA_HOME=/usr/java/default
export PATH=$PATH:$JAVA_HOME/bin

# hadoop
curl -s http://www.eu.apache.org/dist/hadoop/common/hadoop-2.3.0/hadoop-2.3.0.tar.gz | tar -xz -C /usr/local/
cd /usr/local && ln -s hadoop-2.3.0 hadoop

export HADOOP_PREFIX=/usr/local/hadoop
sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' etc/hadoop/hadoop-env.sh
sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' etc/hadoop/hadoop-env.sh
. ./etc/hadoop/hadoop-env.sh

mkdir input
cp etc/hadoop/*.xml input

# Standalone Operation
# testing with mapred sample
#bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.3.0.jar grep input output 'dfs[a-z.]+'

# pseudo distributed
cat > etc/hadoop/core-site.xml<<EOF
  <configuration>
      <property>
          <name>fs.defaultFS</name>
          <value>hdfs://localhost:9000</value>
      </property>
  </configuration>
EOF

cat > etc/hadoop/hdfs-site.xml<<EOF
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

bin/hdfs namenode -format

build-native-libs() {
  # fixing the libhadoop.so issue the hard way ...
  # do it if you have a couple of spare videos to watch
  yum groupinstall "Development Tools" -y
  yum install -y cmake zlib-devel openssl-devel

  curl http://www.eu.apache.org/dist/maven/maven-3/3.2.1/binaries/apache-maven-3.2.1-bin.tar.gz|tar xz  -C /usr/share
  export M2_HOME=/usr/share/apache-maven-3.2.1
  export PATH=$PATH:$M2_HOME/bin

  # ohhh btw you need protobuf
  curl https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.bz2|bunzip2|tar -x -C /tmp
  cd /tmp/protobuf-2.5.0.tar
  ./configure && make && make instal
  export LD_LIBRARY_PATH=/usr/local/lib
  export LD_RUN_PATH=/usr/local/lib

  curl http://www.eu.apache.org/dist/hadoop/common/hadoop-2.3.0/hadoop-2.3.0-src.tar.gz|tar xz -C /tmp
  cd /tmp/hadoop-2.3.0-src/
  mvn package -Pdist,native -DskipTests -Dtar -DskipTests

  rm  /usr/local/hadoop/lib/native/*
  cp -d /tmp/hadoop-2.3.0-src/hadoop-dist/target/hadoop-2.3.0/lib/native/* /usr/local/hadoop/lib/native/
}

# fixing the libhadoop.so like a boss
rm  /usr/local/hadoop/lib/native/*
curl -Ls http://dl.bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64.tar|tar -x -C /usr/local/hadoop/lib/native/

#######
# testing mapreduce
#######

bin/hdfs namenode -format
sbin/start-dfs.sh

bin/hdfs dfs -mkdir -p /user/root
bin/hdfs dfs -put etc/hadoop/ input

bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.3.0.jar grep input output 'dfs[a-z.]+'

bin/hdfs dfs -cat output/*


:<<EOF
# restart

service sshd start
. /usr/local/hadoop/etc/hadoop/hadoop-env.sh
cd $HADOOP_HOME
sbin/start-dfs.sh

EOF
