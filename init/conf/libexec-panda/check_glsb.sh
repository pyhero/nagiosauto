#!/bin/bash
# Check active in mysql(10.9.1.65),if or not active=0.

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/root/bin"

if [ $# -lt 1 ];then
	echo "use check_goabroad_active.sh -h for more information."
	exit 1
	else
	while getopts H:s:h OPT;do
		case $OPT in
			H)
				HOST=$OPTARG
				;;
			s)
				SER=$OPTARG
				;;
			h)
				echo "Useage check_goabroad_active.sh -H address -s address."
				echo "-H mysql's IP"
				echo "-s vps's IP"
				exit 1
				;;
			*)
				echo "use check_goabroad_active.sh -h for more information."
				exit 1

		esac
	done
fi
CS=$(mysql -N -s -unagios -paiuv -h${HOST} -P 3307 -e"use router;select active,weight,conn/weight as userful from goabroad_host where ip='${SER}'")
INFO=$(echo $CS | awk '{print "Active="$1"  ""Weight="$2"  ""Useage="$3*100"%"}')
AT=$(echo $CS | awk '{print $1}')

if [ $AT -eq 0 ];then
	echo "$INFO. | $INFO"
	exit 2
	else
	echo "$INFO. | $INFO"
	exit 0
fi
