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
	if [ $? -ne 0 ];then
		exit 2
	fi
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
yum -q install httpd php gcc glibc glibc-common gd gd-devel perl-YAML -y

rsync -aqz --delete $CONF/etc/* $WORK/etc/
rsync -aqz $CONF/libexec* $CONF/keyserver $CONF/utils $WORK/
rsync -aqz $CONF/pnp4nagios/share $WORK/pnp4nagios/
rsync -aqz $CONF/pnp4nagios/etc/check_commands/ $WORK/pnp4nagios/etc/check_commands/
rsync -aqz $CONF/keyserver/mks.init /etc/init.d/mks
cat > $WORK/pnp4nagios/etc/check_commands/check_mysql.cfg << EOF
DATATYPE = COUNTER
EOF

srcsnmp=/ROOT/conf/nginx/static/data/snmpd.xml
if [ -f $srcsnmp ];then
	cd $WORK/etc/mks
	mv snmpd.xml snmpd.xml.def
	ln -s $srcsnmp snmpd.xml
	cd -
fi

mkdir -p $WORK/RRDdb/tmp

yum -q install -y fping perl-CPAN perl-ExtUtils-MakeMaker perl-Nagios-Plugin perl-Net-SNMP perl-XML-Simple perl-Net-Server rrdtool-perl

data="Data-Serializer-0.60.tar.gz"
file=$SRC/$data
name=$data
url="http://search.cpan.org/CPAN/authors/id/N/NE/NEELY/Data-Serializer-0.60.tar.gz"
download

cd $SRC && tar zxf $data > /dev/null && cd Data-Serializer-0.60
perl Makefile.PL && perl Makefile.PL &&  make > /dev/null && make install > /dev/null
perl -MCPAN -e 'install "Net::Server::PreFork"'
perl -MCPAN -e 'install "XML::Simple"'

cd $ROOT

yum -q install -y perl-DBI perl-DBD-MySQL mysql
/etc/init.d/mks restart > /dev/null
