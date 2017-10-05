#!/bin/bash

#first param: splitter or monitor (should be ok with extractor as well)
proc_name=$1

MYDIR="$(dirname "$(realpath "$0")")"
conf=$MYDIR/ha.conf
log=`awk -F'=' '/log=/ {print $2}' $conf | head -1`
master=`awk -F'=' "/master_${proc_name}=/ {print \\$2}" $conf | head -1`
proc_dir=`awk -F'=' "/${proc_name}_dir=/ {print \\$2}" $conf | head -1`
master_dir=`awk -F'=' "/master_${proc_name}_dir=/ {print \\$2}" $conf | head -1`
csync_setting=`awk -F'=' '/csync_setting=/ {print $2}' $conf | head -1`
fail_count=`awk -F'=' '/fail_count=/ {print $2}' $conf | head -1`

start_proc() {
		procs=`ls ${proc_dir} | grep $proc_name | grep -v conf`
		for proc in $procs; do
			echo "start ${proc_dir}/$proc"  >> $log
			#/usr/bin/pm2 start ${proc_dir}/$proc >> $log
		done
}

#while true;do

	# it is better to detect master host down by ping
	ping_fail=0
	csync=0
	while [ $ping_fail -lt 3 ]; do
		ping -c 3 $master > /dev/null 2>&1 || ping_fail=`echo "$ping_fail + 1" | bc`
		sleep 3
		csync=`echo "$csync + 1" |bc`
		if [ $csync -eq $csync_setting ]; then
			/usr/bin/rsync -avzh -e '/usr/bin/ssh -o ConnectTimeout=10 -i /root/.ssh/id_rsa -p 22' root@$master:$master_dir/ $proc_dir --delete >> $log
			csync=0
		fi

		# for the case pm2 process on master host is down
		pm2s=`ssh -o ConnectTimeout=10  -i /root/.ssh/id_rsa -t root@$master "pm2 l | grep ${proc_name} | grep online" | wc -l `
		if [ \( $? -ne 0 \) -o  \( $pm2s -lt 1 \) ]; then		
			echo "`date` pm2 down on master" >> $log
			#check pm2 3 time as well
			ping_fail=`echo "$ping_fail + 1" | bc`
		else
			echo "`date` it seems master process is running normally" >> $log
		fi			 
	done
	
	#after start backup extractors, this program exits normally
	#master host needs to be checked afterward
	start_proc
	exit 0	

	#sync config and extractor scripts between master and slave
	#this is crucial for backup system to work
	#/usr/bin/rsync -avzh -e '/usr/bin/ssh -p 22' root@$master:$master_extr_dir/ $extr_dir --delete
	
	#if [ $? -eq 0 ]; then
	#else
		#echo "master down"
		#start_extractors
	#fi

#done

