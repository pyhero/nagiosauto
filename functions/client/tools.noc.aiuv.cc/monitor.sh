#!/bin/bash
#

center_ser="noc.aiuv.cc"
if ! ping -c 1 $center_ser;then
	echo -e "\e[32mCan not connect to $center_ser!\e[0m"
	echo "Call ZhangLong"
	exit 2
fi

v3File="/etc/snmp/snmpd.local.conf"
if [ -f $v3File ];then
	echo "May installed!"
	exit 1
fi

script_dir=/ROOT/sh && mkdir -p $script_dir

rundir=/tmp && cd $rundir

## add snmp keys post ser resolve
if ! grep -q 'post.aiuv.cc' /etc/hosts;then
cat >> /etc/hosts << EOF
10.0.202.200	post.aiuv.cc
EOF
fi

url="http://tools.noc.aiuv.com/monitor/snmpv3.tgz"
$(which wget) $url -q

package=snmpv3
$(which tar) zxf ${package}.tgz && cd $package
if cat /etc/redhat-release | egrep -qi '(release 5|release 4)';then
	cd soft
	rpmbuild --quiet -bb net-snmp-host-sohu.spec
	rpmbuild --quiet -bb net-snmp-snmpv3-sohu.spec
	mv /usr/src/redhat/RPMS/noarch/net-snmp*.rpm ./
	cd -
fi
sh install.sh
