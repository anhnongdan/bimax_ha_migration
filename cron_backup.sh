#!/bin/sh

#get docker id
ids="`docker ps | awk '/bimax_pw/ {l=$NF;sub(/^bimax_pw/,"",l);sub(/_.*$/,"",l);print(l)}'`"
log=/var/log/backup_pw_db.log

for id in $ids;do
	bk_dir=/data/bimax/pw$id/db/backup/
	if [ -d /data/backup/pw$id ]; then
		mv /data/backup/pw$id /data/backup/_pw$id
	fi
	$PWD/backup_host.sh $id >> $log
	if [ ! -z $?  ]; then
		#just to make sure, if backup_host success the dir should be there
		if [ -d /data/backup/pw$id ]; then
                	rm -rf /data/backup/_pw$id
			rsync -avz -e 'ssh -p 10022' --progress $bk_dir root@172.16.64.180:/data/backup/pw$id
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup success for $id " >> $log
        	else
			mv /data/backup/_pw$id /data/backup/pw$id
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup failed for $id, returned the backup folder." >> $log
		fi
	fi
done


