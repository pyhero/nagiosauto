#!/usr/bin/perl -w
#
# $Id: ConfigGen.pm 188 2009-02-27 09:18:43Z huapinghuang $
# mm system assistant tools
# gen host group config
#
package MM::ConfigGen;

use strict;

use XML::Simple;
use Data::Dumper;
use MM::HostGroup;
use MM::Basic;

sub genconf {
	my %param = %{$_[0]};
	my $CFG_FILE	= $param{cfg_file};
	my $URL_GRP	= $param{url_grp};
	my $DIR_OUTPUT	= $param{dir_output};
	my $ADM_DEFAULT	= $param{adm_default};
	my $SER_MAP	= (defined $param{ser_map}) ? $param{ser_map} : {};
	my $SUF_STRIP	= (defined $param{suf_strip}) ? $param{suf_strip} : '';
#	print Dumper $SER_MAP;

	chdir $DIR_OUTPUT;

	my $gcared = XMLin( MM::Basic::getFile($CFG_FILE) );
	$gcared = $gcared->{group};

	my $groups = MM::HostGroup::getGroups({'url' =>$URL_GRP,
						'type'=>'hash'});

	my @ips;
	my ($g, $gname);
	my ($h, $hname);
	my ($admins, $services);
	my $service;
	my $str_output;
	foreach $g (keys %$gcared) {
		# $gtype: public or private
		my $gtype = $gcared->{$g}->{type} || '';
		if(exists $gcared->{$g}->{admins}) {
			$admins = join ",", @{$gcared->{$g}->{admins}};
		} else {
			$admins = $ADM_DEFAULT;
		}
		if(exists $groups->{$g}) {
#			$gname = gen_objname($g);
			$gname = ($gtype)?"$gtype-$g":$g;
			$gname =~ s/$SUF_STRIP//;
			$str_output = "
define hostgroup {
	hostgroup_name		$gname
	alias			$gname
}
define host {
	use			generic-cache-host
	hostgroups		$gname
	contact_groups		$admins
	name			$gname-host
	register		0
}
";
			$services  = $gcared->{$g}->{services};
			if(ref $services ne "ARRAY" ){
				$services = [$services];
			}
			foreach (@$services) {
				$service = get_service($_, $SER_MAP);
				# squid service will be specially treated below, temporary
				if($_ eq "squid") {
					next;
				}
			$str_output .= "
define service {
	use			generic-$service-service
	hostgroup_name		$gname
}
";
			}
#		@ips = array_uniq(@{$groups->{$g}});
			@ips = sort @{$groups->{$g}};
			my %count;
			foreach $h (@ips){
				$count{$h}++;
				$hname = gen_objname($h);

				# host define only once
				if(!($count{$h}>1)) {
						$str_output .= "
define host {
	use			$gname-host
	host_name		$hname
	alias			$h
	address			$h
}
";
				}

				# for squidX issue, temporary
				if(in_array($services, "squid")) {
					$service = "squid";
					if($count{$h}>1) {
						$service .= $count{$h};
					}
					$service = get_service($service, $SER_MAP);
					$str_output .= "
define service {
	use			generic-$service-service
	host_name		$hname
}
";
				}
			}
			open FILE, ">", "$gname.cfg";
			print FILE $str_output;
			close FILE;
		} else {
			print "$g do not exists.\n";
		}
	}
}

sub get_service {
	my ($sevice, $map) = @_;
	return (defined $map->{$sevice}) ? $map->{$sevice} : $sevice;
}

sub gen_objname {
	$_ = $_[0];
#add by zyk for replace - to . format in configure files of hosts and services etc....
#s#\.#-#g;
	return $_;
}
sub array_uniq {
	my %saw;
	return grep(!$saw{$_}++, @_);
}

sub in_array {
	my ($arr,$search_for) = @_;
	return grep {$search_for eq $_} @$arr;
}

1;
