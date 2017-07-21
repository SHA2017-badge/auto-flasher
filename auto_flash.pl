#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw/ sleep time /;

unless ( @ARGV == 1 ) {
	die "Usage: $0 <usb-device>\n".
		"\n".
		"  # $0 /dev/ttyUSB0 -- will flash USB0\n".
		"\n";
}

my $clear_string = `clear`;

my $dev = shift;

my $esptool_path = './esptool';
my $esptool = "$esptool_path/esptool.py";

my $esptool_opts="--chip esp32 --port $dev --baud 921600 --before default_reset --after hard_reset";

my $flash_opts="-z --flash_mode dio --flash_freq 40m --flash_size detect";

# NOTE: these offsets have to match partitions.csv!
my @flash_parts = qw(
     0x1000  ./firmware/bootloader.bin
    0x10000  ./firmware/sha2017-badge.bin
   0x191000  ./firmware/locfd.zip
     0x8000  ./firmware/partitions-$size.bin
);

print "\033[44m";
print $clear_string;
print "=== waiting for device '$dev' ===\n";
while ( ! -r $dev ) {
	sleep 0.1;
}

my $t_start = time();

print "\033[41m";
print $clear_string;
print "=== request flash size ===\n";
my $res = `python $esptool $esptool_opts flash_id`;
print $res;
my $size;
if ($res =~ /Detected flash size: (\d+MB)/) {
	$size = $1;
}

print "=== erasing flash ===\n";
system("python $esptool $esptool_opts erase_flash");
my $t_erase_done = time();

print "=== flashing firmware ===\n";
my $flash_parts = "@flash_parts";
$flash_parts =~ s/\$size\b/$size/g;
system("python $esptool $esptool_opts write_flash $flash_opts $flash_parts");

# do an extra sleep to give the OS some time to recreate the device
# after reboot.
sleep 1;
my $t_flash_done = time();

printf "Stats: erase=%.3fs flash=%.3fs total=%.3fs\n",
	$t_erase_done - $t_start, $t_flash_done - $t_erase_done,
	$t_flash_done - $t_start;

print "\033[42m";
print $clear_string;
print "=== waiting until device is removed ===\n";
while ( -e $dev ) {
	sleep 0.1;
}
