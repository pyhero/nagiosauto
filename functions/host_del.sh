#!/bin/bash
#
# Author: Xu Panda
# Update: 2016-05-11
#
# Changelog
#

DIR=$(cd `dirname $0`;echo $PWD)
## source global variables.
funcs="$DIR/xscripts/functions"
if [ ! -f $funcs ];then
	echo -e "\e[32m$funs\e[0m: not exist."
	exit 6
else
	source $funcs
fi

help () {
	echo -e "Usage:\e[32m$0 {ip address | ip file }\e[0m"
	exit 1
}

## if host from $1 or from file
ip_="" && ip_file=""
if [ $# -gt 0 ];then
	ip_=$1
else
	help
fi

host_store () {
	succeed_list=$history_dir/list_del.$today && touch $succeed_list
	if ! grep -q $host $succeed_list;then
		echo $host >> $succeed_list
	fi
}

clear_ip_file () {
	sed -i "/$host/d" $ip_file 2> /dev/null
	[ ! -s $ip_file ] && rm -rf $ip_file
}

clean_config () {
	# define ip source
	if [ ! -f $ip_ ];then
		ips=$ip_
	else
		ip_file=$ip_
		ips=$(cat $ip_file)
	fi
	newdo=0
	# doit
	for host in $ips;do
		## check if ip in idc private net.
		chkIpInNet

		## def ip belong to which idc.
		def_location

		conf_dir=$nagios_conf_configure_dir/conf/$location
		dir=$conf_dir && chkdir

		host_conf="$conf_dir/xhosts/${host}.cfg"
		# check if already exist.
		if [ ! -f $host_conf ];then
			echo -e "\e[31m!!! Did Nothing for \e[33m$host\e[0m"
			continue
		fi
		ip=$host
		# clean config file.
		backdir=$nagios_conf_configure_dir/xbakconf/$location/${today}
		mkdir -p $backdir
		rsync -qaz $host_conf $backdir/${host}.cfg
		$(which svn) del $host_conf --force > /dev/null
		## clean service file
		num=0
		for ser_conf in $(ls $conf_dir/xsers/*.cfg);do
			if grep -q $host $ser_conf;then
				rsync -qaz $ser_conf $backdir/${ser_conf##*/}.$num
				num=$[$num+1]
				sed -i "s/\!$host//g;s/$host//g;s/,,/,/" $ser_conf
			fi
		done
		host_store && clear_ip_file
		newdo=$[$newdo+1]
	done
}

doit () {
	clean_config
	if [ $newdo -gt 0 ];then
		update_conf
		sync_remote
	fi
}

doit
