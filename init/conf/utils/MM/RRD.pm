#!/usr/bin/perl
#
# Copyright(c) 2008 Keyn Li <kaili@sohu-inc.com>
# RRD function lib
# $Id: RRD.pm 239 2009-07-06 04:16:07Z huapinghuang $
# 
package MM::RRD;

use strict;
use RRDs;
use Data::Dumper;

my $DEBUG=1;

# round a number or number list
sub round {
	my @ar=@$_;
	foreach (@ar) {
		if($_ && /^\d+\.?\d*$/) {
			$_ = sprintf("%.0f", $_);
		}
	}
	return @ar;
}

# stuff undef value with 'U'
# return 1 if found undef
sub undefStuff {
	my $un=0;
	foreach (@{$_[0]}) {
		if(!defined $_) {
			$_='U';
			$un=1;
		}
	}
	return $un;
}

# handle rrd error
sub RRDerror {
	my $ERROR;
	$ERROR = RRDs::error;
	die "RRD $_[0] ERROR: $ERROR\n" if $ERROR;
}

# get last value of appointed ds
sub RRDgetLast {
	my ($dir, $host, $service, $ds, $time, $value) = @_;
	my $file = "$dir/$host/$service-$ds.tmp.rrd";
	my $STEP = 60;
	my @DS = ("DS:$ds:DERIVE:300:0:U");
	my @RRA = ("RRA:AVERAGE:0.5:1:60");
	my $error;

	if(! -d $dir) {
		$MM::error = "Directory $dir do not exist";
		return "ERR";
	}
	mkdir "$dir/$host";
	if(! -e $file) {
		RRDs::create( $file, @DS, @RRA,
				"--start=".($time-1),
				"--step", $STEP );
	}

	RRDs::update($file, "$time:$value");
	if ( $error = RRDs::error ) {
		return $error;
	}
	
        my $lastupdate = RRDs::last($file) - $STEP;
        my (undef, undef, undef, $data) = RRDs::fetch($file, "AVERAGE", "-s $lastupdate");

	if(defined($data->[0]->[0])) {
		return sprintf("%f",$data->[0]->[0]);
	} else {
		return "UNKN";
	}
}

# summarize n rrdfile to one
sub RRDn2one {
	my (%param) = @_;
	my $heartbeat = $param{'heartbeat'}?$param{'heartbeat'}:60*3; #default hb=180
	my $dfile = $param{'dfile'};
	my $sfiles = $param{'sfiles'};
	# treate NaN as zero? default yes.
	my $UN0 = (exists $param{'UN0'}) ? $param{'UN0'} : 1;

	my (@DEF, @CDEF, @XPORT);
	# current earliest "end" of source rrds
	# initial NOW
	my $end_earliest=time;
	my $end_get; # 'lastupdate' got from rrd
	# def major and minor index,
	my ($index, $i) = ('a', 0);
	my $filegroup;
	my $ds;
	my $cdef;
	foreach $filegroup(@$sfiles) { # filegroup loop
		foreach $ds (@{$filegroup->{'ds'}}) { # ds loop
			$i=0;
			$cdef="CDEF:$index=";
			foreach (@{$filegroup->{'files'}}) { # files loop
				# rrd file must exist
				if(! -e $_) {
					print "File $_ do not exists, skip it\n";
					next;
				}
				$end_get = RRDs::last($_);
				# Skip half-day inactive rrd 
				if($end_earliest - $end_get > 43200) {
					print "A long time inactive file $_ found, skip it\n";
					next;
				}
				if ($end_earliest>$end_get) {
					$end_earliest = $end_get;
				}
				push @DEF,"DEF:$index$i=$_:$ds:AVERAGE";
				if($UN0) {
					$cdef .= "$index$i,UN,0,$index$i,IF,";
				} else {
					$cdef .= "$index$i,";
				}
				$i++;
			}
			# $i=0 means no valid rrd found
			if($i<1) {
				next;
			} elsif($i>1) {
				foreach (1..($i-1)) {
					$cdef .= "+,";
				}
			}

			$cdef =~ s/,$//;
			push @CDEF, $cdef;

			push @XPORT, "XPORT:$index:$ds";
			$index++;
		}
	}
	if(!@DEF) {
		print "NONE VALID RRD FOUND. DFile=$dfile. SKIP.\n";
		return;
	}

	# Create destination rrd file if it does not exist
	if(!-e $dfile) {
		my $step_new = $param{'step_new'}?$param{'step_new'}:60;
		my $offset_new = $param{'offset_new'}?$param{'offset_new'}:600;
		my @RRA=(
				"RRA:AVERAGE:0.5:1:10080",
				"RRA:AVERAGE:0.5:5:8928",
				"RRA:AVERAGE:0.5:30:4464",
				"RRA:AVERAGE:0.5:120:2196",
				"RRA:AVERAGE:0.5:1440:366",
				"RRA:AVERAGE:0.5:10080:262",
				"RRA:MAX:0.5:5:8928",
				"RRA:MAX:0.5:30:4464",
				"RRA:MAX:0.5:120:2196",
				"RRA:MAX:0.5:1440:366",
				"RRA:MAX:0.5:10080:262",
				"RRA:MIN:0.5:5:8928",
				"RRA:MIN:0.5:30:4464",
				"RRA:MIN:0.5:120:2196",
				"RRA:MIN:0.5:1440:366",
				"RRA:MIN:0.5:10080:262"
			);
		my @DS;
		foreach (@$sfiles) {
			foreach (@{$_->{'ds'}}) {
				push @DS,"DS:$_:GAUGE:$heartbeat:0:U";
			}
		}
		RRDs::create($dfile, @DS, @RRA,
				"--start=".(time-$offset_new),
				"--step=$step_new");
		RRDerror("CREATE");
	}

	# Only data after lastupdated needed
	my $lastupdate=RRDs::last($dfile);
	RRDerror("LAST");
	if($lastupdate >= $end_earliest) {
		print "start($lastupdate) greater than end($end_earliest), unactive rrd data found. SKIP\n";
		return -2;
	}
	if($DEBUG) {
		print "\n";
		print join " \\\n", @DEF;
		print " \\\n";
		print join " \\\n", @CDEF;
		print " \\\n";
		print join " \\\n", @XPORT;
		print " \n";
	}

	my ($start,$end,$step,undef,$legend,$data) =
		RRDs::xport("-m 600","-s $lastupdate", "-e $end_earliest", @DEF, @CDEF, @XPORT);
	RRDerror("XPORT");
	my $template = join ":", @$legend;
	my $current;
	my $updatetime=$start;
	my @dataupdate;
	my $datavalid;

	foreach (@$data) {
		# if UN0, data must be older than $heartbeat time
		if($UN0 && (($end-$updatetime)>$heartbeat)) {
			$datavalid = 1;
		# if not UN0, data must not be NaN unless it's older than $heartbeat time
		} elsif (!$UN0 && ( !undefStuff(\@$_)|| (($end-$updatetime)>$heartbeat) ) ) {
			$datavalid = 1;
		} else {
			$datavalid = 0;
		}
		if($datavalid) {
			$current=join ":", &round(@$_);
			push @dataupdate, "$updatetime:$current";
		}
		$updatetime += $step;
		next;
	}
	if($DEBUG) {
		print join " \\\n", @dataupdate;
	}
	foreach (@dataupdate) {
		RRDs::update($dfile,
				"--template", $template, $_
			    );
		RRDerror("UPDATE");
	}
}

1;
