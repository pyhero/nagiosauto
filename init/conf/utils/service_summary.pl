#! /usr/bin/perl -w
#
# $Id: service_summary.pl 73 2008-07-31 15:28:53Z kaili $
# service group RRD summarization
# Kaili <kaili@sohu-inc.com>
#

use strict;
use File::Basename;
use lib dirname $0;

use DBI;
use MM::RRD;
use Data::Dumper;

#my $DIR =  dirname $0;
#require "$DIR/libRRD.pl";

# define parameters here
my $BASE_DIR  = "/opt/nagios";
my $RRDS_DIR = $BASE_DIR . "/RRDdb/";
my $SERVICES_DIR = $BASE_DIR . "/RRDdb/services_sum/";


my $dsn = "DBI:mysql:devdb:localhost";
my $username = "root";
my $password = "";
my ($dbh, $sth, $hashref);

$dbh = DBI->connect($dsn, $username, $password, { RaiseError => 1 });
my %services_tree = &getServicesTree;
my %services_def = &getServicesDef;
#my %service_groups;# = &getServicesRRDs;
my %service_groups = &getServicesRRDs;
$dbh->disconnect();

############# BASIC RRD PARAM ##########
my %param;
my @ds = qw(input output);
$param{'step_new'} = 60;
#if "one rrd" doesn't exsit, creating starttime is offset time before now
$param{'offset_new'} = 1800;
$param{'heartbeat'} = 3*$param{'step_new'};
#########################################

############# SMALL SERVICE SUM ##########
foreach (keys %service_groups) {

	undef $param{'sfiles'};
	$param{'dfile'} = $SERVICES_DIR . "$_.rrd";
	my $files = $service_groups{$_};
	push @{$param{'sfiles'}}, {ds=>[@ds], files=>$files};

	print "\n#-----------\nProcessing SID $_ with files:\n";
	print join "\n", @$files;
	print "\n";
	MM::RRD::RRDn2one(%param);
}
#########################################

############## PER IDC F SERVICE SUM ###############
my ($cid, $fid, $sid, $hash_fss, $ary_sss);
while( ($cid, $hash_fss) = each %services_tree) {
	reset %$hash_fss;
	while( ($fid, $ary_sss) = each %$hash_fss) {
		push @$ary_sss, $fid; # fid it self is a child serve
		$param{'dfile'} = $SERVICES_DIR . "0_${fid}_${cid}.rrd";
		foreach (@$ary_sss) {
			$_ = $SERVICES_DIR . $_ . "_$cid.rrd";
		}
		undef $param{'sfiles'};
		push @{$param{'sfiles'}}, {ds=>[@ds], files=>$ary_sss};
		MM::RRD::RRDn2one(%param);
	}
}
####################################################


##########################
## SUPPORT ROUTINE BELOW #
##########################

sub in_array {
	my ($arr,$search_for) = @_;
	return grep {$search_for eq $_} @$arr;
}

# get services defination
# {serviceid => fatherid, serviceid+>fatherid, ...}
sub getServicesDef {
	my %services_def;
	$sth = $dbh->prepare("SELECT * FROM s_service");
	$sth->execute();
	my ($sid, $fid, $sname);
	while($hashref = $sth->fetchrow_hashref()) {
		$services_def{$hashref->{serviceid}} = $hashref->{fatherid};
	}
	$sth->finish();
	return %services_def;
}

# per IDC subnets grouping
# %idc = {"idc_id1" => "'61.135.131', '61.135.132', ...", "idc_id2"=>"'220.181.26','220.181.20'", ... }
sub getIdcIps {
	my ($cid, @subnets, %idc);
	$sth = $dbh->prepare("SELECT * FROM ip_idc");
	$sth->execute();
	while($hashref = $sth->fetchrow_hashref()) {
		$cid = $hashref->{cid};
		@subnets = split /\//, $hashref->{start};
		foreach (@subnets) {
			$_ = "'$_'";
		}
		$idc{$cid} = join ",",@subnets;
	}
	$sth->finish();
	return %idc;
}

# get idc, fserve, sserve tree
# {idc1=>{fid1=>[sid1,sid2,...], fid2=>[sid5,sid6,...], ...}, idc2=>... }
#
sub getServicesTree {
	my %services_tree;
	my $cid;
	my $ary_ref;
	my %idc = &getIdcIps;
	foreach $cid (keys(%idc)) {
		if(!exists $services_tree{$cid}) {
			$services_tree{$cid}={};
		}
		my $sql = "SELECT b.serviceid, b.fatherid, b.name"
			." FROM ip_info a, s_service b"
			." WHERE b.serviceid = a.sid"
			." AND SUBSTRING_INDEX(a.ip,'.',3) IN ($idc{$cid}) GROUP BY serviceid";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		my ($sid, $fid);
		while($hashref = $sth->fetchrow_hashref()) {
			$sid = $hashref->{serviceid};
			$fid = $hashref->{fatherid};
			if($fid==0) {
				if(!exists $services_tree{$cid}{$sid}) {
					$services_tree{$cid}{$sid}=[];
				}
			} else {
				if(!exists $services_tree{$cid}{$fid}) {
					$services_tree{$cid}{$fid}=[];
				}
				$ary_ref = $services_tree{$cid}{$fid};
				push @$ary_ref, $sid;
			}
		}
		$sth->finish();
	}
	return %services_tree;
}

# get services group and rrd file info
# return { 'group1'=>[file1, file2, ..], 'group2'=>[file3, file5], ...}
sub getServicesRRDs {
	my %service_groups;

	my $cid;
	my %idc = &getIdcIps;
	foreach $cid (keys(%idc)) {
		my $sql = "SELECT a.sid,a.ip,b.swip,b.swint FROM ip_info a, arpinfo b"
			." WHERE a.ip=b.ipaddr"
			." AND SUBSTRING_INDEX(a.ip, '.', 3) IN (" . $idc{$cid} . ")";
#		$sth = $dbh->prepare("SELECT a.sid,a.ip,b.swip,b.swint FROM ip_info a, arpinfo b WHERE a.ip=b.ipaddr");
		$sth = $dbh->prepare($sql);
		$sth->execute();

		my ($sid, $file, $ary_ref);
		while($hashref = $sth->fetchrow_hashref()) {
			$sid = $hashref->{sid} . "_$cid";
			if(!$hashref->{swip} || !$hashref->{swint}) {
				next;
			}
			$file = $RRDS_DIR . $hashref->{swip} . "_" . $hashref->{swint} . ".rrd";
			if(exists $service_groups{$sid}) {
				$ary_ref = $service_groups{$sid};
				if(!&in_array($ary_ref, $file)) {
					push @$ary_ref, $file;
				}
			} else {
				$service_groups{$sid} = [$file];
			}
		}
		$sth->finish();
	}
	return %service_groups;
}
