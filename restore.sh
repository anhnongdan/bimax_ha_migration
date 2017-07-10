#!/bin/bash
snum=3
inum=6

xtrabackup=`which xtrabackup` >> /dev/null
#xtrabackup=`which mysql` >> /dev/null

# need to map backup folder to docker db
target=/data/bimax/pw$snum/db/backup #match this to whatever
datadir=/data/bimax/pw$inum/db/data
#datadir=/var/lib/mysql
log=/data/bimax/pw$inum/db/log/restore.log

st=`date +"%Y-%m-%d %H:%M:%S"`
echo "Restore start at: $st" >> $log

if [ ! -z "$xtrabackup" -a "$xtrabackup" != "" ]; then
	echo "xtrabackup is installed" >> $log 
else 
	yum install percona-xtrabackup-24 || exit 1
fi


##check disk available volume
free=`df | grep -w "/mnt/data" | grep -v "/mnt/data/" | awk '{print $4}'`
# check datadir size, for full backup only
backup=`du -s "$target" | awk '{print $1}'`

if [ $free -lt $backup ]; then
        echo "not enought space for backup" >> $log
	exit 2
fi

#Prepare backup only before restoring, will be more complex with incremental backup
$xtrabackup --prepare --target-dir=$target >> $log

if [ ! -z $?  ]; then
did=`docker ps |grep db$inum | head -1 | awk '{print $1}'`
## check archive??
# check mysql
DbP=`docker ps | grep db$inum | awk -F" " '{print $7}'`
if [ "$DbP" = 'Up' ]; then
	#will not use mysql stop for docker, stop the container instead
	#echo "service mysql stop"
	docker stop $did
fi

	#don't know why "rm -rf $datadir/*" doesn't work here, still left smt in the folder... 
	rm -rf $datadir
	mkdir -p $datadir
	
	#echo "$xtrabackup --innodb-log-file-size=50331648 --copy-back -H -P -u -p  --datadir=$datadir --target-dir=$target"
	$xtrabackup --copy-back --datadir=$datadir --target-dir=$target >> $log 
	chown -R 106:108 $datadir/*
	docker start $did

else
	echo "Prepare backup failed" >> $log
	exit 3
fi
comp=`date +"%Y-%m-%d %H:%M:%S"`
echo "Restore end at: $comp (started at $st)" >> $log






