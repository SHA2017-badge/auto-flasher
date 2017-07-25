#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw/ sleep /;

print "=== Creating .zip for locfd  ===\n";
system("bash updateZip.sh") and die "Failed to build locfd.zip: $?\n";

print "=== Collecting badge tty devices ===\n";
my %seen;

while (1) {
	if (opendir(my $dir, '/dev')) {
		while (defined (my $file = readdir($dir))) {
			next unless $file =~ /\Atty_badge_/;
			my $dev = "/dev/$file";
			if ( -r $dev && ! $seen{$dev}++ ) {
				my $short = substr($file, 10);
				print("found $dev ($short)\n");
				system("screen -X -S auto-flasher screen -t '$short' bash -c 'while true; do ./auto_flash.pl --skip-mkzip $dev; done'");
			}
		}
		closedir($dir);
	}

	sleep 0.1;
}
