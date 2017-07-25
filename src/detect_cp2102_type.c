#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <assert.h>

#include <linux/usbdevice_fs.h>

#ifdef DEBUG
void
hexdump(unsigned char *buf, int size)
{
	int pos;
	for (pos = 0; pos < size; pos += 16)
	{
		printf("[%04x]  ", pos);
		int i;
		for (i=0; (i<16) && (pos+i < size); i++)
			printf("%02x ", buf[pos+i]);
		for (; i<16; i++)
			printf("   ");
		printf(" ");
		for (i=0; (i<16) && (pos+i < size); i++)
		{
			char ch = buf[pos+i];
			if (ch < ' ' || ch > 0x7e)
				ch = '.';
			printf("%c", ch);
		}
		printf("\n");
	}
}
#endif // DEBUG

int
main(int argc, char *argv[])
{
	if (argc != 2) {
		fprintf(stderr, "Usage: %s /dev/bus/usb/001/006\n", argv[0]);
		return 1;
	}

	char *devfile = argv[1];
	int fd = open(devfile, O_RDWR);
	if (fd == -1) {
		perror("open()");
		return 1;
	}

	uint32_t caps = 0;

	int err = ioctl(fd, USBDEVFS_GET_CAPABILITIES, &caps);
	if (err != 0) {
		perror("ioctl()");
		return 1;
	}

#ifdef DEBUG
	printf("caps = 0x%08x\n", caps);
#endif // DEBUG

	/*
	struct usbdevfs_disconnect_claim dc = {
		.interface = 0,
		.driver    = "usbfs",
		.flags     = USBDEVFS_DISCONNECT_CLAIM_EXCEPT_DRIVER,
	};
	err = ioctl(fd, USBDEVFS_DISCONNECT_CLAIM, &dc);
	if (err != 0) {
		perror("ioctl()");
		return 1;
	}
	*/

	uint8_t buf[8+128] = { 0 };
	uint8_t *ptr = buf;
	*ptr++ = 0x80 | 0x40; // request type
	*ptr++ = 0xff; // request
	*ptr++ = 0x0a; // lo(descr)
	*ptr++ = 0x37; // hi(descr)
	*ptr++ = 0; // lo(index)
	*ptr++ = 0; // hi(index)
	*ptr++ = 128; // lo(length)
	*ptr++ = 0; // hi(length)
	ptr = &ptr[128];
	size_t size = ((intptr_t) ptr) - ((intptr_t) buf);
	struct usbdevfs_urb urb = {
		.usercontext   = NULL,
		.type          = USBDEVFS_URB_TYPE_CONTROL,
		.endpoint      = 0,
		.buffer        = buf,
		.buffer_length = size,
	};
	err = ioctl(fd, USBDEVFS_SUBMITURB, &urb);
	if (err != 0) {
		perror("ioctl()");
		return 1;
	}

	struct usbdevfs_urb *urb_res = NULL;
	err = ioctl(fd, USBDEVFS_REAPURBNDELAY, &urb_res);
	while ( err == -1 && errno == EAGAIN ) {
		usleep(1000);
		err = ioctl(fd, USBDEVFS_REAPURBNDELAY, &urb_res);
	}
	if (err != 0) {
		perror("ioctl()");
		return 1;
	}

	if (urb_res != NULL) {
#ifdef DEBUG
		printf("received urb.\n");
		hexdump((void *) urb_res, sizeof(struct usbdevfs_urb));
#endif // DEBUG

		if (urb_res->buffer != NULL) {
			uint8_t *buf = urb_res->buffer;
			int buflen = urb_res->buffer_length;

#ifdef DEBUG
			printf("buffer contains data.\n");
			hexdump(buf, buflen);
#endif // DEBUG

			if (buflen == 8 + 128 && buf[6] == 0x80 && buf[7] == 0x00) {
				printf("detected original CP2102\n");
				return 10;
			} else if (buflen == 8 + 1 && buf[6] == 0x01 && buf[7] == 0x00) {
				printf("detected fake CP2102\n");
				return 11;
			}
		}
	}

	printf("unknown chip.\n");
	return 0;
}
