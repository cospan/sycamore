#obj-m += sycamore_usb_serial.o

obj-m += cp210x-sycamore.o

csrcs := sycamore_usb_serial.c
cobjs := $(csrcs:%.c=%.o)

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install_dep:
	./ins_m.sh

