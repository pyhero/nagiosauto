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
cleanNofity () {
	newdo=0
	num=0
	for host in $ips;do
		## check if ip in idc private net.
		chkIpInNet
		## def ip belong to which idc.
		def_location

		conf_dir=$nagios_conf_configure_dir/conf/$location
		dir=$conf_dir && chkdir

		group_conf=$conf_dir/xsers/notify_hostgroup.cfg
		file=$group_conf && chkfile
		if ! grep -q $NOTIFY_GROUP_NAME $group_conf;then
			echo -e "$NOTIFY_GROUP_NAME \e[31mnot defined in\e[0m $group_conf "
			exit 2
		fi
		if sed -n "/alias.*$NOTIFY_GROUP_NAME/{n;p}" $group_conf | grep -q $host;then
			sed -i "/alias.*$NOTIFY_GROUP_NAME/{n;s/$host//;s/,,/,/g;s/,,/,/g}" $group_conf
			host_succeed[$num]=$host && num=$[$num+1] && newdo=$[$newdo+1]
			successStore && cleanIP
		fi

		if ! sed -n "/alias.*$NOTIFY_GROUP_NAME/{n;p}" $group_conf | egrep -q '[0-9]';then
			nofity_conf=$conf_dir/xsers/escalations.cfg
			echo -e "\e[35m$NOTIFY_GROUP_NAME\e[0m@\e[34m$group_conf\e[0m has no members.Delete these lines."
			echo -e "Clear \e[35m$ESCALATION_SER_NAME\e[0m@\e[34m$nofity_conf\e[0m."
			echo -e "\nAfter all above,Then run \e[32m./sync_conf.sh\e[0m"
			exit 2
		fi
	done
}

cleanNofity
if [ $newdo -gt 0 ];then
	update_conf
	sync_remote
fi
