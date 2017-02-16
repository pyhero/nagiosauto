#!/usr/bin/perl -w
#
# $Id: squid_summary.pl 85 2008-08-13 06:46:02Z kaili $
# mm system assistant tools
# summary squid group
#

use strict;
use File::Basename;
use lib dirname $0;

use RRDs;
use Data::Dumper;
use MM::HostGroup;
use MM::RRD;
use MM::SUM::Squidnew;

my $DIR = dirname $0;

# define parameters here
my $BASE_DIR  = "/opt/sohu/nagios";
#my $RRDS_DIR = $BASE_DIR . "/RRDdb/squid";
my $RRDS_DIR = $BASE_DIR . "/pnp/share/perfdata";
my $GRPRRDS_DIR = $BASE_DIR . "/RRDdb/squid_sum_new";

MM::SUM::Squidnew::doSum({
		dir_src	=> $RRDS_DIR,
		dir_des => $GRPRRDS_DIR,
		url_grp => 'http://ctm.no.sohu.com/infosys/getgroup.php',
		});
