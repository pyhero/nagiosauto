#!/usr/bin/perl -w
# MM XML-RPC Server library

package RPCdeps;

use strict;

use Exporter 'import';
our @EXPORT = qw($DIR_NAGIOS $DIR_PLUGINS $DIR_INFO $DIR_PERFDATA $DIR_RRDS _getRRDdata);
use RRDs;
use Parallel::ForkManager;

our $DIR_NAGIOS = "/opt/sohu/nagios";
our $DIR_PLUGINS = "$DIR_NAGIOS/libexec-sohu";
our $DIR_INFO = "$DIR_NAGIOS/info";
our $DIR_PERFDATA = "$DIR_NAGIOS/pnp/share/perfdata";
our $DIR_RRDS = "$DIR_NAGIOS/RRDdb";

# Retrieve specific data values stored in $_[0] and return a hash
# Optional $_[1] indicates the timestamp, if absent, take the last one as default.
sub _getRRDdata {
    my $fn = $_[0];
    my $past = $_[1];
    my ($info, $last, $start, $names, $data);
    my $result;
    $info = RRDs::info($fn);
    $last = $info->{'last_update'};
    if (defined($past) || time() - $last <= 10 * $info->{'step'}) {
        ($start, undef, $names, $data) = RRDs::fetch($fn, 'AVERAGE', '-s', defined($past)?$past - 1:$last - $info->{'step'}, '-e', defined($past)?$past:$last);
        if (defined($start)) {
            $result->{'timestamp'} = $start;
        }
        my $cnt = 0;
        foreach my $name (@$names) {
            $result->{$name} = $data->[0][$cnt++];
        }
    } else {
        $result = "RRD tooooooooold!";
    }
    return $result;
}

1;
