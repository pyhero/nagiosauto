#!/bin/bash
#Check openvpn obfsproxy squid httpd dnsmasq

# openvpn
# Use another perl script
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3
OP=`/usr/local/nagios/libexec/check_openvpn.pl -H 127.0.0.1 -p 8444 -n 2>&1`
STATUS=`echo "$OP" | awk '{print $2}' | awk -F ":" '{print $1}'`
CLIENTS=`echo "$OP" | awk '{print $3}'`
#CLIENTS=`(sleep 1;echo status 2;sleep 1) | telnet 127.0.0.1 8444 | grep ^CLIENT_LIST  | wc -l`

if [ "$STATUS" = "OK" ];then
#	if [ $CLIENTS -le 90 -a $CLIENTS -gt 5 ];then
		echo -n "$OP"
		VPN_EXIT=$OK
#		elif [ $CLIENTS -le 5 ];then
#			echo -n "Openvpn is OK,but only $CLIENTS clients!"
#			VPN_EXIT=$CRITICAL
#		elif [ $CLIENTS -gt 90 ];then
#			echo -n "Openvpn is OK,$CLIENTS clients is to many!"
#			VPN_EXIT=$WARNING
#	fi
	elif [ "$STATUS" = "WARNING" ];then
		echo -n "$OP"
		VPN_EXIT=$WARNING
	elif [ "$STATUS" = "Critical" ];then
		echo -n "$OP"
		VPN_EXIT=$CRITICAL
	elif [ "$STATUS" = "UNKNOWN" ];then
		echo -n "$OP"
		VPN_EXIT=$UNKNOWN
fi

# squid_memory_use
ps auxf | grep squid | grep '(s' 2>&1 > /dev/null
if [ $? -ne 0 ];then
	echo -n " squid stoped!"
	SQU_EXIT=$CRITICAL
	else
	TMEM=`ps auxf | grep squid | grep '(s' | awk '{print $4}'`
	MEM=`ps auxf | grep squid | grep '(s' | awk '{print $4}' | awk -F "." '{print $1}'`
	MIN=30
	MAX=45
	if [ $MEM -le $MIN ];then
		SQU_EXIT=$OK
		elif [ $MEM -ge $MAX ];then
			echo -n " squid used $TMEM% mem !"
			SQU_EXIT=$CRITICAL
	fi
fi

# dnsmasq
ps auxf | grep dnsmasq | grep /usr 2>&1 > /dev/null
DNS=$?

if [ $DNS -eq 0 ];then
#	echo -n " dnsmasq is running."
	DNS_EXIT=$OK
	else
	echo -n " dnsmasq is stoped."
	DNS_EXIT=$CRITICAL
fi

# httpd
ps auxf | grep httpd | grep apache 2>&1 > /dev/null
HTTP=$?

if [ $HTTP -eq 0 ];then
#	echo -n " httpd is running."
	HTTP_EXIT=$OK
	else
	echo -n " httpd is stoped."
	HTTP_EXIT=$CRITICAL
fi

# obfsproxy
PORT="563 695 989 995 3660 8080"
for i in $PORT
do
	ps auxf | grep obfsproxy | grep $i 2>&1 > /dev/null
	if [ $? -eq 0 ];then
		RUN[$i]=$i
		else
		BAD[$i]=$i
	fi
done
TEST=`echo ${BAD[@]} | awk '{print $1}'`

if [ ! -z $TEST ];then
	echo " obfsproxy port: ${BAD[@]} is down."
	OBFS_EXIT=$CRITICAL
	else
#	echo -n " obfsproxy port: ${RUN[@]} is ok."
	OBFS_EXIT=$OK
fi

# exit
VPS="$OBFS_EXIT $VPN_EXIT $SQU_EXIT $DNS_EXIT $HTTP_EXIT"

for i in $VPS
do
	if [ $i -eq 3 ];then
		echo " [active=0] | clients=$CLIENTS;;;0 squid_used_%=$TMEM;;;0.0 active=1"
		exit $UNKNOWN
		elif [ $i -eq 2 ];then
			echo " [active=0] | clients=$CLIENTS;;;0 squid_used_%=$TMEM;;;0.0 active=0"
			exit $CRITICAL
#		elif [ $i -eq 1 ];then
#			echo "|clients=$CLIENTS;;;0 squid_used_%=$TMEM;;;0.0"
#			exit $WARNING
	fi
done


echo " [active=1] | clients=$CLIENTS;;;0 squid_used_%=$TMEM;;;0.0 active=1"
exit $OK
