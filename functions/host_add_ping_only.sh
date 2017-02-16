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
	echo -e "\e[32m$funcs\e[0m: not exist."
	exit 6
else
	source $funcs
fi

help () {
	echo -e "Usage:\e[32m$0 [ip address]\e[0m"
	exit 1
}

## if host from $1 or from file
ip_add="" && ip_file=""
if [ $# -gt 0 ];then
	ip_add=$1
	ip_file=$1
else
	ip_file="/ROOT/conf/nginx/static/data/${today}.ip"
	if [ ! -f $ip_file ];then
		echo -e "\e[31m!!!\e[0m No \e[31mnew\e[0m server post infomation:($ip_file)"
		help
	fi
fi

host_store () {
	succeed_list=$history_dir/list_add.$today && touch $succeed_list
	if ! grep -q $host $succeed_list;then
		echo $host >> $succeed_list
	fi
}

clear_ip_file () {
	sed -i "/$host/d" $ip_file 2> /dev/null
	[ ! -s $ip_file ] && rm -rf $ip_file
}

create_config () {
	# define ip source
	if [ ! -z $ip_add ];then
		if [ -f $ip_add ];then
			ips=$(cat $ip_add)
		else
			ips=$ip_add
		fi
	else
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
		service_conf="$conf_dir/xsers/services.cfg"
		# check if already exist.
		if [ -f $host_conf ];then
			echo -e "\e[32m!!! $host\e[0m: Already exist & Did Nothing..."
			clear_ip_file
			continue
		#elif grep -qr $host $conf_dir/*;then
		#	echo "\e[31m${host}\e[0m.cfg not exist,but host already in some confie file."
		#	continue
		fi
		ip=$host && chkping
		if [ $continue_key == 1 ];then
			clear_ip_file
			continue
		fi
		# create config file.
		rsync -qaz $host_config_module $host_conf
		sed -i "s/127\.0\.0\.1/$host/" $host_conf
		sed -i "/CNC\.TJ/s/$/\!$host,/" $service_conf
		host_store && clear_ip_file
		$(which svn) add $host_conf > /dev/null
		title="! New Monitor:$host@$location FOR PING ONLY"
		body="FYI"
		source $scripts_dir/mail.sh
		newdo=$[$newdo+1]
	done
}

doit () {
	create_config
	notify_failed
	if [ $newdo -gt 0 ];then
		update_conf
		sync_remote
	fi
}

doit
