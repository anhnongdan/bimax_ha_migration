#!/bin/sh

/usr/bin/rsync -avzh -e '/usr/bin/ssh -p 22' --progress /root/bimax_ha_migration/test_rsync/ root@172.20.4.64:/root/test_rsync >> /tmp/rsync.log 2>&1
