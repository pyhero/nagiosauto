#!/bin/bash
#

dohelp () {
	echo "Useage:$0 -H HOSTNAME -c critical"
	exit 3
}

[ $# -lt 2 ] && dohelp

chk_cer () {
	end_day=$(openssl s_client -servername $sername -connect $sername:443 </dev/null 2>/dev/null | \
		sed -n '/-BEGIN CERTIFICATE/,/END CER/p' | \
		openssl x509 -text 2>/dev/null | \
		sed -n 's/ *Not After : *//p')

	today=$(date "+%s")
	endday=$(date "+%s" -d "$end_day")
	last=$[($endday-$today)/3600/24]
	msg="$sername cer last $last days."
	if [ $last -le $cri ];then
		echo $msg
		exit 2
	else
		echo $msg
		exit 0
	fi
}

while getopts H::c::h arg;do
	case $arg in
		H)
			sername=$OPTARG
			;;
		c)
			cri=$OPTARG
			;;
		h)
			dohelp
			;;
		*)
			dohelp
	esac
done

[ ! $cri ] && cri="30"
chk_cer
