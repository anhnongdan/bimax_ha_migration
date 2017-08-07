#!/bin/sh

#get docker id
ids="`docker ps | awk '/bimax_pw/ {l=$NF;sub(/^bimax_pw/,"",l);sub(/_.*$/,"",l);print(l)}'`"
log=/var/log/backup_pw_db.log

for id in $ids;do
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
			usr/bin/rsync -avzh -e '/usr/bin/ssh -p 22' --progress $bk_dir/ root@172.20.4.64:/data/backup/pw$id
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup success for $id " >> $log
        	else
			mv ${bk_dir}__ ${bk_dir}
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup failed for $id, returned the backup folder." >> $log
		fi
	fi
done


