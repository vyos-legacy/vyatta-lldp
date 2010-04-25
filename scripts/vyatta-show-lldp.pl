#!/usr/bin/perl
#
# Module: vyatta-show-lldp.pl
# 
# **** License ****
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# This code was originally developed by Vyatta, Inc.
# Portions created by Vyatta are Copyright (C) 2010 Vyatta, Inc.
# All Rights Reserved.
# 
# Author: Stig Thormodsrud
# Date: April 2010
# Description: Script to show lldp records
# 
# **** End License ****
#

use Getopt::Long;
use POSIX;
use XML::Simple;
use Data::Dumper;

use warnings;
use strict;

sub get_cap {
    my ($ref) = @_;

    my $cap = "";
    my $index = 0;
    while (1) {
        last if ! defined $ref->{'chassis'}[0]->{'capability'}[$index];
        my $cap_ref = $ref->{'chassis'}[0]->{'capability'}[$index];
        if (defined $cap_ref) {
            if ($cap_ref->{'type'} eq 'Router') {
                $cap .= 'R' if $cap_ref->{'enabled'} eq 'on';
            }
            if ($cap_ref->{'type'} eq 'Bridge') {
                $cap .= 'B' if $cap_ref->{'enabled'} eq 'on';
            }
            if ($cap_ref->{'type'} eq 'Wlan') {
                $cap .= 'W' if $cap_ref->{'enabled'} eq 'on';
            }
            if ($cap_ref->{'type'} eq 'Station') {
                $cap .= 'S' if $cap_ref->{'enabled'} eq 'on';
            }
            if ($cap_ref->{'type'} eq 'Repeater') {
                $cap .= 'r' if $cap_ref->{'enabled'} eq 'on';
            }
            if ($cap_ref->{'type'} eq 'Telephone') {
                $cap .= 'T' if $cap_ref->{'enabled'} eq 'on';
            }
            if ($cap_ref->{'type'} eq 'Docsis') {
                $cap .= 'D' if $cap_ref->{'enabled'} eq 'on';
            }
            if ($cap_ref->{'type'} eq 'Other') {
                $cap .= 'O' if $cap_ref->{'enabled'} eq 'on';
            }
        }
        $index++;
    }
    return $cap;
}

sub show_lldp_neighbor {
    my ($intf, $all) = @_;

    my $xs = XML::Simple->new(KeyAttr => "interface", ForceArray => 1, 
                              KeepRoot => 0);
    my ($xml, $data);

    $intf = '' if ! defined $intf;

    $xml = `/usr/sbin/lldpctl -f xml $intf`;
    $data = $xs->XMLin($xml);

    print "Capability Codes: R - Router, B - Bridge, W - Wlan " .
          "r - Repeater, S - Station\n";
    print "                  D - Docsis, T - Telephone, O - Other\n\n";

    my $format = "%-25s %-6s %-5s  %-5s %-20s %-8s\n";
    printf($format, 'Device ID', 'Local', 'Proto', 'Cap', 
           'Platform', 'Port ID');
    printf($format, '---------', '-----', '-----', '---', 
           '--------', '-------');

    my $index = 0;
    while (1) {
        last if ! defined $data->{interface}[$index];
        my $rec_ref = $data->{interface}[$index];

        my $via = $rec_ref->{'via'};
        $via = '?' if ! $via;

        my $local_intf = $rec_ref->{'name'};
        $local_intf = '?' if ! $local_intf;

        my $name = $rec_ref->{'chassis'}[0]->{'name'}[0]->{'content'};
        chomp $name;
        if (! defined $name or $name eq 'Not received') {
            $name = $rec_ref->{'chassis'}[0]->{'id'}[0]->{'content'};
        }
        $name = 'unknown' if ! $name;
       
        my $cap = get_cap($rec_ref);
        $cap = '?' if ! $cap;

        my $version = '';
        my $plat = $rec_ref->{'chassis'}[0]->{'descr'}[0]->{'content'};
        if (defined $plat) {
            if ($plat =~ /(.*)\s+running on\s(.*)/) {
                $plat = $1;
                $version = $2;
            } else {
                $plat = substr($plat, 0, 20);
            }
        } else {
            $plat = 'unknown';
        }

        my $port = $rec_ref->{'port'}[0]->{'id'}[0]->{'content'};
        my $type = $rec_ref->{'port'}[0]->{'id'}[0]->{'type'};
        if (defined $type and $type ne 'ifname') {
            $port = $rec_ref->{'port'}[0]->{'descr'}[0]->{'content'};
        }
        $port = 'unknown' if ! $port;
        if ($port =~ /^Ethernet(.*)$/) {
            $port = "Eth$1";
        }
        if ($port =~ /^GigabitEthernet(.*)$/) {
            $port = "GigE$1";
        }

        printf($format, $name, $local_intf, $via, $cap, $plat, $port);
        #print Dumper($rec_ref);

        $index++;
    }
    exit 0;
}

sub show_lldp_neighbor_detail {
    my ($device_id, $all) = @_;

    system("/usr/sbin/lldpctl");
    exit 0;
}



#
# main
#

my ($intf, $device, $action, $all);

GetOptions("intf=s"      => \$intf,
           "device=s"    => \$device,
	   "action=s"    => \$action,
           "all=s"       => \$all
) or usage();

die "Must define action\n" if ! defined $action;


show_lldp_neighbor($intf, $all)          if $action eq 'show-neighbor';

show_lldp_neighbor_detail($device, $all) if $action eq 'show-neighbor-detail';


exit 1;

# end of file
