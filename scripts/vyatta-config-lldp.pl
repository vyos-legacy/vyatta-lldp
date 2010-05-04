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

use lib '/opt/vyatta/share/perl5';
use Vyatta::Config;

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

sub get_vyatta_platform {
    
    my $platform = 'Vyatta Router';
    my $cmd;
    
    $cmd = 'sudo dmidecode -s chassis-manufacturer';
    my $manu = `$cmd`;
    chomp $manu;
    if (defined $manu and $manu eq 'Vyatta') {
        $cmd = 'sudo dmidecode -s system-product-name';
        my $product = `$cmd`;
        chomp $product;
        if (defined $product) {
            return "Vyatta $product";
        }
    } else {
        $cmd = 'sudo dmidecode -s processor-version';
        my $product = `$cmd`;
        chomp $product;
        if (defined $product) {
            return "Vyatta Router";
        }        
    }

    return $platform;
}

sub get_vyatta_version {
    
    my $version = 'vyatta unknown';

    my $filename = '/opt/vyatta/etc/version';
    open(my $FILE, '<', $filename) or die "Error: read [$filename] $!";

    while (<$FILE>) {
        if (/^Description:\s+(.*)$/) {
            close($FILE);
            return $1;
        }
    }
    close($FILE);
    return $version;
}

sub get_options {
    
    my $opts = '';
    my $config = new Vyatta::Config;

    $config->setLevel('service lldp'); 
    $opts .= '-c ' if $config->exists('enable-cdp');
    $opts .= '-e ' if $config->exists('enable-edp');
    $opts .= '-f ' if $config->exists('enable-fdp');
    $opts .= '-s ' if $config->exists('enable-sonmp');
    $opts .= '-v ' if $config->exists('enable-vlan');

    my $addr = $config->returnValue('management-address');
    if (defined $addr) {
        $opts .= "-m $addr ";
    }
    return $opts;
}

sub vyatta_enable_lldp {

    print "Starting lldpd...\n";

    my ($cmd, $rc) = ('', '');
    
    if (! -e $chroot_dir) {
        mkdir $chroot_dir;
    }
    if (is_running()) {
        vyatta_disable_lldp();
    }

    my $plat = get_vyatta_platform();
    my $ver  = get_vyatta_version();
    my $opts = get_options();
    my $descr = "$plat running on $ver";

    $cmd = "$daemon $opts -M4 -S \"$descr\" ";
    $rc = system($cmd);

    return $rc;
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

    return $rc;
}


#
# main
#

my ($action);

GetOptions("action=s"    => \$action,
) or usage();

die "Must define action\n" if ! defined $action;

my $rc = 1;
$rc =  vyatta_enable_lldp()  if $action eq 'enable';
$rc =  vyatta_disable_lldp() if $action eq 'disable';

exit $rc;

# end of file
