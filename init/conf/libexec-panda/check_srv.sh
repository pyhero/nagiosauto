#!/bin/bash
# Check WuDi's srv_mon healthy and return time.

OK=0
WAR=1
CRI=2
UNK=3

while getopts H:V: OPT;do
	case $OPT in
		H)
			ip=${OPTARG}
			;;
		V)
			var=${OPTARG}
			;;
		h)
			echo "Useage $0 -H ip -V common_down/hot_sync"
			echo "H : IP Address."
			echo "V : hot_sync || hot_sync"
			;;
		*)
			echo "Run $0 -h to get helps."
	esac
done

url="http://msg.p2p.ikcd.net/srv_mon.php?ip=${ip}&srv=${var}"
COM () {
	/usr/bin/curl -s -w ";%{http_code}" ${url}
}

RETVAL=$(COM)

STAT=$(echo $RETVAL | awk -F ";" '{print $2}')
TIME=$(echo $RETVAL | awk -F ";" '{print $1}')

ok () {
	echo "OK.Time=$TIME|Time=$TIME"
	exit $OK
}

war () {
	echo "Waring.Time=$TIME|Time=$TIME"
	exit $WAR
}

cri () {
	echo "Critical.Time=$TIME|Time=$TIME"
	exit $CRI
}

unk () {
	echo "${STAT} Cant not connect to server! | Time=$TIME"
	exit $UNK
}

echo $STAT | egrep "^[0-3][0-9][0-9]" > /dev/null
if [ $? -ne 0 ];then
	unk
fi

if [ $TIME -le 3600 ];then
	ok
	elif [ $TIME -gt 3600 && $TIME -le 7200 ];then
		war
	elif [ $TIME -gt 7200 ];then
		cri
fi
