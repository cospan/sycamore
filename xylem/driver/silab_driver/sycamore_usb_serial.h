//sycamore_usb_serial.h


//sycamore specific probe function


#ifndef __SYCAMORE_USB_SERIAL__
#define __SYCAMORE_USB_SERIAL__

#include <linux/platform_device.h>

//sycamore_platfrom data
struct sycamore_t {
	struct platform_device *platform_device;
	u32	size_of_drt;
	char * drt;
};

int sycamore_usb_serial_probe(struct usb_interface *interface, const struct usb_device_id *id);
void sycamore_usb_serial_disconnect(struct usb_interface *iface);
//	sycamore = kzalloc(sizeof(struct sycamore_t), GFP_KERNEL);	
//	if (!sycamore) {
//		usb_deregister(&cp210x_driver);
//		usb_serial_deregister(&cp210x_device);
//		return -ENOMEM;
//	}

//	struct sycamore_t * sycamore = usb_get_serial_data(&cp210x_device);
//	kfree(sycamore);


#endif //__SYCAMORE_USB_SERIAL__
