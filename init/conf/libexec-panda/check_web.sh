#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
O=0
C=2

COM() {
	if [ ! -z $DOMAIN ];then
		curl -o /dev/null -s -k -w "%{http_code};time_connect=%{time_connect} time_starttransfer=%{time_starttransfer} time_total=%{time_total}" -H "$HOST"  "$URL"
		else
		curl -o /dev/null -s -k -w "%{http_code};time_connect=%{time_connect} time_starttransfer=%{time_starttransfer} time_total=%{time_total}" $fun "$URL"
	fi
}

while getopts U:ShD: OPT;do
	case $OPT in
		U)
			URL=${OPTARG}
			;;
		H)
			HOST=${OPTARG}
			;;
		h)
			echo "-H domainname , url should use ip address"
			;;
		*)
			echo "Useage: $0 -U url [-H] [-h]"
			exit 1
	esac
done		

CODE_VALUE=`COM`
echo $CODE_VALUE | egrep "^[2-3][0-9][0-9]" > /dev/null
CODE_TYPE=$?

STATUS() {
	echo -n `echo $CODE_VALUE | awk -F ';' '{print $1}' `
}

PER() {
	echo "| `echo $CODE_VALUE | awk -F ';' '{print $2}'`"
}

OK() {
	echo -n OK,
	STATUS
	PER
	exit $O
}

CRI() {
	echo -n Critical,
	STATUS
	PER
	exit $C	
}

if [ -z `STATUS` ];then
	CRI
	elif [ $CODE_TYPE -eq 0 ];then
		OK
	else
	CRI
fi
