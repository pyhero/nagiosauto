#!/usr/bin/perl -w
#
# $Id: vms.pl 83 2008-08-09 14:48:56Z kaili $
# mm system assistant tools
# vms service config generator
#
use strict;
use File::Basename;
use lib dirname $0;

use XML::Simple;
use File::Basename;
use Data::Dumper;
use MM::Basic;
use MM::HostGroup;
use MM::ConfigGen;

# define parameters here
my $DIR_BASE  = "/opt/sohu/nagios";

my $CFG_FILE	= "file://$DIR_BASE/etc/vms_config.xml";
my $URL_GRP	= "file://$DIR_BASE/etc/vms_list.xml";
my $DIR_OUTPUT	= "$DIR_BASE/etc/vms/";
#my $DIR_OUTPUT = "/tmp/k";
my $ADM_DEFAULT	= "vod-admins";
# strip too long groupname suffix
my $SUF_STRIP	= ".itc.cn";

my $SER_MAP = {
	hoststatic	=> 'host-static-vms',
	nginx		=> 'nginx-vms',
	squid		=> 'squid-vms',
	squid2		=> 'squid2-vms',
	lighttpd	=> 'lighttpd-vms',
};

MM::ConfigGen::genconf({
	cfg_file	=> $CFG_FILE,
	url_grp		=> $URL_GRP,
	dir_output	=> $DIR_OUTPUT,
	adm_default	=> $ADM_DEFAULT,
	ser_map		=> $SER_MAP,
	suf_strip	=> $SUF_STRIP,
	});
