#!/bin/sh
MYDIR="$(dirname "$(realpath "$0")")"
conf=$MYDIR/backup.conf
log=`awk -F'=' '/log=/ {print $2}' $conf | head -1`
host=`awk -F'=' '/backup_host=/ {print $2}' $conf | head -1`
port=`awk -F'=' '/backup_port=/ {print $2}' $conf | head -1`
bk_dir=`awk -F'=' '/backup_dir=/ {print $2}' $conf | head -1`
exclude=`awk -F'=' '/exclude=/ {print $2}' $conf | head -1`
lc_dir=`awk -F'=' '/local_backup=/ {print $2}' $conf | head -1`

#get docker id
ids="`docker ps | awk '/bimax_pw/ {l=$NF;sub(/^bimax_pw/,"",l);sub(/_.*$/,"",l);print(l)}'`"
if [ -f $exclude ]; then excludes=`cat $exclude`; fi

for id in $ids;do
	#backup excludes hosts just like flow.sh
	if [[ $excludes =~ (^|[[:space:]])$id($|[[:space:]]) ]]; then
                        echo "skip backup $id" >> $log
                        continue
        fi

	local_bk_dir=$lc_dir/pw$id
	
	if [ -d $local_bk_dir ]; then
		mv $local_bk_dir ${local_bk_dir}__
	fi
	sh $MYDIR/backup_host.sh $id >> $log
	if [ ! -z $?  ]; then
		#just to make sure, if backup_host success the dir should be there
		if [ -d $local_bk_dir ]; then
                	rm -rf ${local_bk_dir}__
			#rsync -avzh -e 'ssh -i /root/.ssh/id_rsa.pub' --progress $bk_dir/ root@172.20.4.64:/data/backup/pw$id >> $log
			/usr/bin/rsync -avzh -e "/usr/bin/ssh -p $port" $local_bk_dir/ root@$host:$bk_dir/pw$id >> $log 2>&1
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup success for $id " >> $log
        	else
			mv ${local_bk_dir}__ ${local_bk_dir}
			echo "`date +"%Y-%m-%d %H:%M:%S"`: backup failed for $id, returned the backup folder." >> $log
		fi
	fi
done


