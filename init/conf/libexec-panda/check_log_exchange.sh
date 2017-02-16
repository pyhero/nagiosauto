#!/bin/bash
# Xu Panda 20130906
# Check if the log is exchanged.

export Path="/bin:/usr/local/bin:/sbin:/usr/bin:/usr/sbin"
OK=0
CRI=2

var () {
	# The truth log file
	LOG_TURE=$DIR/$FILE

	# Mkdir a new directory to check the changes
	LOG_DIR=$DIR/Log_Check

	# The truth log file's mirror for diff the log file
	LOG_MIR=${LOG_DIR}/${FILE}.mir

	# The log's exchange
	LOG_DIF=${LOG_DIR}/${FILE}.dif

	# Bakup the mirror
	LOG_BAK=${LOG_DIR}/${FILE}.bak
}

judge () {
	# Check Dir
	if [ ! -d $LOG_DIR ];then
		mkdir $LOG_DIR
	fi

	# Log mirror
	if [ ! -f $LOG_MIR ];then
		cp $LOG_TURE $LOG_MIR
	fi
}

new () {
	mv $LOG_MIR $LOG_BAK
	cp $LOG_TURE $LOG_MIR
}

check () {
	diff $LOG_TURE $LOG_MIR > $LOG_DIF
	if [ $? -ne 0 ];then
		echo -n "$LOG_TURE: $(cat $LOG_DIF)"
		echo " | stat=$CRI"
		new
		EXT=$CRI
		EXIT
		exit $CRI
		else
		echo -n "$LOG_TURE no changes."
		echo " | stat=$OK"
		EXT=$OK
		EXIT
		exit $OK
	fi
}

EXIT () {
	echo "exit $EXT"
}

help () {
	echo -e "Useage $0 -D \$directory -F \$file"
	echo "-h  help"
	echo "-D  The log file's directory"
	echo "-F  The name of the log file"
}

while getopts hD:F: opt;do
	case $opt in
		h)
			help
			exit 0
			;;
		D)
			DIR=$OPTARG
			;;
		F)
			FILE=$OPTARG
			;;
		*)
			help
			exit 1
	esac
done

var
judge
check
