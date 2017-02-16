#!/usr/bin/perl -w
# squid related RPC methods

package squid;

use strict;

use Data::Serializer;
use RPCdeps;

my $serializer;

sub _purgeInfo {
    my $ip = $_[0];
    my $ipslash = $ip; $ipslash =~ s/\./\//g;
    my $file = "$DIR_INFO/squid/$ipslash/squidinfo";
    if (-r $file) {
        my $tmp = $serializer->retrieve($file);
        qx($DIR_PLUGINS/check_squid_info -H $tmp->{'privIP'});
    } else {
        qx($DIR_PLUGINS/check_squid_info -H $ip);
    }
    $file = "$DIR_INFO/squid/$ipslash/squid2info";
    if (-r $file) {
        my $tmp = $serializer->retrieve($file);
        qx($DIR_PLUGINS/check_squid2_info -H $tmp->{'privIP'});
    } else {
        qx($DIR_PLUGINS/check_squid2_info -H $ip);
    }
}

sub _parseInfo {
    my ($ip, $purge) = @_;
    my $ipslash = $ip; $ipslash =~ s/\./\//g;
    my $file = "$DIR_INFO/squid/$ipslash/squidinfo";
    my ($ret, $tmp, $result);
    $tmp->{'squid1'} = $serializer->retrieve($file) if (-r $file);
    $file = "$DIR_INFO/squid/$ipslash/squid2info";
    $tmp->{'squid2'} = $serializer->retrieve($file) if (-r $file);
    if (defined($tmp->{'squid1'}) && $ip eq $tmp->{'squid1'}->{'privIP'} || defined($tmp->{'squid2'}) && $ip eq $tmp->{'squid2'}->{'
privIP'}) {
        $result = $tmp;
        $ret = 0;
    } elsif (defined($tmp->{'squid1'}) && $ip eq $tmp->{'squid1'}->{'pubIP'}) {
        $result->{'squid1'} = $tmp->{'squid1'};
        $ret = 1;
    } elsif (defined($tmp->{'squid2'}) && $ip eq $tmp->{'squid2'}->{'pubIP'}) {
        $result->{'squid2'} = $tmp->{'squid2'};
        $ret = 2;
    } else {
        $ret = -1;
    }
    return ($ret, $result); 
}

sub getData { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
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
        my ($flg, $tmp) = &_parseInfo($ip);
        my ($file, $privIP);
        if ($flg == 0 || $flg == 1 || $flg == -1) {
            $privIP = $tmp->{'squid1'}->{'privIP'};
            $file = "$DIR_PERFDATA/$privIP/Squid.rrd";
            if (-r $file) {
                my $ret = &_getRRDdata($file, $time);
                if (defined($ret)) {
                    $result->{$ip}->{'squid1'} = $ret;
                }
            }
        }
        if ($flg == 0 || $flg == 2 || $flg == -1) {
            $privIP = $tmp->{'squid2'}->{'privIP'};
            $file = "$DIR_PERFDATA/$privIP/Squid2.rrd";
            if (-r $file) {
                my $ret = &_getRRDdata($file, $time);
                if (defined($ret)) {
                    $result->{$ip}->{'squid2'} = $ret;
                }
            }
        }
    }
    $serializer->DESTROY();
    return $result;
}

sub getGraph { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
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
    my @legend = qw(CPU HR MEM OBJ UNLNK RQ TF);
    $serializer = Data::Serializer->new();
    foreach my $ip (@$iplist) {
        my ($flg, $tmp) = &_parseInfo($ip);
        my ($file, $privIP);
        if ($flg == 0 || $flg == 1 || $flg == -1) {
            $privIP = $tmp->{'squid1'}->{'privIP'};
            $file = "$DIR_PERFDATA/$privIP/Squid.rrd";
            if (-r $file) {
                for (my $i = 1; $i <= @legend; $i++) {
                    $result->{$ip}->{'squid1'}->{$legend[$i - 1]} = "http://mm.no.sohu.com/nagios/pnp/index.php?host=$privIP&srv=Squid&source=$i&start=$start&end=$end&display=image";
                }
            }
        }
        if ($flg == 0 || $flg == 2 || $flg == -1) {
            $privIP = $tmp->{'squid2'}->{'privIP'};
            $file = "$DIR_PERFDATA/$privIP/Squid2.rrd";
            if (-r $file) {
                for (my $i = 1; $i <= @legend; $i++) {
                    $result->{$ip}->{'squid2'}->{$legend[$i - 1]} = "http://mm.no.sohu.com/nagios/pnp/index.php?host=$privIP&srv=Squid2&source=$i&start=$start&end=$end&display=image";
                }
            }
        }
    }
    $serializer->DESTROY();
    return $result;
}

sub getGrpData { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my ($domainlist, $time) = @_;
    if (!defined($domainlist)) {
        return {};
    }
    if (!ref($domainlist)) {
        $domainlist = [$domainlist];
    }
    $time = undef if (defined($time) && $time == -1);
    my $result;
    foreach my $domain (@$domainlist) {
        my $file = "$DIR_RRDS/squid_sum_new/$domain.rrd";
        next if (!-r $file);
        $result->{$domain} = &_getRRDdata($file, $time);
    }
    return $result;
}

sub getGrpGraph { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my ($domainlist, $start, $end) = @_;
    if (!defined($domainlist)) {
        return {};
    }
    if (!ref($domainlist)) {
        $domainlist = [$domainlist];
    }
    $start = undef if (defined($start) && $start == -1);
    $end = undef if (defined($end) && $end == -1);
    if (!defined($end)) {
        $end = time();
    }
    if (!defined($start)) {
        $start = $end - 86400;
    }
    if ($start > $end) {
        return {};
    }
    my $result;
    foreach my $domain (@$domainlist) {
        my $file = "$DIR_RRDS/squid_sum_new/$domain.rrd";
        next if (!-r $file);
        $result->{$domain}->{"OBJ"} = "http://mm.no.sohu.com/cgi-bin/groupGrapher.cgi?domain=$domain&type=objects&s=$start&e=$end";
        $result->{$domain}->{"RQ"} = "http://mm.no.sohu.com/cgi-bin/groupGrapher.cgi?domain=$domain&type=requests&s=$start&e=$end";
        $result->{$domain}->{"TF"} = "http://mm.no.sohu.com/cgi-bin/groupGrapher.cgi?domain=$domain&type=traffic&s=$start&e=$end";
    }
    return $result;
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
        (undef, $result->{$ip}) = &_parseInfo($ip);
        delete($result->{$ip}) if (!$result->{$ip});
    }
    $serializer->DESTROY();
    return $result;
}

1;
