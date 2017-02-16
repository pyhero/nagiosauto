#!/usr/bin/perl -w
#
# Copyright(c) 2009 Huaping Huang <huapinghuang@sohu-inc.com>
# XML Func Lib
# $Id$
#
package MM::XML;

use strict;
use IO::Socket;
use Data::Serializer;

# xmlRetrieveConfig: Retrieve XML format configurations of an SNMP session
# $device: IP address of the object host
sub xmlRetrieveConfig
{
   my ($device, $service) = @_;
   my $serializer = Data::Serializer->new();
   my $sock = IO::Socket::INET->new(PeerPort => 52431, PeerAddr => "127.0.0.1", Proto => "udp");
   my $res;
   print $sock "$device $service";
   $sock->recv($res, 4096, 0);
   $res = $serializer->deserialize($res);
#   $serializer->DESTROY();
   return $res;
}

1;
