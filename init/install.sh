#!/bin/bash
#
# Author: Xu Panda
# Update: 2015-06-02

ROOT=$(cd `dirname $0`;echo $PWD)
SRC=$ROOT/src
CONF=$ROOT/conf
SCRIPT=$ROOT/script
WORK="/ROOT/server/nagios"

loip=$(ip a | grep inet | grep -v inet6 | grep -v "127\.0\.0\.1" | \
	egrep '(192\.168\.[0-9]*\.[0-9]*|10\.[0-9]*\.[0-9]*\.[0-9]*|172\.16\.[0-9]*\.[0-9]*)' | \
	awk '{print $2}' | awk -F '/' '{print $1}')

download () {
	# You need to temm me url=? & name=? first.
	#url=
	# Name is the software packet.
	#name=
	if [ ! -f $file ];then
	/usr/bin/wget -q $url -O $SRC/$name
	fi
}

check_dir () {
	# You need to tell me dir=? first.
	#dir=
	mkdir -p $dir
}

funs="nagios plugin nrpe pnp4nagios advance"

for fun in $funs;do
	sh $ROOT/$fun.sh
done

chown -R nagios.nagios $WORK
