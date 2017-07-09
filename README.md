# auto-flasher


submodules
----------

Install the esptool with:

	git submodule init
	git submodule update


install udev rule
-----------------

Add this udev-rule to avoid device-name changes during flashing.

	cp udev-rules.d-badge.rules /etc/udev/rules.d/badge.rules
	/etc/init.d/udev restart


run auto-flasher
----------------

Add the right firmware in ./firmware/ (if not provided in the git
repository itself)

Then start this for every usb-device-path:

	while true; do ./auto_flash.sh /dev/tty_badge_1.2.4; done

Added a screenrc for convenience.

	screen -c ./screenrc
