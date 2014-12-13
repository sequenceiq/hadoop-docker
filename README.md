#Apache Hadoop 2.6.0 Docker image

_Note: this is the master branch - for a particular Hadoop version always check the related branch_

A few weeks ago we released an Apache Hadoop 2.3 Docker image - this quickly become the most [popular](https://registry.hub.docker.com/search?q=hadoop&s=downloads) Hadoop image in the Docker [registry](https://registry.hub.docker.com/).


Following the success of our previous Hadoop Docker [images](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/), the feedback and feature requests we received aligned with the Hadoop release cycle, so we have released an Apache Hadoop 2.6.0 Docker image - same as the previous version, it's available as a trusted and automated build on the official Docker [registry](https://registry.hub.docker.com/).


_FYI: All the former Hadoop releases (2.3, 2.4.0, 2.4.1, 2.5.0, 2.5.1, 2.5.2, 2.6.0) are available in the GitHub branches or our [Docker Registry](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/) - check the tags._

# DockerContainerExecutor

This version of image is using the DockerContainerExecutor
http://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/DockerContainerExecutor.html


# Build the image

If you'd like to try directly from the Dockerfile you can build the image as:

```
docker build -t sequenceiq/hadoop-docker:2.6.0-dce .
```
# Pull the image

The image is also released as an official Docker image from Docker's automated build repository - you can always pull or refer the image when launching containers.

```
docker pull sequenceiq/hadoop-docker:2.6.0-dce
```

# Start a container

**Make sure that SELinux is disabled on the host. If you are using boot2docker you don't need to do anything.**

On host machine please create the directories and make sure that they are empty. These directories are used to share information between containers.

```
rm -rf /tmp/hadoop-root/nm-local-dir
mkdir -p /tmp/hadoop-root/nm-local-dir
rm -rf /usr/local/hadoop/logs/userlogs/
mkdir -p /usr/local/hadoop/logs/userlogs/
```

In order to use the Docker image you have just build or pulled use:
```
docker run -i -t -v /usr/local/bin/docker:/usr/local/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/hadoop-root/nm-local-dir:/tmp/hadoop-root/nm-local-dir -v /usr/local/hadoop/logs/userlogs:/usr/local/hadoop/logs/userlogs --net=host sequenceiq/hadoop-docker:2.6.0-dce /etc/bootstrap.sh -bash

```

## Testing

You can run one of the stock examples:

```
cd $HADOOP_PREFIX
# run the teragen with 2.6.0
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.0.jar teragen -Dmapreduce.map.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0" -Dyarn.app.mapreduce.am.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0" 1 /tmp/out

# run the grep with 2.6.0
cd $HADOOP_PREFIX
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.0.jar grep -Dmapreduce.map.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0" -Dmapreduce.reduce.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0" -Dyarn.app.mapreduce.am.env="yarn.nodemanager.docker-container-executor.image-name=sequenceiq/hadoop-docker:2.6.0" input output 'dfs[a-z.]+'

# check the output of grep
bin/hdfs dfs -cat output/*
```

## Hadoop native libraries, build, Bintray, etc

The Hadoop build process is no easy task - requires lots of libraries and their right version, protobuf, etc and takes some time - we have simplified all these, made the build and released a 64b version of Hadoop nativelibs on this [Bintray repo](https://bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64bit/2.6.0/view/files). Enjoy.

## Automate everything

As we have mentioned previousely, a Docker file was created and released in the official [Docker repository](https://registry.hub.docker.com/u/sequenceiq/hadoop-docker/)
