#!/bin/bash
# Xu Panda 20130905
# Check mount mounted && healthy(Allowed write or not)

export PATH="/bin:/usr/local/bin:/sbin:/usr/bin:/usr/sbin"
OK=0
CRI=2
DATE=$(date "+%F-%H-%M-%S")

COM () {
	mount | grep $typ | grep $src | grep $pot &> /dev/null
	if [ $? -eq 0 ];then
		EX_MOU=$OK
		else
		echo -n "The DIR wasn't mounted."
		EX_MOU=$CRI
	fi
}

EXIT () {
	echo "exit $EXT"
}

health () {
	TF=$pot/nagios
	#touch $TF &> /dev/null
	#if [ $? -eq 0 ];then
	if [ -f $TF ];then
		echo -n "Mounted dir is OK!"
		EX_WRI=$OK
	#	rm -rf $TF
		else
		echo -n "Dir mounted but not allowed to read!"
		EX_WRI=$CRI
	fi
}

help () {
	echo 'Check mount mounted && healthy(Can write)'
	echo 'Useage $0 -S $source -P point -T type [-V]'
	echo '-h help'
	echo -e "-S the turth files,values= [ mount | awk '{print \$1}' ]"
	echo -e "-P the mount point,values= [ mount | awk '{print \$3}' ]"
	echo -e "-T the mount types,values= [ mount | awk '{print \$5}' ]"
	echo -e "-V the mount options,values= [ mount | awk '{print \$6}' ]"
}

while getopts hS:P:T:V opt;do
	case $opt in
		h)
			help
			exit 0
			;;
		S)
			src=$OPTARG
			;;
		P)
			pot=$OPTARG
			;;
		T)
			typ=$OPTARG
			;;
		V)
			var=$OPTARG
			;;
		*)
			help
			exit 1
	esac
done

COM
if [ $EX_MOU -eq 0 ];then
	health
fi

echo " | mount_health=$EX_MOU write_healthy=$EX_WRI"

for i in $EX_MOU $EX_WRI
do
	if [ $i -ne 0 ];then
		EXT=$i
		EXIT
		exit $i
	fi
done
EXT=$OK
EXIT
exit 0
