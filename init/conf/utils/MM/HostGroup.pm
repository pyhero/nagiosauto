#!/usr/bin/perl -w
#
# $Id: HostGroup.pm 96 2008-09-11 14:25:30Z kaili $
# mm system assistant tools
# summary squid group
#
package MM::HostGroup;

use strict;
use XML::Simple;
use Data::Dumper;

#use File::Basename;
#my $DIR =  dirname $0;
#require "$DIR/libRRD.pl";
#require "$DIR/libMMCommon.pl";
use MM::Basic;

#
# return groups like [{'name'=>'page1.a.sohu.com', 'ips'=>['61.135.131.1', '61.15.131.2']}]
#
sub getGroups {
	my %param = %{$_[0]};
#	my $type = $_[0] || '';
	my $url = $param{'url'};
	my $type = (exists($param{'type'}))? $param{'type'} : '';
	my ($content, $error);
#	$url="http://ctm.no.sohu.com/infosys/getgroup.php";
	(0==MM::Basic::fetchFile( $url, \$content, \$error)) || die("Fetchfile error: $error");

	my $xml=XMLin($content);
	my $groups=$xml->{'group'};
	my ($group, $ipgroup, $ip, @ips);
	my $groups_ret;
	foreach $group (keys %$groups) {
		$ipgroup = $groups->{$group}->{'ip'};
		undef @ips;
		# $ipgroup will be an element itself rather then a "ARRAY" ref
		# when $ipgroup has only one element
		if( ref($ipgroup) eq "ARRAY" ) {
			foreach $ip (@$ipgroup) {
				# prefer private ip, if no private, use public
				push @ips, $ip->{'pri'} || $ip->{'pub'};
			}
		} elsif( ref($ipgroup) eq "HASH" ) {
			push @ips, $ipgroup->{'pri'} || $ip->{'pub'};
		} else {
			next;
		}
		if($type eq 'hash') {
			$groups_ret->{$group} = [@ips];
		} else {
			push @$groups_ret, {name=>$group, ips=>[@ips]};
		}
	}
	return $groups_ret;
}

1;
