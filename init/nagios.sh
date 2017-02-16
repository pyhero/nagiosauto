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
	mkdir -p $dir
}

# Install Dependency.
echo -e "\n\e[31mInstall dependency: ...\e[0m"
yum -q install httpd php gcc glibc glibc-common gd gd-devel -y

# Install nagios core.
echo -e "\n\e[31mInstall nagios: ...\e[0m"
id nagios &> /dev/null
if [ $? -ne 0 ];then
	groupadd -g 700 nagios && useradd -u 700 -g 700 -s /sbin/nologin nagios
fi

nagios="nagios-4.1.1"
file=$SRC/${nagios}.tar.gz
name=${nagios}.tar.gz
url="https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.1.1.tar.gz"
download

cd $SRC && tar zxf $name > /dev/null && cd $nagios
./configure --prefix=$WORK --with-nagios-user=nagios --with-nagios-group=nagios > /dev/null && \
	make all > /dev/null && \
	make install > /dev/null && \
	make install-init > /dev/null && \
	make install-commandmode > /dev/null && \
	make install-config > /dev/null && \
	make install-webconf > /dev/null && \
	make install-exfoliation > /dev/null
cd $ROOT

sed -i "s/Allow from all/Allow from 127.0.0.1 192.168.0.0\/16 10.0.0.0\/8 172.16.0.0\/12/" /etc/httpd/conf.d/nagios.conf

sed -i '/^Listen/s/.*/Listen 127.0.0.1:880/' /etc/httpd/conf/httpd.conf 
cat >> /etc/httpd/conf.d/nagios.conf << EOF

NameVirtualHost 127.0.0.1:880
<VirtualHost 127.0.0.1:880>
        DocumentRoot /ROOT/server/nagios/share
        ServerName nagios.aiuv.cc
</VirtualHost>
EOF

sed -i '/statusjson.cgi/s/cgi-bin/\/nagios\/cgi-bin/' $WORK/share/main.php

#echo -e "\n\e[31mCreate user nagiosadmin(Default passwd:admin): ...\e[0m"
#/usr/bin/htpasswd -c /ROOT/server/nagios/etc/htpasswd.users nagiosadmin
#/etc/init.d/httpd restart > /dev/null

