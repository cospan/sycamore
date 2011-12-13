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

void read_data(sycamore_t *sycamore, char * buffer, int length){
	int i = 0;
	printk ("%s entered\n", __func__);
	printk ("read %d bytes: %s\n", length, buffer);
	for(i = 0; i < length; ++i){
		if (sycamore->buf_pos >= BUFFER_SIZE){
			printk("%s: buffer full!", __func__);
			sycamore->buf_pos = 0;
		}
		sycamore->in_buffer[sycamore->buf_pos] = buffer[i];
		sycamore->buf_pos++;
		
	}
}

int sycamore_ioctl(sycamore_t *sycamore, struct tty_struct *tty, unsigned int cmd, unsigned long arg){
	int count = 0;

	printk ("%s Entered function, with CMD: 0x%X\n", __func__, cmd);

	if (sycamore->port_lock){
		printk("%s sycamore is locked by another device\n", __func__);
	}


	switch (cmd) {
		case(PING_SYCAMORE): 
			printk ("%s Ping Function Called\n", __func__);
			tty->ops->write(tty, "L0000000000000000000000000000000", 32);
			count = tty_chars_in_buffer(tty);
			printk ("outgoing count: %d\n", count);
			tty_wait_until_sent(tty, 500);
//			tty->ops->read(tty, &buffer[0], 25);
			return 0;
		case(READ_DRT):
			printk("buffer: %s", &sycamore->in_buffer[0]);
			return 0;
		case(GET_DRT_SIZE):
			return 0;
	}
	//return success
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
	sycamore->buf_pos = 0;



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


