#!/bin/bash
#
# Author: Panda
# Update: 20160627

DIR=$(cd `dirname $0`;echo $PWD)
function printHelp () {
	echo -e "Usage:$0 {\e[32mip address\e[0m | \e[32mip list file\e[0m} {\e[32mnofity group name\e[0m}"
	echo -e "\n\$1:\tIf only one host,then set \$1 as IP_ADDRESS,\n\tif many hosts,then one line one ip into a file,and set \$1 as the IP_LIST_FILE."
	echo -e "\n\$2:\tNeed define contact @xglobal/contact.cfg.\n\tThe name format must be like:\e[32mGROUP_NAME-contact\e[0m(like \e[32mnoc-contact\e[0m)"
	exit 3
}

[ $# -lt 2 ] && printHelp

##. source global variables.
funcs="$DIR/xscripts/functions"
if [ ! -f $funcs ];then
	echo -e "\e[32m$funcs\e[0m: not exist."
	exit 6
else
	source $funcs
fi

##. Get (host & notify_group) from ($1 & $2)
IP_SRC=$1
if [ -f $IP_SRC ];then
	ips=$(cat $IP_SRC)
	NEED_CLEAN=1
else
	ips=$IP_SRC
	NEED_CLEAN=0
fi

NOTIFY_GROUP=${2}
NOTIFY_GROUP_UP=$(echo $NOTIFY_GROUP|sed 's/[a-z]/\u&/g')
NOTIFY_GROUP_LO=$(echo $NOTIFY_GROUP|sed 's/[A-Z]/\l&/g')
NOTIFY_GROUP_NAME="${NOTIFY_GROUP_UP}-NOTIFY"
NOTIFY_CONTACT_NAME="${NOTIFY_GROUP_LO}-contact"
ESCALATION_SER_NAME="$NOTIFY_GROUP_LO-eeser"
ESCALATION_HOST_NAME="$NOTIFY_GROUP_LO-eehost"

CONTACT_FILE=$nagios_conf_configure_dir/conf/xglobal/contact.cfg
if ! grep -q $NOTIFY_CONTACT_NAME $CONTACT_FILE;then
	echo -e "Define contact name \e[31m$NOTIFY_CONTACT_NAME \e[32m@$CONTACT_FILE\e[0m first."
	exit 2
fi

##. loglog
successStore () {
	succeed_list=$history_dir/notify_succ.$today && touch $succeed_list
	if ! grep -q $host $succeed_list;then
		echo "$host > $NOTIFY_GROUP_NAME" >> $succeed_list
	fi
}

failedStore () {
	failed_list=$history_dir/notify_fail.$today && touch $failed_list
	if ! grep -q $host $failed_list;then
		echo $host >> $failed_list
	fi
}

cleanIP () {
	if [ $NEED_CLEAN == 1 ];then
		sed -i "/$host/d" $IP_SRC 2> /dev/null
	fi
	[ ! -s $IP_SRC ] && rm -rf $IP_SRC
} 

##. Add notify
generateNofity () {
	newdo=0
	num=0
	for host in $ips;do
		## check if ip in idc private net.
		chkIpInNet
		## def ip belong to which idc.
		def_location

		conf_dir=$nagios_conf_configure_dir/conf/$location
		dir=$conf_dir && chkdir
		host_conf=$conf_dir/xhosts/${host}.cfg
		if [ ! -f $host_conf ];then
			echo -e "\e[32m$host: not in config $host_conf\e[0m"
			host_failed[$num]=$host && num=$[$num+1]
			failedStore
			continue
		fi

		notify_conf=$conf_dir/xsers/escalations.cfg && touch $notify_conf
		if ! grep -q $ESCALATION_SER_NAME $notify_conf;then
			sed "s/noc/$NOTIFY_GROUP_LO/g; \
				s/NOC/$NOTIFY_GROUP_UP/g" \
				$escalations_config_module >> $notify_conf
			svn add $notify_conf
		fi
		if ! sed -n "/name.*$ESCALATION_HOST_NAME/{n;p}" $notify_conf | grep -q $NOTIFY_GROUP_NAME;then
			sed -i "/name.*$ESCALATION_HOST_NAME/{n;s/$/$NOTIFY_GROUP_NAME,/}" $notify_conf
		fi
		if ! sed -n "/name.*$ESCALATION_SER_NAME/{n;p}" $notify_conf | grep -q $NOTIFY_GROUP_NAME;then
			sed -i "/name.*$ESCALATION_SER_NAME/{n;s/$/$NOTIFY_GROUP_NAME,/}" $notify_conf
		fi

		group_conf=$conf_dir/xsers/notify_hostgroup.cfg && touch $group_conf
		if ! grep -q $NOTIFY_GROUP_NAME $group_conf;then
			sed "s/NOC-NOTIFY/$NOTIFY_GROUP_NAME/" $notify_group_module >> $group_conf
			svn add $group_conf
		fi
		if sed -n "/alias.*$NOTIFY_GROUP_NAME/{n;p}" $group_conf | grep -q $host;then
			echo -e "\e[32m$host\e[0m:alread in group:${NOTIFY_GROUP_NAME}."
			host_failed[$num]=$host && num=$[$num+1]
			failedStore
			continue
		fi
		sed -i "/alias.*$NOTIFY_GROUP_NAME/{n;s/$/$host,/}" $group_conf
		host_succeed[$num]=$host && num=$[$num+1] && newdo=$[$newdo+1]
		successStore && cleanIP
	done
}

generateNofity
if [ $newdo -gt 0 ];then
	update_conf
	sync_remote
fi
