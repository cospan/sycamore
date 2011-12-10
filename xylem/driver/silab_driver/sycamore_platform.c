//sycamore_platform.c
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include "sycamore_platform.h"
#include "sycamore_ioctl.h"



//static struct platform_device sycamore_tty ={
//	.name = "sycamore_tty",
//	.id = -1,
//};
/*
static struct gpio_led gpio_leds[] = {
	{
		.name = "sycamore::led0",
		.default_trigger = "sycamore_go",
		.gpio = 150,
	},
};

static struct gpio_led_platform_data gpio_led_info = {
	.leds = gpio_leds,
	.num_leds = ARRAY_SIZE(gpio_leds),
};
static struct platform_device leds_gpio = {
	.name = "leds-gpio",
	.id = -1,
	.dev = {
		.platform_data = &gpio_led_info,
	},
};

*/
static ssize_t show_test(struct device *dev,
			  struct device_attribute *attr,
			  char *buf){

//	sycamore_t *sycamore = dev_get_drvdata(dev);
	return sprintf (buf, "hi\r\n");

}

static struct device_attribute dev_attr_test = {
	.attr = {
		.name = "test_name",
		.mode = 0444 },
	.show = show_test 
};

static struct attribute *platform_attributes[] = {
	&dev_attr_test.attr,
	NULL
};

int generate_platform_devices(sycamore_t *sycamore){
	sycamore->platform_attribute_group.attrs = platform_attributes;	
	return 0;
}


int sycamore_ioctl(struct tty_struct *tty, unsigned int cmd, unsigned long arg){

	printk ("Entered ioctl");
/*
	sycamore_t *sycamore = NULL;
	struct usb_serial_port *port = tty->driver_data;
	sycamore = (sycamore_t *) dev_get_drvdata(&port->data);
	
//	dbg("%s entered", __func__);

	if (sycamore->port_lock){
//		dbg("%s sycamore is locked by another device", __func__);
	}

//	dbg("%s entered", __func__);
	switch (cmd) {
		case(PING_SYCAMORE): 
			return 1;
		case(READ_DRT):
			return 2;
		case(GET_DRT_SIZE):
			return 3;
	}
*/
	return 0;
}
int sycamore_attach(sycamore_t *sycamore){

	//initialize the sycamore structure
	int result = 0;
	//sycamore = (sycamore_t *) kzalloc(sizeof(sycamore_t), GFP_KERNEL);
	sycamore->platform_device = NULL;
	sycamore->port_lock = 0;
	sycamore->size_of_drt = 0;
	sycamore->drt	= NULL;
	sycamore->pdev = NULL;
	sycamore->ioctl = sycamore_ioctl;

	//generate the platform bus
	sycamore->platform_device = platform_device_alloc(SYCAMORE_BUS_NAME, -1);
	if (!sycamore->platform_device){
		//dbg("%s Error, couldn't allocate space for sycamore->platform_device", __func__);
		return -ENOMEM;
	}

	//XXX: This may require a bus number afterwards to indicate multiple sycamore buses
	platform_set_drvdata(sycamore->platform_device, sycamore);

	//now we need to add the bus to system
	result = platform_device_add(sycamore->platform_device);

	if (result != 0){
		goto fail_platform_device;
	}

	//create a all the sub items sysfs bus entry

	generate_platform_devices(sycamore);
	result = sysfs_create_group(&sycamore->platform_device->dev.kobj, &sycamore->platform_attribute_group);

	if (result != 0){
		goto fail_sysfs;
	}



	//create a platform device
	//platform_device_register(&sycamore_tty);
	sycamore->pdev = platform_device_register_simple("sycamore_tty", -1, NULL, 0);

	//end create platform device
	return 0;

fail_sysfs:
	platform_device_del(sycamore->platform_device);
fail_platform_device:
	platform_device_put(sycamore->platform_device);
	return result;

}
void sycamore_disconnect(sycamore_t *sycamore){
	
	if (sycamore->size_of_drt > 0) {
		//DRT has a string
		kfree(sycamore->drt);
		sycamore->size_of_drt = 0;
	}

	//remove the group
	platform_device_unregister(sycamore->pdev);


	//remove the platform device

//	platform_device_unregister(&sycamore_tty);
	//end remove the platform device
	platform_device_del(sycamore->platform_device);
	platform_device_put(sycamore->platform_device);
}


