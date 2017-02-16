#!/bin/bash
# Check total surplus and every area's surplus from mysql.

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/root/bin"

if [ $# -lt 1 ];then
	echo "use check_goabroad_surplus.sh -h for more information."
	exit 1
	else
	while getopts H:a:h OPT;do
		case $OPT in
			H)
				HOST=$OPTARG
				;;
			a)
				AREA=$OPTARG
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
SUR=$(mysql -N -s -unagios -pnagios -h${HOST} -P 3307 -e"use router;select sum(weight)-sum(conn) as sur from goabroad_host where area='${AREA}' and enable=1")
TOTAL=$(mysql -N -s -unagios -pnagios -h${HOST} -P 3307 -e"use router;select sum(weight)-sum(conn) as sur from goabroad_host where enable=1")

echo "$AREA has $SUR free.Total free: $TOTAL."
