#!/usr/bin/perl -w
# host related RPC methods

package host;

use strict;

use Data::Serializer;
use RPCdeps;

my $serializer;

sub _purgeInfo {
    my $ip = $_[0];
    my $ipslash = $ip; $ipslash =~ s/\./\//g;
    my $file = "$DIR_INFO/host/$ipslash/ipinfo";
    if (-r $file) {
        my $tmp = $serializer->retrieve($file);
        qx($DIR_PLUGINS/check_host_info -H $tmp->{'host'});
    } else {
        qx($DIR_PLUGINS/check_host_info -H $ip);
    }
}

sub _parseIPInfo {
    my $ip = $_[0];
    my $ipslash = $ip; $ipslash =~ s/\./\//g;
    my $file = "$DIR_INFO/host/$ipslash/ipinfo";
    my $result;
    $result = $serializer->retrieve($file) if (-r $file);
    if (defined($result)) {
        $result->{$ip}->{'host'} = $result->{'host'};
        $result->{$ip}->{'timestamp'} = $result->{'timestamp'};
    }
    return $result->{$ip};
}

sub getInfo { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my ($iplist, $purge) = @_;
    if (!defined($iplist)) {
        return {};
    }
    if (!ref($iplist)) {
        $iplist = [$iplist];
    }
    my $result;
    $serializer = Data::Serializer->new();
    if (defined($purge) && $purge) {
        *CORE::GLOBAL::exit = sub {CORE::exit();};
        my $pm = new Parallel::ForkManager(@$iplist);
        foreach my $ip (@$iplist) {
            $pm->start() and next;
            &_purgeInfo($ip);
            $pm->finish();
        }
        *CORE::GLOBAL::exit = sub {ModPerl::Util::exit();};
    }
    foreach my $ip (@$iplist) {
        my $ipslash = $ip; $ipslash =~ s/\./\//g;
        my $file = "$DIR_INFO/host/$ipslash/hostinfo";
        $result->{$ip} = $serializer->retrieve($file) if (-r $file);
    }
    $serializer->DESTROY();
    return $result;
}

sub getIPInfo { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my ($iplist, $purge) = @_;
    if (!defined($iplist)) {
        return {};
    }
    if (!ref($iplist)) {
        $iplist = [$iplist];
    }
    my $result;
    $serializer = Data::Serializer->new();
    if (defined($purge) && $purge) {
       *CORE::GLOBAL::exit = sub {CORE::exit();};
        my $pm = new Parallel::ForkManager(@$iplist);
        foreach my $ip (@$iplist) {
            $pm->start() and next;
            &_purgeInfo($ip);
            $pm->finish();
        }
        *CORE::GLOBAL::exit = sub {ModPerl::Util::exit();};
    }
    foreach my $ip (@$iplist) {
        $result->{$ip} = &_parseIPInfo($ip);
        delete($result->{$ip}) if (!$result->{$ip});
    }
    $serializer->DESTROY();
    return $result;
}

sub getTraffic { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my ($iplist, $time) = @_;
    if (!defined($iplist)) {
        return {};
    }
    if (!ref($iplist)) {
        $iplist = [$iplist];
    }
    $time = undef if (defined($time) && $time == -1);
    my $result;
    $serializer = Data::Serializer->new();
    foreach my $ip (@$iplist) {
        my $tmp = &_parseIPInfo($ip);
        if (defined($tmp)) {
            my $ifDescr = $tmp->{'ifDescr'};
            my $host = $tmp->{'host'};
            my $fn = "$DIR_PERFDATA/$host/Iface-$ifDescr.rrd";
            if (-r $fn) {
                $result->{$ip} = &_getRRDdata($fn, $time);
            }
            if (defined($result->{$ip})) {
                $result->{$ip}->{'host'} = $host;
                $result->{$ip}->{'ifSpeed'} = $ifDescr;
            }
        } 
    }   
    $serializer->DESTROY();
    return $result;
}

sub getTrafficGraph { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my ($iplist, $start, $end) = @_;
    if (!defined($iplist)) {
        return {};
    }
    if (!ref($iplist)) {
        $iplist = [$iplist];
    }
    $start = undef if (defined($start) && $start == -1);
    $end = undef if (defined($end) && $end == -1);
    if (!defined($end)) {
        $end = time();
    }
    if (!defined($start)) {
        $start = $end - 24 * 60 * 60;
    }
    if ($start > $end) {
        return {};
    }
    my $result;
    $serializer = Data::Serializer->new();
    foreach my $ip (@$iplist) {
        my $tmp = &_parseIPInfo($ip);
        if (defined($tmp)) {
            my $host = $tmp->{'host'};
            my $ifDescr = $tmp->{'ifDescr'};
            $result->{$ip}->{'URL'} = "http://mm.no.sohu.com/nagios/pnp/index.php?host=$host&srv=Iface-$ifDescr&start=$start&end=$end&display=image";
        }
    }
    $serializer->DESTROY();
    return $result;
}

1;
