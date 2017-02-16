#!/bin/bash
#

ROOT=$(cd `dirname $0`;echo $PWD)
SRC=$ROOT/src
CONF=$ROOT/conf
SCRIPT=$ROOT/script
WORK="/ROOT/server/nagios"

loip=$(ip a | grep inet | grep -v inet6 | grep -v "127\.0\.0\.1" | \
	egrep '(192\.168\.[0-9]*\.[0-9]*|10\.[0-9]*\.[0-9]*\.[0-9]*|172\.16\.[0-9]*\.[0-9]*)' | \
	awk '{print $2}' | awk -F '/' '{print $1}')

download () {
	# You need to temm me url=? & name=? first.
	#url=
	# Name is the software packet.
	#name=
	if [ ! -f $file ];then
	/usr/bin/wget -q $url -O $SRC/$name
	fi
}

check_dir () {
	# You need to tell me dir=? first.
	#dir=
	if [ ! -d $dir ];then
		mkdir -p $dir
	fi
}

# Install Dependency.
echo -e "\n\e[31mInstall dependency: ...\e[0m"
yum -q install httpd php gcc glibc glibc-common gd gd-devel -y

# Install pnp4nagios
echo -e "\n\e[31mInstall pnp4nagios: ...\e[0m"
yum -q install rrdtool-devel openssl-devel php-gd -y
pnp4nagios="pnp4nagios-0.6.25"
file=$SRC/${pnp4nagios}.tar.gz
name=${pnp4nagios}.tar.gz
url="http://jaist.dl.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-0.6.25.tar.gz"
download
cd $SRC && tar zxf $name && cd $pnp4nagios

./configure --prefix=$WORK/pnp4nagios > /dev/null && \
	make all > /dev/null && \
	make install > /dev/null && \
	make install-webconf > /dev/null && make install-config > /dev/null && make install-init > /dev/null
sed -i "/AuthUserFile/s/\/.*/\/ROOT\/server\/nagios\/etc\/htpasswd.users/;s/Allow from all/Allow from 127.0.0.1 192.168.0.0\/16 10.0.0.0\/8 172.16.0.0\/12/" /etc/httpd/conf.d/pnp4nagios.conf

# configure
nagioscfg=$WORK/etc/nagios.cfg
sed -i '/process_performance_data/s/0/1/' $nagioscfg
mkdir -p /ROOT/server/nagios/pnp4nagios/var/service-perfdata /ROOT/server/nagios/pnp4nagios/var/host-perfdata
cat $CONF/performance_data.cfg >> $nagioscfg
sed -i '/^#host_perfdata_command/s/^#//;/^#service_perfdata_command/s/^#//' $nagioscfg
sed -i '/escape_html_tags/s/1$/0/' $nagioscfg

chown -R nagios.nagios $WORK

cd $ROOT
