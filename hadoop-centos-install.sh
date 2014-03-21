#!/bin/bash

#Install script for Hadoop 2.3 on CentOS 6.5.3/x86_64

#run as root (sudo su -)

# install packages
yum install -y curl which tar sudo openssh-server openssh-clients rsync

# passwordless ssh
ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
service sshd start

# install java
curl -LO 'http://download.oracle.com/otn-pub/java/jdk/7u51-b13/jdk-7u51-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
rpm -i jdk-7u51-linux-x64.rpm
rm jdk-7u51-linux-x64.rpm
export JAVA_HOME=/usr/java/default
export PATH=$PATH:$JAVA_HOME/bin:/usr/local/bin

# install hadoop
curl -s http://www.eu.apache.org/dist/hadoop/common/hadoop-2.3.0/hadoop-2.3.0.tar.gz | tar -xz -C /usr/local/
cd /usr/local && ln -s hadoop-2.3.0 hadoop

export HADOOP_PREFIX=/usr/local/hadoop
sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
. $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
. $HADOOP_PREFIX/etc/hadoop/yarn-env.sh

mkdir $HADOOP_PREFIX/input
cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# Standalone Operation
# testing with mapred sample
#bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.3.0.jar grep input output 'dfs[a-z.]+'

# pseudo distributed
cat > $HADOOP_PREFIX/etc/hadoop/core-site.xml<<EOF
  <configuration>
      <property>
          <name>fs.defaultFS</name>
          <value>hdfs://localhost:9000</value>
      </property>
  </configuration>
EOF

cat > $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml<<EOF
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

cat > $HADOOP_PREFIX/etc/hadoop/mapred-site.xml<<EOF
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
EOF

cat > $HADOOP_PREFIX/etc/hadoop/yarn-site.xml<<EOF
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
EOF

#set the hostname - fix vagrant issue
ping $HOSTNAME -c 1 -W 1 || echo "127.0.0.1 $HOSTNAME" >>/etc/hosts

# format HDFS namenode
$HADOOP_PREFIX/bin/hdfs namenode -format

#build hadoop dependencies function - devtools, maven, protobuf
build-hadoop-dependencies() {
  # fixing the libhadoop.so issue the hard way ...
  # do it if you have a couple of spare videos to watch
  yum groupinstall "Development Tools" -y
  yum install -y cmake zlib-devel openssl-devel

  # maven
  curl http://www.eu.apache.org/dist/maven/maven-3/3.2.1/binaries/apache-maven-3.2.1-bin.tar.gz|tar xz  -C /usr/share
  export M2_HOME=/usr/share/apache-maven-3.2.1
  export PATH=$PATH:$M2_HOME/bin

  # ohhh btw you need protobuf - released rpm is 2.3, we need 2.5 thus we need to build, will take a while, go get a coffee
  curl https://protobuf.googlecode.com/files/protobuf-2.5.0.tar.bz2|bunzip2|tar -x -C /tmp
  cd /tmp/protobuf-2.5.0
  ./configure && make && make install
  export LD_LIBRARY_PATH=/usr/local/lib
  export LD_RUN_PATH=/usr/local/lib
}

#we have released the native libs on bintray (the official release is 32 bit), use that instead of building
build-native-hadoop-libs() {
  #coffee time again - this will take quite a long time

  #build hadoop dependencies
  build-hadoop-dependencies

  # hadoop
  curl http://www.eu.apache.org/dist/hadoop/common/hadoop-2.3.0/hadoop-2.3.0-src.tar.gz|tar xz -C /tmp
  cd /tmp/hadoop-2.3.0-src/
  mvn package -Pdist,native -DskipTests -Dtar -DskipTests

  rm -rf /usr/local/hadoop/lib/native/*
  cp -d /tmp/hadoop-2.3.0-src/hadoop-dist/target/hadoop-2.3.0/lib/native/* /usr/local/hadoop/lib/native/
}

# fixing the libhadoop.so - we have built a 64bit distro for Hadoop native libs
use-native-hadoop-libs() {
  rm -rf /usr/local/hadoop/lib/native/*
  curl -Ls http://dl.bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64.tar|tar -x -C /usr/local/hadoop/lib/native/
}

#use native libs - in case you'd like to build Hadoop use build-native-hadoop-libs instead
use-native-hadoop-libs

####################
# testing mapreduce
####################
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
$HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
$HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input
$HADOOP_PREFIX/bin/hadoop jar $HADOOP_PREFIX/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.3.0.jar grep input output 'dfs[a-z.]+'
$HADOOP_PREFIX/bin/hdfs dfs -cat output/*





#pull out ports 50070 and 8088 (namenode and resource manager) for your convenience.
#enter SSH command mode
#~C
#-L 8088:127.0.0.1 8088


:<<EOF
# restart

service sshd start
. /usr/local/hadoop/etc/hadoop/hadoop-env.sh
cd $HADOOP_HOME
sbin/start-dfs.sh
sbin/start-yarn.sh

EOF
