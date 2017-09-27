#!/bin/sh

#get docker id
ids="`docker ps | awk '/bimax_pw/ {l=$NF;sub(/^bimax_pw/,"",l);sub(/_.*$/,"",l);print(l)}'`"
log=/var/log/backup_pw_db.log
exclude=/data/app/bimax/exclude_host
if [ -f $exclude ]; then excludes=`cat $exclude`; fi

for id in $ids;do
	#backup excludes hosts just like flow.sh
	if [[ $excludes =~ (^|[[:space:]])$id($|[[:space:]]) ]]; then
                        echo "skip backup $id" >> $log
                        continue
        fi

	bk_dir=/data/bimax/pw$id/db/backup
	
	if [ -d $bk_dir ]; then
		mv $bk_dir ${bk_dir}__
	fi
	sh /root/bimax_ha_migration/backup_host.sh $id >> $log
	if [ ! -z $?  ]; then
		#just to make sure, if backup_host success the dir should be there
		if [ -d $bk_dir ]; then
                	rm -rf ${bk_dir}__
			#rsync -avzh -e 'ssh -i /root/.ssh/id_rsa.pub' --progress $bk_dir/ root@172.20.4.64:/data/backup/pw$id >> $log
			/usr/bin/rsync -avzh -e '/usr/bin/ssh -p 22' $bk_dir/ root@172.40.4.91:/data/backup/pw$id >> $log 2>&1
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup success for $id " >> $log
        	else
			mv ${bk_dir}__ ${bk_dir}
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup failed for $id, returned the backup folder." >> $log
		fi
	fi
done


