//gpio_device.c


/*
Distributed under the MIT licesnse.
Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/


/**
 * Sycamore GPIO Device
 *
 * Description:
 *	Virtual GPIO device that will interface with the sycamore bus
 *	and present the kernel with a GPIO device
 *
 **/


#include <linux/slab.h>
#include "gpio_device.h"


struct _sycamore_gpio_dev_t {
	u32 value;
};


void gpio_dev_destroy(sycamore_device_t *sd);
void gpio_dev_interrupt(sycamore_device_t *sd, u32 interrupt);

void * gpio_dev_init(	sycamore_device_t * sd, 
						const char * name){
	sycamore_gpio_dev_t *gpio_dev = NULL;
	printk("%s: (sycamore) entered\n", __func__);
	gpio_dev = (sycamore_gpio_dev_t *) kzalloc(
									sizeof(sycamore_gpio_dev_t), 
									GFP_KERNEL);
	if (gpio_dev == NULL){
		printk("%s: (sycamore) ERROR: allocation failure\n", __func__);
		return NULL;
	}
	//don't really know what to put in here
	gpio_dev->value = 0;

	sd->device = gpio_dev;
	sd->pdev = platform_device_register_simple (
								name, 
								-1,
								NULL,
								0);

	sd->destroy = gpio_dev_destroy;
	sd->interrupt = gpio_dev_interrupt;
	return gpio_dev;
}

void gpio_dev_destroy (sycamore_device_t * sd){
	sycamore_gpio_dev_t *gpio_dev = NULL;
	printk("%s: (sycamore) entered\n", __func__);
	gpio_dev = (sycamore_gpio_dev_t *) sd->device;

	platform_device_unregister(sd->pdev);
	
	kfree(gpio_dev);

}


void gpio_dev_interrupt(sycamore_device_t *sd, u32 interrupt){
	printk("%s: (sycamore) entered\n", __func__);
	//don't really have anything to do yet
}
