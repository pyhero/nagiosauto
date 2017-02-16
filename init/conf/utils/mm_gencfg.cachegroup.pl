#!/usr/bin/perl -w
#
# $Id: mm_gencfg.cachegroup.pl 83 2008-08-09 14:48:56Z kaili $
# mm system assistant tools
# summary squid group
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

my %config = do 'config.pl';
# define parameters here
my $DIR_BASE  = "/opt/sohu/nagios";

my $CFG_FILE = "file://$DIR_BASE/etc/cachegroups.xml";
my $URL_GRP = 'http://ctm.no.sohu.com/infosys/getgroup.php';
my $DIR_OUTPUT = "$DIR_BASE/etc/cachegroups/";
#my $DIR_OUTPUT = "/tmp/k";
my $ADM_DEFAULT = "linux-admins";
my $SUF_STRIP	= ".sohu.com";

MM::ConfigGen::genconf({
	cfg_file	=> $CFG_FILE,
	url_grp		=> $URL_GRP,
	dir_output	=> $DIR_OUTPUT,
	adm_default	=> $ADM_DEFAULT,
	suf_strip	=> $SUF_STRIP,
	});
