obj-m += cp210x.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
install:
	modprobe usbserial
	insmod ./cp210x.ko

remove:
	rmmod cp210x.ko

install_dep:
	./ins_m.sh

