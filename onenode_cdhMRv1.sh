#!/bin/bash

cdhrelease=${1:-4.5.0}
major=$(echo $cdhrelease | /bin/cut -d"." -f1)

# Declare array for the node roles
declare -a noderoles=(hdfs-namenode hdfs-secondarynamenode hdfs-datanode 0.20-mapreduce-jobtracker 0.20-mapreduce-tasktracker 0.20-conf-pseudo)

namedir="/var/lib/hadoop-hdfs/cache/hdfs/dfs/name"

##### 1. Set the CDH repo and import the GPG Key
/bin/cat > /etc/yum.repos.d/cloudera.repo <<EOF
[cloudera-cdh${cdhrelease}]
# Packages for Cloudera's Distribution for Hadoop, Version 4, on RedHat	or CentOS 6 x86_64
name=Cloudera's Distribution for Hadoop, Version 4
baseurl=http://archive.cloudera.com/cdh${major}/redhat/6/x86_64/cdh/${cdhrelease}/
gpgkey = http://archive.cloudera.com/cdh${major}/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera    
gpgcheck = 1
EOF

/bin/rpm --import http://archive.cloudera.com/cdh${major}/redhat/6/x86_64/cdh/RPM-GPG-KEY-cloudera

##### 2. Install the hadoop packages.
for role in ${noderoles[@]}
do
	yum -y install hadoop-${role}
done

#### 3. format HDFS

	if [  "$(ls -A ${namedir} 2>/dev/null )" == "" ] ; then
		#echo "I am here"
		/usr/bin/yes Y | /usr/bin/sudo -u hdfs /usr/bin/hadoop namenode -format 
	fi

##### 4.  Start HDFS 
for service in `cd /etc/init.d/ ; ls hadoop-hdfs-*`
do
	service $service restart
done

### HDFS set-up is done.

#### MRv1 setup follows

##### 5. Create /tmp and other directories in HDFS
	/usr/bin/sudo -u hdfs hadoop fs -mkdir /tmp
	/usr/bin/sudo -u hdfs hadoop fs -chmod -R 1777 /tmp

	/usr/bin/sudo -u hdfs hadoop fs -mkdir -p /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
	/usr/bin/sudo -u hdfs hadoop fs -chmod 1777 /var/lib/hadoop-hdfs/cache/mapred/mapred/staging
	/usr/bin/sudo -u hdfs hadoop fs -chown -R mapred /var/lib/hadoop-hdfs/cache/mapred

	/usr/bin/sudo -u hdfs hadoop fs -mkdir -p /user
	/usr/bin/sudo -u hdfs hadoop fs -mkdir -p /user/root
	/usr/bin/sudo -u hdfs hadoop fs -chown -R root /user/root
	
##### 6. Start MRv1

for service in `cd /etc/init.d/ ; ls hadoop-0.20-mapreduce-*`
do
	service $service restart
done
