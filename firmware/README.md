This directory should contain 3 files:

- bootloader.bin    -- the bootloader from build/bootloader/bootloader.bin
- sha2017-badge.bin -- the firmware from build/sha2017-badge-test.bin
- partitions.bin    -- the partition-table from build/partitions.bin
- fatfs-locfd.bin   -- the initial user filesystem mounted as /

```
./esptool/esptool.py --chip esp32 --port /dev/cu.SLAB_USBtoUART --baud 115200 --before default_reset --after hard_reset read_flash 0xb20000 5111808 firmware/fatfs-locfd.bin
```
