#!/bin/bash

# This should run on the host, not the docker instance as it need to check 
# disk and get db information from PW configuration file.

#For backup only scenario, datadir and target dir should be the same.
snum=3
inum=3

xtrabackup=`which xtrabackup` >> /dev/null
#xtrabackup=`which mysql` >> /dev/null

# need to map backup folder to docker db
target=/data/bimax/pw$inum/db/backup #match this to whatever
datadir=/data/bimax/pw$snum/db/data
#datadir=/var/lib/mysql


if [ ! -z "$xtrabackup" -a "$xtrabackup" != "" ]; then
	echo "xtrabackup is installed"
else 
	yum install percona-xtrabackup-24 || exit 1
fi


##check disk available volume
free=`df | grep -w "/mnt/data" | grep -v "/mnt/data/" | awk '{print $4}'`
# check datadir size, for full backup only
backup=`du -s "$datadir" | awk '{print $1}'`

if [ $free -lt $backup ]; then
	echo "not enought space for backup"
	exit 2
else
	hfree=`df -h | grep -w "/mnt/data" | grep -v "/mnt/data/" | awk '{print $4}'`
	hbk=`du -sh /mnt/data/bimax/pw3/db/data | awk '{print $1}'`
	echo "OK, backup size est: $hbk and $hfree of disk is available"
	#check time and make full backup
	bktime=`date +"%Y-%m-%d %H:%M:%S"`
	echo "Start full backup at $bktime"
	#echo "$xtrabackup --backup --target-dir=$target"
	#echo "mysql -h 127.0.0.1 --db-port= -u  -p 

	#datadir path is the directory on romote server while target-dir is dir on this bk server 
	#so both target-dir and data-dir need to be the dirs on local host (or specify as host/path/file or smt
	$xtrabackup --innodb-log-file-size=50331648 --backup -H __host__ -P __port__ -u __user__ -p __pas__ --datadir=$datadir --target-dir=$target 

	endtime=`date +"%Y-%m-%d %H:%M:%S"` 
	echo "Backup complete at: $endtime (start: $bktime)"
fi

