#!/usr/bin/perl -w
#
# Copyright(c) 2008 Huaping Huang <huapinghuang@sohu-inc.com>
# SNMP Func Lib
# $Id$
#
package MM::SNMP;

use strict;
use Net::SNMP;

# snmpDate2String: convert an SNMP DateAndTime octetstring to human readable string
# $octetstr: octet strings such as what hrSystemDate returns
sub snmpDate2String
{
    my $date = $_[0];
    $date = substr($date, 2, 22);
    return sprintf("%d-%d-%d,%d:%d:%d.%d,%s%d:%d", unpack("n C6 a C2", pack("H*", $date)));
}

# snmpv3CreateSession: Create an SNMPv3 session
# $device: IP address of the object host
# $username: username for snmpv3 authentication, default is "nomgmtuser"
# $authkey: authkey for snmpv3 authentication
# $privkey: privkey for snmpv3 authentication
sub snmpv3CreateSession
{
    my ($device, $username, $authkey, $privkey) = @_;

    # "Malformed UTF-8 Characters" bugfix
    $authkey = substr($authkey, 0, 34);
    $privkey = substr($privkey, 0, 34);
    my ($session, $error) = Net::SNMP->session(
        -hostname     => $device,
        -port         => 161,
        -nonblocking  => 1,
        -version      => 3,
        -timeout      => 10,
        -retries      => 3,
        -username     => $username || "nomgmtuser",
        -authkey      => $authkey,
        -authprotocol => "md5",
        -privkey      => $privkey,
        -privprotocol => "des",
    );
    return ($session, $error);
}

# squidsnmpCreateSession: Create an SNMPv1/v2c session for checking squid
# $device: IP address of the object host
# $community: username for snmpv1/v2c authentication, default is "s0h5sguid"
# $version: "1" or "2c"
# $port: squid snmp daemon port
sub squidsnmpCreateSession
{
    my ($device, $community, $port, $version) = @_;
    my ($session, $error) = Net::SNMP->session(
        -hostname     => $device,
        -port         => $port,
        -nonblocking  => 1,
        -version      => $version || 1,
        -timeout      => 10,
        -retries      => 3,
        -community    => $community || "s0h5sguid",
    );
    return ($session, $error);
}
# snmpGetScalar: get the value of SNMP scalar variables
# $session: a Net::SNMP session object
# $result: where the VarBindList stores, usually a scalar variable but depends on how your callback works
# $varbindlist: a reference to the list of the OIDs to query, each one has a ".0" suffix
sub snmpGetScalar
{
    my ($session, $result, $varbindlist) = @_;
    my $status = $session->get_request(
        -callback    => [\&callback, $result],
        -varbindlist => $varbindlist,
    );
    return $status;
}

# snmpGetTable: get the value of an SNMP table
# $session: a Net::SNMP session object
# $result: where the VarBindList stores, usually a scalar variable but depends on how your callback works
# $baseoid: base OID of the entire table
sub snmpGetTable
{
    my ($session, $result, $baseoid) = @_;
    my $status = $session->get_table(
        -callback       => [\&callback, $result],
        -baseoid        => $baseoid,
        -maxrepetitions => 10,
    );
    return $status;
}

sub callback
{
    my ($session, $table) = @_;
    # store the VarBindList as a reference in $$table
    $$table = $session->var_bind_list();
}

1;
