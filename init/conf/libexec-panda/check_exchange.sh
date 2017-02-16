#!/bin/bash
# Xu Panda 20130906
# For nrpe to cat status file.

export PATH="/bin:/usr/local/bin:/sbin:/usr/bin:/usr/sbin"
OK=0
CRI=2
#DATE=$(date "+%F-%H-%M-%S")

judge () {
	if [ ! -f $FILE ];then
		echo "Unknown status file!"
		exit $CRI
		else
		if [ $(cat $FILE | wc -l) -lt 2 ];then
			echo "Bad status file!"
			exit $CRI
		fi
	fi
}

DATA () {
	sed '$d' $FILE
}

EXIT () {
	sed -n '$p' $FILE
}

help () {
	echo -e "Useage $0 -F \$file"
	echo ""
	echo "-h  help"
	echo "-F  The log recorde exhchange.Two lines like:"
	echo ""
	echo "db.log no changes. | stat=0"
	echo "exit 0"
	echo ""
	echo "Line 1 will push to nagios xxxdata;"
	echo "Line 2 will push the exit status to nagios."
}

while getopts hF: opt;do
	case $opt in
		h)
			help
			exit 0
			;;
		F)
			FILE=$OPTARG
			;;
		*)
			help
			exit 1
	esac
done

judge
echo `DATA`
`EXIT`
