#!/bin/bash
#
# Author: Xu Panda
# Update: 2015-07-23

cmd=$(which snmpwalk 2> /dev/null)
if [ ! $cmd ];then
	echo "Install snmpwalk:yum install -y net-snmp-utils"
	exit 2
fi

dohelp () {
	echo -e "Useage:$0 -H HOSTADDRESS -o OID [OPTIONS] \n"
	echo -e "Use snmp to get info.\nAuthor: Xu Panda\nVersion: 0.1\n"
	echo -e "OPTIONS:"
	echo "  -h		display this help message"
	echo "  -H		HOSTADDRESS The host to check"
	echo "  -v 1|2c|3	specifies SNMP version to use"
	echo "  default is 2v"
	echo "  -c		set the community string"
	echo "  default is ikelSNMPv2Cm"
	echo "  -o		set snmp oid"
	exit 1
}

[ $# -lt 2 ] && dohelp

while getopts H::v::c:o::h arg;do
	case $arg in
		H)
			host=$OPTARG
			;;
		v)
			ver=$OPTARF

			;;
		c)
			com=$OPTARG
			
			;;
		o)
			oid=$OPTARG
			
			;;
		h)
			dohelp
			;;
		*)
			dohelp
	esac
done
[ ! $ver ] && ver="2c"
[ ! $com ] && com="PaxX2099clv2"
[ ! $oid ] && oid="hrSystemDate"

#Time oid: hrSystemDate

doit () {
	$cmd -v $ver -c $com $host $oid 2> /dev/null
	if [ $? -ne 0 ];then
		exit 2
	fi
}

gettime () {
	local war=10 && local cri=30
	rtime=$(doit | awk '{print $NF}')
	[ ! $rtime ] && echo "Get time failed." && exit 3
	rtime=$(echo $rtime | sed 's/\,/ /g') && rtime=$(date '+%s' -d "$rtime")
	ltime=$(date '+%s')
	difftime=$[$rtime-$ltime] && difftime=${difftime#-}
	if [ $difftime -lt $war ];then
		echo "$difftime secs differ with nagios. | TimeBad=0"
		exit 0
	elif [ $difftime -ge $war -a $difftime -lt $cri ];then
		echo "$difftime secs differ with nagios. | TimeBad=1"
		exit 1
	elif [ $difftime -ge $cri ];then
		echo "$difftime secs differ with nagios. | TimeBad=1"
		exit 2
	fi
}

gettime
