#!/bin/bash
#

today=$($(which date) "+%Y%m%d")
ip_file=/ROOT/conf/nginx/static/data/${today}.ip
scripts=/ROOT/sh/svn/panda/nagiosauto/functions/host_add.sh

if [ -f $ip_file ];then
	sh $scripts
fi
