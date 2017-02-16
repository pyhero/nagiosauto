#!/usr/bin/perl
## check_http.pl
## Copyright (c) 2008, Oliver Wittenburg  <oliver@wiburg.de>
##
## This program is free software: you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation, either version 3 of the License, or (at your option) any later
## version.
##
## This program is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along with
## this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# A new check_http Nagios Plugin with the following requirement(s):
# - able to use multiple conditions for warning or critical status
# example
# ok: 200 ok and contents "abc" or "def"
# warning: if one gets a 200 OK and content "xyz"
# critical: 500 Server error
#
#This plugin is _no_ replacement of the default check_http plugin.
#
#It provides some functionality which the standard check_http doesn\\\'t have.
#
#The standard check_http plugins doesn\\\'t allow to set warning or critical status depending on the page content. check_http can only return OK or Critical if a string (or regular expression) matches.
#
#Using this plugin you can set multiple conditions for warning and/or critical status.
#
#Example:
#Combine regex and http codes:
#./check_http.pl -H host.domain.com -u /test.html -W \'Wwarn\' -W \'Mmissing\' -C \'Ccrit\' -c 500 -c 404
#
#
#Capital options (-W and -C) indicate regex patterns which should match the page content.
#The lowercase options are reserved for the HTTP Codes (regex can be used too).
#
#There still many open tasks like user authentication support, configurable redirect support ...
#Updates will follow.
#
#
#Usage:
#-H
#-u (default: /)
#-p (default: 80)
#-s, --ssl
#
#      connection via ssl (default off)
#
#-w
#
#      state=warning, if the specified http code (404, 303, ...) is returned
#
#-c
#
#      state=critical, if the specified http code (404, 303, ...) is returned
#
#-W
#
#      if regex matches against page content -> state = warning
#
#-C
#
#      if regex matches against page content -> state = critical
#
#-h, --help

use HTTP::Request::Common qw(POST);
use strict;
use LWP::UserAgent;
use Getopt::Long;
use Time::HiRes qw( gettimeofday );
use lib "/usr/local/nagios/libexec"  ;
use utils qw(&usage %ERRORS);
use Switch;


# variables/lists
my $cexpr;
my $ccode;
my $protocol;
my $o_url;
my $o_host;
my $o_port;
my $o_ssl;
my @o_criticalHttpCodes;
my @o_criticalExpressions;
my @o_warningHttpCodes;
my @o_warningExpressions;
my $o_help;
my $o_hostname;
my $o_useragent;
my $o_method;
my $o_post_param;
my $o_post_value;
my $request;
my $o_cookie_value;
my $o_content_type;
my $o_maxredir;
my $o_timeout;


# FIXME:
sub help {
    print <<EOT
Usage: \t$0 -H <host> [-u <uri>] [-p <port>] [-s]
        [-w warning HTTP code] [-c critical HTTP code]
        [-W warning content regex] [-C critical content regex]

This plugin tests the HTTP service on the specified host.  The warning and/or
critical conditions can be either the HTTP response code or a regular
expression which matches the HTTP body.

-H, --host <IP or host address>

-u, --url  <URI> (Default: /).

-p, --port <port> (Default: 80).

-s, --ssl <on|off> 
		Attempt SSL connection (Default: off).
		
-A, --useragent <useragent>
		Specify the User Agent header value (Default: "check_http").
		
-n, --hostname <hostname>
		Specify the Host header value (Default is the same as the host address).

-m, --method <(GET|POST)>
		Specify the HTTP request method (Default: GET).

-t, --timeout <timeout_in_seconds>
		Set the timeout for the request in seconds (Default: 10 seconds).
  
-M, --maxredir <number_of_redirects>
		Set the maximum number of redirects to be performed. (Default: 7).
		
-r, --post_param <paramater_name>
		Specify a paramter name for when the selected method is POST.

-v, --post_value <paramater_value>
		Specify a value for when the selected method is POST.
		
-T, --content-type <content_type>

		Set a content type for POST requests (Optiona).
-k, --cookie_value <cookie_value>
		Specify a value for a cookie.

-w, --warningHttpCode <http_response_code>
        Return state=warning, if the specified HTTP  code (404, 303, ...) is returned.

-c, --criticalHttpCode <http_response_code>
        Return state=critical, if the specified HTTP code (404, 303, ...) is returned.

-W, --warningExpression <warning content regex>
		Return state = warning if regex matches against page content.

-C, --criticalExpression <critical content regex>
        Return state = critical if regex matches against page content.
		
The -w, -c, -W and -C options can be specified multiple times.

If -w, -c, -W or -C option are not specified the following rules apply:
        OK:             HTTP Response Code 2xx
        WARNING:        HTTP Response Code 3xx
        CRITICAL:       HTTP Response Code 4xx or 5xx

But without the -w, -c, -W and -C options you would be better off using the standard check_http plugin.

-h, --help
        Prints this help message.
		
EOT
}

