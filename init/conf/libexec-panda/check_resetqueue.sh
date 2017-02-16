#!/bin/bash
#

# From Gao Xubin to monitor "reset queue" len.

len=$(curl -s -k "https://app.aiuv.com/cloud.php?m=statistics&a=GetResetQueueLen&t=ca33473a5cdc28f9d12b8b6feea8ec9a")

echo "reset-queue=$len | reset-queue=$len"
if [ $len -gt 20000 ];then
	exit 1
fi
exit 0
