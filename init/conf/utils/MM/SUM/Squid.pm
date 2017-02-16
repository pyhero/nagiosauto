#!/usr/bin/perl -w
#
# $Id: Squid.pm 96 2008-09-11 14:25:30Z kaili $
# mm system assistant tools
# summary squid group
#

package MM::SUM::Squid;

use strict;
#use File::Basename;
#use lib dirname $0;
use lib "../../";

#use XML::Simple;
use RRDs;
#use Time::Period;
use Data::Dumper;
use MM::HostGroup;
use MM::RRD;

#my $DIR = dirname $0;

# define parameters here
#my $BASE_DIR  = "/opt/sohu/nagios";
#my $RRDS_DIR = $BASE_DIR . "/RRDdb/squid";
#my $GRPRRDS_DIR = $BASE_DIR . "/RRDdb/squid_sum";
my ($RRDS_DIR, $GRPRRDS_DIR);

#
# get rrd files from ip list
sub getSquidRRDsByIps {
	# hash storing a ip's display count,
	# for multiple squid may correspond several files with only ONE ip
	my %count; 
	my @files;
	my $suffix=$_[1]?$_[1]:"";
	foreach my $ip (@{$_[0]}) {
		$count{$ip}++;
		if($count{$ip}==1) {
			# file must exist.
			if(-e "$RRDS_DIR/$ip$suffix.rrd") {
				push @files, "$RRDS_DIR/$ip$suffix.rrd";
			}
		} else {
			if(-e "${RRDS_DIR}2/$ip$suffix.rrd") {
				push @files, "${RRDS_DIR}2/$ip$suffix.rrd";
			}
		}
	}
	return @files;
}

#
# do group summarization from group ips
#
sub makeGroup {
	my $groupname=$_->{'name'};
	my @groupips =$_->{'ips'};
	my @files;

	my %ds;
	my $starttime = time;
	my $fileRRD = "$GRPRRDS_DIR/$groupname.rrd";

	my %param; # parameters transfer to RRD n2one 
	$param{'dfile'} = $fileRRD;
	$param{'step_new'} = 60;
	#if "one rrd" doesn't exsit, creating starttime is offset time before now
	$param{'offset_new'} = 1800;
	$param{'heartbeat'} = 3*$param{'step_new'};

	@files=&getSquidRRDsByIps(@groupips);
	%ds=qw( ClientHttpRequests
		HttpOutKb
		ServerRequests
		ServerInKb );
	push @{$param{'sfiles'}},{ds=>[%ds], files=>[@files]};


	@files=&getSquidRRDsByIps(@groupips,".obj");
	%ds=qw( NumObjCount
		NumObjRemoved );
	push @{$param{'sfiles'}},{ds=>[%ds], files=>[@files]};

	MM::RRD::RRDn2one(%param);
}

##### main routine #####
sub doSum {
	my %param = %{$_[0]};
	$RRDS_DIR	= $param{dir_src};
	$GRPRRDS_DIR	= $param{dir_des};
	my $url		= $param{url_grp};

	my $groups = MM::HostGroup::getGroups({'url' =>$url,
			'type'=>'array'});
	foreach (@$groups) {
		&makeGroup($_);
	}
}

1;