# FIXME: timeouts, user, password, follow redirects
Getopt::Long::Configure ("bundling");
GetOptions(
  'u=s'  => \$o_url,    			 'url=s'  				=> \$o_url,
  's=s'  => \$o_ssl,    			 'ssl=s'  				=> \$o_ssl,
  'H=s'  => \$o_host,   			 'host=s' 				=> \$o_host,
  'p=i'  => \$o_port,     			 'port=i' 				=> \$o_port,
  'n=s'  => \$o_hostname, 			 'hostname=s' 			=> \$o_hostname,
  'A=s'  => \$o_useragent, 			 'useragent=s' 			=> \$o_useragent,
  'm=s'  => \$o_method, 			 'method=s' 			=> \$o_method,
  'M=i'  => \$o_maxredir,	 		 'maxredir=i'			=> \$o_maxredir,
  't=i'  => \$o_timeout,	 		 'timeout=i'		 	=> \$o_timeout,
  'r=s'  => \$o_post_param, 		 'post_param=s' 		=> \$o_post_param,
  'v=s'  => \$o_post_value, 		 'post_value=s' 		=> \$o_post_value,
  'k=s'  => \$o_cookie_value, 		 'cookie_value=s'	 	=> \$o_cookie_value,
  'T=s'  => \$o_content_type, 		 'content_type=s'	 	=> \$o_content_type,
  'w=s'  => \@o_warningHttpCodes, 	 'warningHttpCode=s' 	=> \@o_warningHttpCodes,
  'W=s'  => \@o_warningExpressions,  'warningExpression=s' 	=> \@o_warningExpressions,
  'c=s'  => \@o_criticalHttpCodes, 	 'criticalHttpCode=s' 	=> \@o_criticalHttpCodes,
  'C=s'  => \@o_criticalExpressions, 'criticalExpression=s' => \@o_criticalExpressions,
  'h'    => \$o_help,      			 'help'  				=> \$o_help
);
if ($o_help) { help(); exit 0};

# Follwing Parameters have to be set by the user, otherwise exit ...:
if (!$o_host) { help ();
usage("\nError: Host not specified\n\n");
};

# Setting some default values:
# ....
if (!$o_ssl) {$o_ssl = "off"}
if (!$o_port and $o_ssl eq "off" ) {$o_port = 80 };
if (!$o_port and $o_ssl eq "on" ) { $o_port = 443 };
if (!$o_url ) { $o_url = "/" };
if (!$o_hostname ) { $o_hostname = $o_host };
if (!$o_useragent ) { $o_useragent = "check_http" };
if (!$o_method ) { $o_method = "GET" };
if (!$o_post_value ) { $o_post_value = undef };
if (!$o_post_param ) { $o_post_param = undef };
if (!$o_cookie_value ) { $o_cookie_value = undef };
if (!$o_content_type ) { $o_content_type = undef };
if (!$o_maxredir ) {$o_maxredir = 7 };
if (!$o_timeout ) {$o_timeout = 10 };


my $start = gettimeofday();
my $ua = LWP::UserAgent->new();

my $undef = undef;

$ua->agent($o_useragent);
$ua->timeout($o_timeout);
$ua->max_redirect($o_maxredir);

switch ($o_ssl) {
case "off" {$protocol = "http"}
case "on"  {$protocol = "https"}
}


my $url = $protocol . "://" . $o_host . ":" . $o_port . $o_url ;


if ($o_method eq 'GET' )  {$request = HTTP::Request->new('GET', $url );};
if ($o_method eq 'POST' ) {$request = HTTP::Request->new(POST => $url);
$request->content("$o_post_param=" . $o_post_value);}


unless ($o_cookie_value eq $undef){ $request->header('Cookie', $o_cookie_value) };

$request->header('Host', $o_hostname); 


if ($o_method eq 'POST' ) {$request->header('Content-Type', $o_content_type);};
# Get the HTTP Responde Code (200, 404, 500 ...)
my $response = $ua->request($request);

my $code = $response->code();
my $content = $response->content();


my $end = gettimeofday();
my $delta = ($end - $start);


#i Critical?
if (@o_criticalHttpCodes or @o_criticalExpressions) {

  # Test wether a (user-defined) critical HTTP-Code is returned
  foreach $ccode (@o_criticalHttpCodes) {
    if ($code =~ m/$ccode/) {
      # print $response->status_line, "\n";
      print "Status: Critical. Matching critical HTTP Code $code |time=$delta" . "s;;;0\n";
      my $state = "CRITICAL";
      exit $ERRORS{$state};
    }
  }

  # Test wether a (user-defined) critical string can be found in the body
  foreach $cexpr (@o_criticalExpressions) {
    if ($content =~m/$cexpr/) {
      #print "Status: Critical. Matching critical regular expression |time=$delta" . "s;;;0\n";
      print "Status: Critical. " . substr($content, 0, 30) . " |time=$delta" . "s;;;0\n";
      my $state = "CRITICAL";
      exit $ERRORS{$state};
    }
  }
}
else {
  # no critical condition was supplied by user
  if ($code >= 400) {
    print "Status: Critical (" . $response->status_line . ") |time=$delta" . "s;;;0\n";
    my $state = "CRITICAL";
    exit $ERRORS{$state};
  }
}


# Warning?
if (@o_warningHttpCodes or @o_warningExpressions) {
  # Test wether a (user-defined) warning HTTP-Code is returned
  foreach $ccode (@o_warningHttpCodes) {
    if ($code =~ m/$ccode/) {
      # print $response->status_line, "\n";
      print "Status: Warning.  HTTP Code $code |time=$delta" . "s;;;0\n";
      my $state = "WARNING";
      exit $ERRORS{$state};
    }
  }
  # Test wether a (user-defined) warning string can be found in the body
  foreach $cexpr (@o_warningExpressions) {
    if ($content =~m/$cexpr/) {
      print "Status: Warning. Matching warning regular expression |time=$delta" . "s;;;0\n";
      my $state = "WARNING";
      exit $ERRORS{$state};
    }
  }
}
else {
  # no critical condition was supplied by user
  if ($code >= 300) {
    print "Status: WARNING (" . $response->status_line . ") |time=$delta" . "s;;;0\n";
    my $state = "WARNING";
    exit $ERRORS{$state};
  }
}


if ($response->is_success) {
  print "Status: OK |time=$delta" . "s;;;0\n";
}
else {
  print $response->status_line, "\n";
}
