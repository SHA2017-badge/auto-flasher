#!/bin/bash

set -e

if [ $# -ne 1 ]; then
	echo "Usage: $0 <usb-device>" >&2
	echo >&2
	echo "  # $0 /dev/ttyUSB0 -- will flash USB0" >&2
	echo >&2
	exit 1
fi

dev="$1"

esptool_path=./esptool
esptool="$esptool_path/esptool.py"

esptool_opts="--chip esp32 --port $dev --baud 921600 --before default_reset --after hard_reset"

flash_opts="-z --flash_mode dio --flash_freq 40m --flash_size detect"

# NOTE: these offsets have to match partitions.csv!
flash_part1=" 0x1000  ./firmware/bootloader.bin"
flash_part2="0x10000  ./firmware/sha2017-badge.bin"
flash_part3=" 0x8000  ./firmware/partitions.bin"

echo "=== waiting for device '$dev' ==="
while [ ! -r $dev ]; do
	sleep 1
done

echo "=== erasing flash ==="
python $esptool $esptool_opts erase_flash

echo "=== flashing firmware ==="
python $esptool $esptool_opts write_flash $flash_opts $flash_part1 $flash_part2 $flash_part3

echo "=== waiting until device is removed ==="
while [ -e $dev ]; do
	sleep 1
done
