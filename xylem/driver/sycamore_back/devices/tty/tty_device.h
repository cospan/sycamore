//tty_device.h

#ifndef __TTY_DEVICE_H__
#define __TTY_DEVICE_H__

#include <linux/platform_device.h>
#include "../../sycamore_bus.h"


#define SYCAMORE_TTY_DEV_NAME "sycamore-tty"


struct platform_device *pdev; 


struct platform_device * sycamore_tty_dev_new();
void sycamore_tty_dev_destroy();


#endif //__TTY_DEVICE_H__

