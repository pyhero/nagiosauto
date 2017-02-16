#!/usr/bin/perl
# 
# $Id: Basic.pm 96 2008-09-11 14:25:30Z kaili $
# Tech-NO MM System Common Library
# Keyn Li <kaili@sohu-inc.com>
#

use strict;
use Data::Dumper;
use WWW::Curl::Easy;

package MM::Basic;

sub fetchFile {
	my ($url, $response_body, $error) = @_;
	# Setting the options
	my $curl = new WWW::Curl::Easy;

	$curl->setopt(WWW::Curl::Easy::CURLOPT_TIMEOUT, 5);
	# Redirecting the default STDOUT target for header contents, to
	# an anonymous temporary file
	open(my $fileh, '+>', undef);
	$curl->setopt(WWW::Curl::Easy::CURLOPT_HEADERDATA,$fileh);

	$curl->setopt(WWW::Curl::Easy::CURLOPT_HEADER,0);
	$curl->setopt(WWW::Curl::Easy::CURLOPT_URL, $url);
	open (my $fileb, ">", $response_body);
	$curl->setopt(WWW::Curl::Easy::CURLOPT_WRITEDATA,$fileb);

	# Starts the actual request
	my $retcode = $curl->perform;

	# Looking at the results...
	if ($retcode == 0) {
		my $response_code = $curl->getinfo(WWW::Curl::Easy::CURLINFO_HTTP_CODE);
		if($response_code==200) {
			return 0; 
		} else {
			$$error = "HTTP return $response_code";
			return $response_code;
		}
	} else {
		$$error = $curl->strerror($retcode);
		return $retcode;
	}
}

# return file content by URL
sub getFile {
	my ($url) = @_;
	my ($content, $error);
	(0==fetchFile( $url, \$content, \$error)) || die("Fetchfile error: $error");
	return $content;
}

1;
