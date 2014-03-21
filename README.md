# Yak shaving an elefant

You want to try out hadoop 2.3? Go to the zoo and [shave a yak](http://sethgodin.typepad.com/seths_blog/2005/03/dont_shave_that.html).
Or simply just use [docker](https://www.docker.io/).

```
docker run -i -t sequenceiq/hadoop-docker /usr/local/hadoop/bootstrap.sh -bash
```

## Testing

You can run one of the stock examples:

``` bash
# run the mapreduce
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.3.0.jar grep input output 'dfs[a-z.]+'

# check the output
bin/hdfs dfs -cat output/*
```



## too long didn't read
I had problems installing hadoop 2.3 and by googling i stumbled upon this [email thread](http://mail-archives.apache.org/mod_mbox/hadoop-mapreduce-user/201403.mbox/%3C53192FD4.2040003@oss.nttdata.co.jp%3E),
which references an [alternative hadoop docs](http://aajisaka.github.io/hadoop-project/hadoop-project-dist/hadoop-common/SingleCluster.html#Standalone_Operation) deployed on github.

By following that description i run into an other issue:
hadoop is delivered with 32 bit native libraries. No big deal ...

## Hadoop native libraries

Of course there is an official [Native Libraries Guide](http://hadoop.apache.org/docs/r2.3.0/hadoop-project-dist/hadoop-common/NativeLibraries.html) it instructs you
to simple download the sources and `mvn package`. But than you face a new issue: missing `protobuf`. Eeeasy ...

## Protobuf 2.5

Unfortunately `yum install protobuf` installs an older 2.3 version, which is close but no cigar.
 So you download protobuf source, and `./configure && make && make install`

To succeed on that one you have to install a couple of development packages, and there you go.

## Bintray

I wanted to save you those steps so created a binary distro of the native libs
compiled with 64 bit CentOS. So I created [Bintray r̨epo](https://bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64bit/2.3.0/view/files). Enjoy

## Automate everything

As I'm an automation fetishist, a Docker file was created, and released in the official [docker repo](https://index.docker.io/u/sequenceiq/hadoop-docker/)
