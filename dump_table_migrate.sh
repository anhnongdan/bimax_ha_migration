#!/bin/bash

proc_table() {

#db instance
mysql="/data/app/bimax/flow.sh run db${1}_ mysql pw$1 -N -s -A"

#use run here might cause mysqldump exit after dumping the first tale
mysqldump="/data/app/bimax/flow.sh run db${1}_ mysqldump --result-file=/app/archive_dump.sql pw$1"

tmp=`mktemp`
tmp_dump=`mktemp`
echo -n "$mysqldump" >> $tmp_dump
echo "show tables like 'piwik_archive_${3}_2%'" | $mysql | while read arc_table; do
	echo $arc_table
	#echo "$mysqldump $arc_table --result-file=/app/dumped_sql/pw${1}_${arc_table}.sql" >> $tmp_dump
	echo -n " $arc_table" >> $tmp_dump
	#tmp_dump="$tmp_dump $arc_table"
	#cat $2 | awk -v tab=$arc_table 'BEGIN {print "update " $tab " set idsite=" $3 " where idsite="$1";"}'
	while read -r line; do
		tf=`echo $line | awk '{print $1}'`
		tt=`echo $line | awk '{print $3}'`
		echo "update $arc_table set idsite=$tt where idsite=$tf;" >> $tmp
	done < $2 
done

cat $tmp
$mysql < $tmp

#while read -r cmm; do
#	echo $cmm
#	#$cmm
#done < $tmp_dump

cat $tmp_dump | sh
#$tmp_dump >> /dev/null

#$mysqldump < $tmp_dump
rm -f $tmp
rm -f $tmp_dump
}


flow=/data/app/bimax/flow.sh
tran=$2

#list numeric archive
proc_table $@ numeric
proc_table $@ blob

mv /data/bimax/pw${1}/db/app/archive_dump.sql $PWD/pw${1}_archive_dump.sql

