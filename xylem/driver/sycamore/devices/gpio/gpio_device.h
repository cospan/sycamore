//gpio_device.h

#ifndef __GPIO_DEVICE_H__
#define __GPIO_DEVICE_H__

#include <linux/platform_device.h>
#include "../../sycamore_bus.h"


typedef struct _sycamore_gpio_dev_t sycamore_gpio_dev_t;
void *gpio_dev_init(sycamore_device_t * sd, const char * name);



#endif //__GPIO_DEVICE_H__

