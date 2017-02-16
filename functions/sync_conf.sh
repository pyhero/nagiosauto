#!/bin/bash


DIR=$(cd `dirname $0`;echo $PWD)
## source global variables.
funs="$DIR/xscripts/functions"
if [ ! -f $funs ];then
	echo -e "\e[32m$funs\e[0m: not exist."
	exit 6
else
	source $funs
fi

sync_remote
