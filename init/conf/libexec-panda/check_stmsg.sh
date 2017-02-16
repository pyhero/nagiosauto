#!/bin/bash
#
# Monitor how many msgs left.
# If not enough 5000,then notify.
# You should open your acl rules first.

salemsg_api="http://221.179.180.158:8081/QxtSms_surplus/surplus?OperID=aiuv&OperPass=aiuv123"
authmsg_api="http://221.179.180.158:8081/QxtSms_surplus/surplus?OperID=jiluyou&OperPass=jiluyou123"

mi=0
ei=0
get_code () {
	limit=10000
	resault=$(/usr/bin/curl -s $api | \
		grep -Po '(?<=\<rcode\>).*(?=\<\/rcode\>)')

	if [ $resault -lt $limit ];then
		echo -n "${fun}Msg only have $resault.Recharge as soon as you can. "
		exit_code[$ei]=2
		ei=$[$ei+1]
		elif [ $resault -lt 0 ];then
			echo -n "${funi}msg Negative. "
			exit_code[$ei]=3
			ei=$[$ei+1]
		else
			echo -n "${fun}Msg is enough:$resault. "
			exit_code[$ei]=0
			ei=$[$ei+1]
	fi
	msg[$mi]=" ${fun}msg=$resault"
	mi=$[$mi+1]
}

# get info
for fun in sale auth;do
	eval api="\$${fun}msg_api"
	get_code
done

echo "| ${msg[@]}"

# how to exit
for i in ${exit_code[@]};do
	if [ $i -ne 0 ];then
		exit $i
	fi
done
exit 0
