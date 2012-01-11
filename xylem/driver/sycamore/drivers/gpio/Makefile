obj-m += sycamore_gpio.o

sycamore_gpio-objs := gpio_driver.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
install:
	insmod ./sycamore_gpio.ko
remove:
	rmmod sycamore_gpio

