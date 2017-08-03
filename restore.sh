#!/bin/bash

#this should be the same here
snum=$1
inum=$1

xtrabackup=`which xtrabackup` >> /dev/null
#xtrabackup=`which mysql` >> /dev/null

# need to map backup folder to docker db
datadir=/data/bimax/pw$snum/db/data

#target actually is the source 
target=/data/backup/pw$inum
#datadir=/var/lib/mysql
log=/data/bimax/pw$inum/db/log/restore.log

conf=/data/bimax/pw$snum/www/src/config/config.ini.php

echo "`date +"%Y-%m-%d %H:%M:%S"` Restore starting..." >> $log

if [ ! -z "$xtrabackup" -a "$xtrabackup" != "" ]; then
	echo "xtrabackup is installed" >> $log 
else 
	yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-4/percona-release-0.1-4.noarch.rpm
        yum -y install percona-xtrabackup-24 || exit 1
fi

xtrabackup=`which xtrabackup` >> /dev/null

##check disk available volume
free=`df | grep -w "/" | grep -v "/mnt/data/" | awk '{print $4}'`
# check datadir size, for full backup only
backup=`du -s "$target" | awk '{print $1}'`

if [ $free -lt $backup ]; then
        echo "not enought space for backup" >> $log
	exit 2
fi

#Prepare backup only before restoring, will be more complex with incremental backup
$xtrabackup --prepare --target-dir=$target >> $log

if [ ! -z $?  ]; then
	did=`docker ps |grep db${inum}_ | head -1 | awk '{print $1}'`
	## check archive??
	# check mysql
	DbP=`docker ps | grep db${inum}_ | awk -F" " '{print $7}'`
	if [ "$DbP" = 'Up' ]; then
		#will not use mysql stop for docker, stop the container instead
		#echo "service mysql stop"
		docker stop $did
	fi
	
	#don't know why "rm -rf $datadir/*" doesn't work here, still left smt in the folder... 
	rm -rf $datadir
	mkdir -p $datadir
	echo "`date +"%Y-%m-%d %H:%M:%S"` clearing database folder before backup" >> $log	
	
	#echo "$xtrabackup --innodb-log-file-size=50331648 --copy-back -H -P -u -p  --datadir=$datadir --target-dir=$target"
	$xtrabackup --copy-back --datadir=$datadir --target-dir=$target >> $log 
	chown -R 106:108 $datadir/*

	if [ "$DbP" = 'Up' ]; then
		docker start $did
	fi
else
	echo "Prepare backup failed" >> $log
	exit 3
fi

echo "`date +"%Y-%m-%d %H:%M:%S"` Restore end...." >> $log






