# auto-flasher

Note:
All commands are prefixed with '$' for normal user commands and
with '#' for commands as root.


submodules
----------

Install the esptool with:

	$ git submodule update --init --recursive


install udev rule
-----------------

Add this udev-rule to avoid device-name changes during flashing.

	# cp udev-rules.d-badge.rules /etc/udev/rules.d/badge.rules

	# /etc/init.d/udev restart


fix permissions
---------------

Give the user (here 'basvs') the right permissions for opening /dev/ttyUSBx:

	$ ls -al /dev/ttyUSB0
	crw-rw---- 1 root dialout 188, 0 jul 20 15:44 /dev/ttyUSB0

	# adduser basvs dialout
	Adding user `basvs' to group `dialout' ...
	Adding user basvs to group dialout
	Done.

	# id basvs
	uid=1000(basvs) gid=1000(basvs) groups=1000(basvs),20(dialout)


The current user then doesn't have access to the dialout group yet. You will
have to login again or use the command 'newgrp'.

    $ id
	uid=1000(basvs) gid=1000(basvs) groups=1000(basvs)

	$ newgrp dialout

	$ id
	uid=1000(basvs) gid=1000(basvs) groups=1000(basvs),20(dialout)


run auto-flasher
----------------

Add the right firmware in ./firmware/ (if not provided in the git
repository itself)

Then start this for every usb-device-path:

	$ while true; do ./auto_flash.pl /dev/tty_badge_1.2.4; done

Or simply use this screen config. It uses an extra script to detect
all /dev/tty\_badge\_\* character devices.

	$ screen -c ./screenrc

