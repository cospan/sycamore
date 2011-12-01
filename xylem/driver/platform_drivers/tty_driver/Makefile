obj-m += sycamore_tty.o

sycamore_tty-objs := tty_driver.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
install_dep:
	./ins_m.sh

