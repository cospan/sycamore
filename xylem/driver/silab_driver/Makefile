obj-m += sycamore.o

sycamore-objs := uart_protocol.o cp210x-sycamore.o ../sycamore/sycamore_bus.o ../sycamore/sycamore_device.o
#devices
sycamore-objs += ../sycamore/devices/drt/drt.o ../sycamore/devices/gpio/gpio_device.o

#devices

.PHONY: all clean

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	rm ../sycamore/*.o
	rm ../sycamore/.*.o.cmd
	rm ../sycamore/devices/drt/*.o
	rm ../sycamore/devices/drt/.*.o.cmd
	rm ../sycamore/devices/gpio/*.o
	rm ../sycamore/devices/gpio/.*.o.cmd




install:
	modprobe usbserial
	insmod ./sycamore.ko debug=1

remove:
	rmmod sycamore

install_dep:
	./ins_m.sh

