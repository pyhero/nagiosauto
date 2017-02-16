#!/usr/bin/perl -w

package system;
use strict;
use XML::Simple;
my $xml = '
<opt>
  <method name="system.listMethods">
    <signature>
      <anon>array</anon>
    </signature>
    <help>This method returns a list of the methods the server has, by name.</help>
  </method>
  <method name="system.methodHelp">
    <signature>
      <anon>string</anon>
      <anon>string</anon>
    </signature>
    <help>This method returns a text description of a particular method.</help>
  </method>
  <method name="system.methodSignature"> 
    <signature>
      <anon>array</anon>
      <anon>string</anon>
    </signature>
    <help>This method returns a description of the argument format a particular method expects.</help>
  </method>
  <method name="host.getInfo"> 
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>boolean</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>boolean</anon>
    </signature>
    <help>This method returns information of the host owning the specified IP(s).</help>
  </method>
  <method name="host.getIPInfo">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>boolean</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>boolean</anon>
    </signature>
    <help>This method returns information of the interface owning the specified IP(s).</help>
  </method>
  <method name="host.getTraffic">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
    </signature>
    <help>This method returns the traffic data of the interface owning the specified IP(s).</help>
  </method>
  <method name="host.getTrafficGraph">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
      <anon>int</anon>
    </signature>
    <help>This method returns the traffic graph URL of the interface owning the specified IP(s).</help>
  </method>
  <method name="squid.getData">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
    </signature>
    <help>This method returns squid statistics data of the corresponding IP(s).</help>
  </method>
  <method name="squid.getGraph">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
      <anon>int</anon>
    </signature>
    <help>This method returns squid statistics graph URLs of the corresponding IP(s).</help>
  </method>
  <method name="squid.getGrpData">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
    </signature>
    <help>This method returns cache group statistics data of the corresponding domain(s).</help>
  </method>
  <method name="squid.getGrpGraph">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>int</anon>
      <anon>int</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>int</anon>
      <anon>int</anon>
    </signature>
    <help>This method returns cache group statistics graph URLs of the corresponding domain(s).</help>
  </method>
  <method name="squid.getInfo">
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>string</anon>
      <anon>boolean</anon>
    </signature>
    <signature>
      <anon>struct</anon>
      <anon>array</anon>
      <anon>boolean</anon>
    </signature>
    <help>This method returns squid information of the corresponding IP(s).</help>
  </method>
</opt>
';



my $methods = XMLin($xml, ForceArray => ['anon', 'method']);

sub listMethods {
    return [sort keys %{$methods->{'method'}}];
}

sub methodSignature { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my $method = $_[0];
    return $methods->{'method'}->{"$method"}->{'signature'};
}

sub methodHelp { shift() if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my $method = $_[0];
    return $methods->{'method'}->{"$method"}->{'help'};
}

1;
