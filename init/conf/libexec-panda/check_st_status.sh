#!/bin/bash
# Xu Panda 2013-09-12
# Recorde XJB's

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/root/bin"

OK=0
CR=2

URL="http://ucore.aiuv.tw/stats.php"

stat () {
	curl -o /dev/null -s -w "%{http_code}" $URL | egrep "^[0-3][0-9][0-9]" > /dev/null
}

data=$(curl -s $URL)

stat
if [ $? -ne 0 ];then
	echo "Can't connect to server!"
	exit $CR
fi

echo "$data | $data"
exit $OK
