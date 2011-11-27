obj-m += sycamore.o

sycamore-objs := sycamore_usb_serial.o cp210x-sycamore.o

.PHONY: all clean

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install_dep:
	./ins_m.sh

