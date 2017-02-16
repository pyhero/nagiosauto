#!/bin/sh

dir=$(cd `dirname $0`;echo $PWD)

# Check whether we have sufficient privileges
if [ $(whoami) != "root" ]; then
	echo "This script needs to be run as root/superuser."
	exit 1
fi

# Install prerequisite packages
yum install -yq wget httpd php php-xml

# Download and install MNTOS from Exchange
cd /ROOT/src
wget "http://exchange.nagios.org/components/com_mtree/attachment.php?link_id=528&cf_id=24" -O mntos-1.0.tar.gz.gz
gunzip mntos-1.0.tar.gz.gz
tar xf mntos-1.0.tar.gz
rm mntos-1.0.tar.gz
cd mntos-1.0
wget "http://assets.nagios.com/downloads/nagiosxi/misc/globe.png" -O www/img/globe.png
#wget "http://assets.nagios.com/downloads/nagiosxi/scripts/NagiosXI-MNTOS-configure.py"
#chmod +x NagiosXI-MNTOS-configure.py

# Make necessary changes to MNTOS configuration file
sed -i 's/contacts\=.*/contacts="\/ROOT\/www\/mntos-1\.0\/"/' config.ini
sed -i 's/networks\=.*/networks="\/ROOT\/www\/mntos-1\.0\/"/' config.ini
sed -i 's/xmloutput\=.*/xmloutput="\/ROOT\/www\/mntos-1.0\/www\/"/' config.ini

# Walk through initial setup of contacts and networks to show in the interface
$dir/NagiosXI-MNTOS-configure.py

# Make sure this server allows HTTP connections to view the dashboard
#iptables -I RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
#iptables save
#service iptables restart

# Update information from the remote Nagios servers via cron
echo '* * * * * /usr/bin/php /ROOT/www/mntos-1.0/mntos.php /dev/null 2>&1' > /etc/cron.d/mntos

# This line is here so it can be changed if the cron job is changed to run less than every minute (it's in seconds)
sed -i 's/refreshfreq\ =\ 60/refreshfreq\ =\ 60/' www/index.php

# Adjust permissions
chown -R nagios:www-data .
chmod o-r networks.ini
chmod g+w .

# Create a virtual host definition for Apache
echo -e "\
	Alias /mntos \"/ROOT/www/mntos-1.0/www\"\n\
	\n\
	<Directory \"/ROOT/www/mntos-1.0/www\">\n\
	#  SSLRequireSSL\n\
	   Options None\n\
	   AllowOverride None\n\
	   Order allow,deny\n\
	   Allow from all\n\
	</Directory>" > /etc/httpd/conf.d/mntos.conf

# Reload Apache configuration
service httpd restart

echo ""
echo "============================="
echo "MNTOS Installation Complete!"
echo "You can now view the MNTOS interface at http://"$(ifconfig | grep "inet\ addr" | head -n1 | sed 's/^[^:]*://' | sed 's/\ .*//')"/mntos/"
echo "============================="
