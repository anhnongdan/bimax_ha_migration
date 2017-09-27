#!/bin/bash

# This should run on the host, not the docker instance as it need to check 
# disk and get db information from PW configuration file.

#For backup only scenario, datadir and target dir should be the same.
snum=$1
inum=$1

xtrabackup=`which xtrabackup` >> /dev/null
xmysql=`which mysql` >> /dev/null

# need to map backup folder to docker db
target=/data/bimax/pw$inum/db/backup #match this to whatever
datadir=/data/bimax/pw$snum/db/data
#datadir=/var/lib/mysql

conf=/data/bimax/pw$snum/www/src/config/config.ini.php

if [ ! -z "$xmysql" -a "$xmysql" != "" ]; then
	echo "mysql is installed in the host"
else 
	yum -y install mysql || exit 1
fi
if [ ! -z "$xtrabackup" -a "$xtrabackup" != "" ]; then
	echo "xtrabackup is installed"
else
	yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm 
	yum -y install percona-xtrabackup-24 || exit 1
fi

xtrabackup=`which xtrabackup` >> /dev/null

##check disk available volume
free=`df | grep -w "/" | grep -v "/mnt/data/" | awk '{print $4}'`
# check datadir size, for full backup only
backup=`du -s "$datadir" | awk '{print $1}'`

if [ $free -lt $backup ]; then
#if [ $free = 0 ]; then
	echo "not enought space for backup"
	exit 2
else
	#check free disk space of root dir
	hfree=`df -h --output='avail' / | grep -v 'Avai'`
	hbk=`du -sh $datadir | awk '{print $1}'`
	echo "OK, backup size est: $hbk and $hfree of disk is available"
	#check time and make full backup
	bktime=`date +"%Y-%m-%d %H:%M:%S"`
	echo "Start full backup at $bktime"
	#echo "$xtrabackup --backup --target-dir=$target"
	#echo "mysql -h 127.0.0.1 --db-port= -u  -p 

	user=`awk -F'=' '/username =/ {print $2}' $conf | tr -d \'\"`
	host=`awk -F'=' '/host =/ {print $2}' $conf | tr -d \'\"`
	pass=`awk -F'=' '/password =/ {print $2}' $conf | tr -d \'\"`
	port=`awk -F'=' '/port =/ {print $2}' $conf | grep 300 | tr -d \'\"`

	#opt_exclude="^pw\d[.]\w+_archive_(blob|numeric)_temp_\w+"
	opt_exclude="(_archive_(blob|numeric)_temp_|_log_link_visit_action_2)"
	#datadir path is the directory on romote server while target-dir is dir on this bk server 
	#so both target-dir and data-dir need to be the dirs on local host (or specify as host/path/file or smt
	$xtrabackup --tables-exclude=$opt_exclude --innodb-log-file-size=50331648 --backup -H $host -P $port -u $user -p $pass --datadir=$datadir --target-dir=$target 

	endtime=`date +"%Y-%m-%d %H:%M:%S"` 
	echo "Backup complete at: $endtime (start: $bktime)"
fi

