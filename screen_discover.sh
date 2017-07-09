#!/usr/bin/env bash

set -e

declare -A seen=()

while true; do
	for dev in /dev/tty_badge_*; do
		if [ -r $dev ]; then
			if [ "${seen[$dev]}" != 1 ]; then
				seen[$dev]=1
				short="${dev:15}"
				echo "found $dev ($short)"
				screen -X -S auto-flasher screen -t "$short" bash -c "while true; do ./auto_flash.sh $dev; done"
			fi
		fi
	done
	sleep 1
done
