#!/bin/bash

proc_table() {

#db instance
mysql="/data/app/bimax/flow.sh run db${1}_ mysql pw$1 -N -s -A"

tmp=`mktemp`
echo "show tables like 'piwik_archive_${3}_2%'" | $mysql | while read arc_table; do
	#tmp_dump="$tmp_dump $arc_table"
	#cat $2 | awk -v tab=$arc_table 'BEGIN {print "update " $tab " set idsite=" $3 " where idsite="$1";"}'
	while read -r line; do
		tf=`echo $line | awk '{print $3}'`
		tt=`echo $line | awk '{print $1}'`
		echo "update $arc_table set idsite=$tt where idsite=$tf;" >> $tmp
	done < $2 
done

cat $tmp
$mysql < $tmp

rm -f $tmp
}


flow=/data/app/bimax/flow.sh
tran=$2

#list numeric archive
proc_table $@ numeric
proc_table $@ blob


