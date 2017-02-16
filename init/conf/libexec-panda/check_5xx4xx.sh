#!/bin/bash
# Check 5xx 4xx from nginx log!

OK=0
CRI=2
UN=3
LOG=/ROOT/server/nginx/logs/bbs.aiuv.com_access.log
# chk how many lines!
NUM=1000

if [ ! -f $LOG ];then
	echo "No such file or directory!"
	exit $UN
fi

chk_line () {
	cat $LOG | wc -l
}
LINE=`chk_line`

chk_err () {
	tail -n $NUM $LOG | awk 'BEGIN{i5=0;i4=0}{ if ($10 ~/^5/){i5++} if ($10~/^4/){i4++} }END{print "5xx="i5" ""4xx="i4}' 2> /dev/null
}
DATA=`chk_err`
echo "$DATA of the last $NUM lines. | $DATA File_Total_Lines=$LINE"
