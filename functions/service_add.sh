#!/bin/bash
#
# Author: Panda
# Update: 20160615

DIR=$(cd `dirname $0`;echo $PWD)
## If add new group or new service.
server_file=$DIR/xscripts/xser-name.list
group_file=$DIR/xscripts/xser-group.list

printhelp () {
	echo -e "Usage: \e[36m$0\e[0m \
{\e[32mip_address\e[0m | \e[32mip_list_file\e[0m} \
{\e[32mSERVICE\e[0m} \
{\e[32mGROUP\e[0m} \
"
	echo -e "\e[32mSERVICE\e[0m:\n$(cat $server_file)"
	echo -e "\n\e[32mGROUP\e[0m:\n$(cat $group_file)"
	exit 2
}

[ $# -lt 3 ] && printhelp

## source global variables.
funcs="$DIR/xscripts/functions"
if [ ! -f $funcs ];then
	echo -e "\e[32m$funcs\e[0m: not exist."
	exit 6
else
	source $funcs
fi

## ip address from $1
ip_src=$1
if [ -f $ip_src ];then
	ips=$(cat $ip_src)
else
	ips=$ip_src
fi

## service from $2
service_name=$2
if ! grep -qw $service_name $server_file;then
	echo -e "!!!\nSERVICE:\e[31m$service_name\e[0m not in \e[32m$server_file\e[0m"
	echo -e "Becareful about \e[35mcase!\e[0m\n"
	printhelp
fi

## group from $3
group_name=$3
if ! grep -qw $group_name $group_file;then
	echo -e "!!!\nGROUP:\e[31m$group_name\e[0m not in \e[32m$group_file\e[0m"
	echo -e "If do not know GROUP name,then input: \e[35mNOC\e[0m as default.\n"
	printhelp
fi

service_description=${group_name}.${service_name}
group_description=${group_name}-${service_name}

newdo=0
num=0
host_succeed=""
host_failed=""
for host in $ips;do
	## check if ip in idc private net.
	chkIpInNet
	## def ip belong to which idc.
	def_location

	conf_dir=$nagios_conf_configure_dir/conf/$location
	dir=$conf_dir && chkdir

	global_dir=$nagios_conf_configure_dir/conf/xglobal
	global_service=$global_dir/services.cfg

	host_conf="$conf_dir/xhosts/${host}.cfg"
	if [ ! -f $host_conf ];then
		echo -e "\e[32m!!! $host\e[0m: not exist & Did Nothing..."
		host_failed[$num]=$host && num=$[$num+1]
		continue
	fi
	ip=$host && chkping
	[ $continue_key == 1 ] && continue

	service_conf="$conf_dir/xsers/services.cfg"
	group_conf="$conf_dir/xsers/hostgroup.cfg"

	gser_name="ser-$(echo $service_name|sed 's/[A-Z]/\l&/g')"
	if ! grep -qw $gser_name $global_service;then
		echo -e "\e[31;5m$gser_name\e[0m not defined \n@ \e[32m$global_service\e[0m"
		echo -e "\e[35mThe name mast be \e[33;5m$gser_name\e[0m"
		echo -e "\n\e[44;32;7mTree\e[0m:"
		echo -e "@ \e[32;4m$global_dir/\e[0m:"
		echo -e "\e[47;32;4mcommands.cfg\e[0m: define command!"
		echo "		^"
		echo "		|"
		echo "	       use"
		echo "		|"
		echo -e "@ \e[32;4m$global_dir/\e[0m:"
		echo -e "\e[47;32;4mservices.cfg\e[0m: define global service;\e[36;4mbind command\e[0m!"
		echo "		^"
		echo "		|"
		echo "	       use"
		echo "		|"
		echo -e "@ \e[32;4m$conf_dir/xsers/\e[0m:"
		echo -e "\e[47;32;4mservices.cfg\e[0m: define OU service;\e[36;4mbind global service & hostgroup\e[0m!"
		echo "		^"
		echo "		|"
		echo "	       use"
		echo "		|"
		echo -e "@ \e[32;4m$conf_dir/xsers/\e[0m:"
		echo -e "\e[47;32;4mhostgroup.cfg\e[0m: define hostgroup;\e[36;4mbind host\e[0m!"
		echo "		^"
		echo "		|"
		echo "	       use"
		echo "		|"
		echo -e "@ \e[32;4m$global_dir/\e[0m:"
		echo -e "\e[47;32;4mescalations.cfg\e[0m: define notify;\e[36;4mbind hostgroup\e[0m!"
		echo -e "\n\nAfter define above,then:"
		echo -e "@ \e[34;4m$service_config_module\e[0m:One line one \e[36;4mSERVICE\e[0m NAME!"
		echo -e "@ \e[34;4m$group_config_module\e[0m:One line one \e[36;4mGROUP\e[0m NAME!"
		
		exit 2
	fi

	if ! grep -qw $service_description $service_conf;then
		#echo -e "\e[31m$service_description\e[0m not defined in \e[32m$service_conf\e[0m"
		sed "s/ser-nginx/$gser_name/; \
			s/NOC\.NGINX/$service_description/; \
			s/NOC-NGINX/$group_description/" $service_config_module >> $service_conf
	fi

	if ! grep -qw $group_description $group_conf;then
		#echo -e "\e[31m$group_conf\e[0m not defined in \e[32m$group_conf\e[0m"
		sed "s/NOC-NGINX/$group_description/" $group_config_module >> $group_conf
	fi

	if sed -n "/alias.*$group_description$/{n;p}" $group_conf | grep -q $host;then
		echo -e "\e[32m$host\e[0m:alread exist."
		host_failed[$num]=$host && num=$[$num+1]
		continue
	fi

	sed -i "/alias.*$group_description$/{n;s/$/$host,/}" $group_conf
	host_succeed[$num]=$host && num=$[$num+1] && newdo=$[$newdo+1]
done
[ ! -z $host_failed ] && \
echo -e "\n\e[47;31;4;5mFailed\e[0m: ${host_failed[@]}"
[ ! -z $host_succeed ] && \
echo -e "\n\e[47;32;4;5mSucceed\e[0m: ${host_succeed[@]}"

if [ $newdo -gt 0 ];then
	update_conf
	sync_remote
fi
