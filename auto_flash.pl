#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'portable';
use Getopt::Long;
use Time::HiRes qw/ sleep time /;

sub usage {
	die "Usage: $0 [--no-remove] [--skip-mkzip] <usb-device>\n".
		"\n".
		"  # $0 /dev/ttyUSB0 -- will flash USB0\n".
		"\n";
}

sub dev_major {
	my $rdev = shift;
	return
		(($rdev & 0xfff00) >> 8) |
		(($rdev & 0xfffff00000000000) >> 32);
}

sub dev_minor {
	my $rdev = shift;
	return
		($rdev & 0xff) |
		(($rdev & 0xffffff00000) >> 12);
}

sub slurp {
	my $file = shift;
	open my $f, '<', $file or die "open('$file'): $!\n";
	local $/;
	my $data = <$f>;
	close $f;
	return $data;
}

# iterate over all files in /dev/bus/usb
my %dev_info;
sub collect_usb {
	my $path = shift;
	opendir(my $dh, $path) or die "opendir('$path'): $!\n";
	while (defined (my $f = readdir($dh))) {
		next if $f eq '.' || $f eq '..';
		my $file = $path.'/'.$f;
		if (-d $file) {
			collect_usb($file);

		} elsif (-c $file) {
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
				$atime,$mtime,$ctime,$blksize,$blocks)
				= stat($file);

			my $rdev_path = '/sys/dev/char/'.dev_major($rdev).':'.dev_minor($rdev);

			my $f_idVendor = $rdev_path.'/idVendor';
			next unless -r $f_idVendor;
			my $f_idProduct = $rdev_path.'/idProduct';
			next unless -r $f_idProduct;
			my $f_product = $rdev_path.'/product';
			next unless -r $f_product;

			my $idVendor = slurp($f_idVendor);
			chomp $idVendor;
			next unless $idVendor eq '10c4';
			my $idProduct = slurp($f_idProduct);
			chomp $idProduct;
			next unless $idProduct eq 'ea60';
			my $product = slurp($f_product);
			chomp $product;

			opendir(my $dh, $rdev_path) or die "opendir('$rdev_path'): $!\n";
			while (defined (my $f = readdir($dh))) {
				my $file2 = $rdev_path.'/'.$f;
				if ($f =~ /\A\d/ && -d $file2) {
					opendir(my $dh, $file2) or die "opendir('$file2'): $!\n";
					while (defined (my $f = readdir($dh))) {
						my $file3 = $file2.'/'.$f;
						if ($f =~ /\AttyUSB\d*\z/ && -d $file2) {
							$dev_info{'/dev/'.$f} = {
								bus_id  => $file,
								product => $product,
							};
						}
					}
				}
			}
		}
	}
	closedir($dh);
}

sub dev_info {
	my $dev = shift;

	$dev = '/dev/'.readlink($dev) if -l $dev;

	%dev_info = ();
	collect_usb('/dev/bus/usb');

	my $dev_info = $dev_info{$dev} // die "could not find any information about device '$dev'.\n";

	return $dev_info;
}
my $no_remove = 0;
my $skip_mkzip = 0;
GetOptions(
	"no-remove"  => \$no_remove,
	"skip-mkzip" => \$skip_mkzip,
) or usage;

usage unless @ARGV == 1;

my $dev = shift;

my $esptool_path = './esptool';
my $esptool = "$esptool_path/esptool.py";

my $esptool_opts="--chip esp32 --port $dev --baud 921600 --before default_reset --after hard_reset";

my $flash_opts="-z --flash_mode dio --flash_freq 80m --flash_size detect";

# NOTE: these offsets have to match partitions.csv!
my @flash_parts = qw(
     0x1000  ./firmware/bootloader.bin
    0x10000  ./firmware/sha2017-badge.bin
   0x191000  ./firmware/locfd-$type.zip
     0x8000  ./firmware/partitions-$size.bin
);

unless ( $skip_mkzip ) {
	print "=== Creating .zip for locfd  ===\n";
	system("bash updateZip.sh") and die "Failed to build locfd.zip: $?\n";
}

print "=== waiting for device '$dev' ===\n";
while ( ! -r $dev ) {
	sleep 0.1;
}

use Data::Dumper;
my $dev_info = dev_info($dev);
print "device info:\n".Dumper($dev_info);

my $t_start = time();

my $size;
if (defined $ENV{ESP_FLASH_SIZE} && $ENV{ESP_FLASH_SIZE} =~ /\A\d+MB\z/) {
	$size = $ENV{ESP_FLASH_SIZE};
} else {
	print "=== request flash size ===\n";
	my $res = `python $esptool $esptool_opts flash_id`;
	die "Failed to request flash size: $?\n" if $?;
	print $res;
	if ($res =~ /Detected flash size: (\d+MB)/) {
		$size = $1;
	} else {
		die "Failed to determine flash size.\n";
	}
}
my $type;
$type = 'sl' if $dev_info->{'product'} eq 'CP2102 USB to UART Bridge Controller';
$type = 'n' if $dev_info->{'product'} eq 'CP2102N USB to UART Bridge Controller';
die "unknown product '$dev_info->{'product'}'.\n" unless defined $type;

print "size='$size', type='$type'\n";

print "=== erasing flash ===\n";
system("python $esptool $esptool_opts erase_flash") and die "Failed to erase flash: $?\n";
my $t_erase_done = time();

print "=== flashing firmware ===\n";
my $flash_parts = "@flash_parts";
$flash_parts =~ s/\$size\b/$size/g;
$flash_parts =~ s/\$type\b/$type/g;
system("python $esptool $esptool_opts write_flash $flash_opts $flash_parts") and die "failed to flash images: $?\n";

# do an extra sleep to give the OS some time to recreate the device
# after reboot.
sleep 1;
my $t_flash_done = time();

printf "Stats: erase=%.3fs flash=%.3fs total=%.3fs\n",
	$t_erase_done - $t_start, $t_flash_done - $t_erase_done,
	$t_flash_done - $t_start;
exit 0 if $no_remove;

print "=== waiting until device is removed ===\n";
while ( -e $dev ) {
	sleep 0.1;
}
