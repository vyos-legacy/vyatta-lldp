#!/usr/bin/perl
#
# Module: vyatta-config-lldp.pl
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
# Description: Script to configure lldpd
# 
# **** End License ****
#

use Getopt::Long;
use POSIX;
use File::Basename;

use warnings;
use strict;

my $daemon   = '/usr/sbin/lldpd';
my $pid_file = '/var/run/lldpd.pid';
my $chroot_dir = '/var/run/lldpd';

sub is_running {
    if (-f $pid_file) {
	my $pid = `cat $pid_file`;
	chomp $pid;
	my $ps = `ps -p $pid -o comm=`;

	if (defined($ps) && $ps ne "") {
	    return 1;
	} 
    }
    return 0;
}

sub vyatta_enable_lldp {

    print "Starting lldpd...\n";

    my ($cmd, $rc) = ('', '');
    
    if (! -e $chroot_dir) {
        mkdir $chroot_dir;
    }
    if (is_running()) {
        print "Error: lldpd already running.\n";
        exit 1;
    }

    $cmd = "$daemon -v -c -f -e -s -m4";
    $rc = system($cmd);

    exit $rc;
}

sub vyatta_disable_lldp {
    my ($intf) = @_;
    print "Stopping lldpd...\n";

    if (! is_running()) {
        print "Warning: lldpd not running.\n";
        exit 0;
    }

    my $pid = `cat $pid_file`;
    chomp $pid;
    my $rc = system("kill $pid");

    exit $rc;
}


#
# main
#

my ($action);

GetOptions("action=s"    => \$action,
) or usage();

die "Must define action\n" if ! defined $action;


vyatta_enable_lldp()  if $action eq 'enable';

vyatta_disable_lldp() if $action eq 'disable';

exit 1;

# end of file
