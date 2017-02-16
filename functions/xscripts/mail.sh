#!/bin/bash
#

#scripts_dir=./
cmd=$scripts_dir/sendEmail
[ ! -x $cmd ] && exit 2

## need define variables:
##		title:mail title
##		body:mail body

/usr/bin/printf "%b" "$body" | \
	$cmd -f nagios.noc@aiuv.cc \
		-t ng.noc@aiuv.cc \
		-s smtp.aiuv.cc \
		-u "$title" \
		-xu nagios.noc@aiuv.cc \
		-xp Xa1991lftih \
		-o message-content-type=html \
		> /dev/null
