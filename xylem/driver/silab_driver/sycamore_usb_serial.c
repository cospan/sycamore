
#include <linux/kernel.h>
#include <linux/errno.h>
#include <linux/init.h>
#include <linux/slab.h>
#include <linux/tty.h>
#include <linux/tty_driver.h>
#include <linux/tty_flip.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/seq_file.h>
#include <linux/spinlock.h>
#include <linux/mutex.h>
#include <linux/list.h>
#include <linux/uaccess.h>
#include <linux/serial.h>
#include <linux/usb.h>
#include <linux/usb/serial.h>
#include <linux/kfifo.h>
#include "sycamore_usb_serial.h"

int sycamore_usb_serial_probe(struct usb_interface *interface, const struct usb_device_id *id){
	struct usb_device *dev = interface_to_usbdev(interface);
	struct usb_serial *serial = NULL;
	struct usb_serial_port *port;
	struct usb_host_interface *iface_desc;
	struct usb_endpoint_descriptor *endpoint;
	struct usb_endpoint_descriptor *interrupt_in_endpoint[MAX_NUM_PORTS];
	struct usb_endpoint_descriptor *interrupt_out_endpoint[MAX_NUM_PORTS];
	struct usb_endpoint_descriptor *bulk_in_endpoint[MAX_NUM_PORTS];
	struct usb_endpoint_descriptor *bulk_out_endpoint[MAX_NUM_PORTS];
	struct usb_serial_driver *type = NULL;
	int retval;
	unsigned int minor;
	int buffer_size;
	int i;
	int num_interrupt_in = 0;
	int num_interrupt_out = 0;
	int num_bulk_in = 0;
	int num_bulk_out = 0;
	int num_ports = 0;
	int max_endpoints;

	mutex_lock(&table_lock);
	type = search_serial_device(interface);
	if (!type) {
		mutex_unlock(&table_lock);
		dbg("none matched");
		return -ENODEV;
	}

	if (!try_module_get(type->driver.owner)) {
		mutex_unlock(&table_lock);
		dev_err(&interface->dev, "module get failed, exiting\n");
		return -EIO;
	}
	mutex_unlock(&table_lock);

	serial = create_serial(dev, interface, type);
	if (!serial) {
		module_put(type->driver.owner);
		dev_err(&interface->dev, "%s - out of memory\n", __func__);
		return -ENOMEM;
	}

	/* if this device type has a probe function, call it */
	if (type->probe) {
		const struct usb_device_id *id;

		id = get_iface_id(type, interface);
		retval = type->probe(serial, id);

		if (retval) {
			dbg("sub driver rejected device");
			kfree(serial);
			module_put(type->driver.owner);
			return retval;
		}
	}

	/* descriptor matches, let's find the endpoints needed */
	/* check out the endpoints */
	iface_desc = interface->cur_altsetting;
	for (i = 0; i < iface_desc->desc.bNumEndpoints; ++i) {
		endpoint = &iface_desc->endpoint[i].desc;

		if (usb_endpoint_is_bulk_in(endpoint)) {
			/* we found a bulk in endpoint */
			dbg("found bulk in on endpoint %d", i);
			bulk_in_endpoint[num_bulk_in] = endpoint;
			++num_bulk_in;
		}

		if (usb_endpoint_is_bulk_out(endpoint)) {
			/* we found a bulk out endpoint */
			dbg("found bulk out on endpoint %d", i);
			bulk_out_endpoint[num_bulk_out] = endpoint;
			++num_bulk_out;
		}

		if (usb_endpoint_is_int_in(endpoint)) {
			/* we found a interrupt in endpoint */
			dbg("found interrupt in on endpoint %d", i);
			interrupt_in_endpoint[num_interrupt_in] = endpoint;
			++num_interrupt_in;
		}

		if (usb_endpoint_is_int_out(endpoint)) {
			/* we found an interrupt out endpoint */
			dbg("found interrupt out on endpoint %d", i);
			interrupt_out_endpoint[num_interrupt_out] = endpoint;
			++num_interrupt_out;
		}
	}

#if defined(CONFIG_USB_SERIAL_PL2303) || defined(CONFIG_USB_SERIAL_PL2303_MODULE)
	/* BEGIN HORRIBLE HACK FOR PL2303 */
	/* this is needed due to the looney way its endpoints are set up */
	if (((le16_to_cpu(dev->descriptor.idVendor) == PL2303_VENDOR_ID) &&
	     (le16_to_cpu(dev->descriptor.idProduct) == PL2303_PRODUCT_ID)) ||
	    ((le16_to_cpu(dev->descriptor.idVendor) == ATEN_VENDOR_ID) &&
	     (le16_to_cpu(dev->descriptor.idProduct) == ATEN_PRODUCT_ID)) ||
	    ((le16_to_cpu(dev->descriptor.idVendor) == ALCOR_VENDOR_ID) &&
	     (le16_to_cpu(dev->descriptor.idProduct) == ALCOR_PRODUCT_ID)) ||
	    ((le16_to_cpu(dev->descriptor.idVendor) == SIEMENS_VENDOR_ID) &&
	     (le16_to_cpu(dev->descriptor.idProduct) == SIEMENS_PRODUCT_ID_EF81))) {
		if (interface != dev->actconfig->interface[0]) {
			/* check out the endpoints of the other interface*/
			iface_desc = dev->actconfig->interface[0]->cur_altsetting;
			for (i = 0; i < iface_desc->desc.bNumEndpoints; ++i) {
				endpoint = &iface_desc->endpoint[i].desc;
				if (usb_endpoint_is_int_in(endpoint)) {
					/* we found a interrupt in endpoint */
					dbg("found interrupt in for Prolific device on separate interface");
					interrupt_in_endpoint[num_interrupt_in] = endpoint;
					++num_interrupt_in;
				}
			}
		}

		/* Now make sure the PL-2303 is configured correctly.
		 * If not, give up now and hope this hack will work
		 * properly during a later invocation of usb_serial_probe
		 */
		if (num_bulk_in == 0 || num_bulk_out == 0) {
			dev_info(&interface->dev, "PL-2303 hack: descriptors matched but endpoints did not\n");
			kfree(serial);
			module_put(type->driver.owner);
			return -ENODEV;
		}
	}
	/* END HORRIBLE HACK FOR PL2303 */
#endif

#ifdef CONFIG_USB_SERIAL_GENERIC
	if (type == &usb_serial_generic_device) {
		num_ports = num_bulk_out;
		if (num_ports == 0) {
			dev_err(&interface->dev,
			    "Generic device with no bulk out, not allowed.\n");
			kfree(serial);
			module_put(type->driver.owner);
			return -EIO;
		}
	}
#endif
	if (!num_ports) {
		/* if this device type has a calc_num_ports function, call it */
		if (type->calc_num_ports)
			num_ports = type->calc_num_ports(serial);
		if (!num_ports)
			num_ports = type->num_ports;
	}

	serial->num_ports = num_ports;
	serial->num_bulk_in = num_bulk_in;
	serial->num_bulk_out = num_bulk_out;
	serial->num_interrupt_in = num_interrupt_in;
	serial->num_interrupt_out = num_interrupt_out;

	/* found all that we need */
	dev_info(&interface->dev, "%s converter detected\n",
			type->description);

	/* create our ports, we need as many as the max endpoints */
	/* we don't use num_ports here because some devices have more
	   endpoint pairs than ports */
	max_endpoints = max(num_bulk_in, num_bulk_out);
	max_endpoints = max(max_endpoints, num_interrupt_in);
	max_endpoints = max(max_endpoints, num_interrupt_out);
	max_endpoints = max(max_endpoints, (int)serial->num_ports);
	serial->num_port_pointers = max_endpoints;

	dbg("%s - setting up %d port structures for this device",
						__func__, max_endpoints);
	for (i = 0; i < max_endpoints; ++i) {
		port = kzalloc(sizeof(struct usb_serial_port), GFP_KERNEL);
		if (!port)
			goto probe_error;
		tty_port_init(&port->port);
		port->port.ops = &serial_port_ops;
		port->serial = serial;
		spin_lock_init(&port->lock);
		/* Keep this for private driver use for the moment but
		   should probably go away */
		INIT_WORK(&port->work, usb_serial_port_work);
		serial->port[i] = port;
		port->dev.parent = &interface->dev;
		port->dev.driver = NULL;
		port->dev.bus = &usb_serial_bus_type;
		port->dev.release = &port_release;
		device_initialize(&port->dev);
	}

	/* set up the endpoint information */
	for (i = 0; i < num_bulk_in; ++i) {
		endpoint = bulk_in_endpoint[i];
		port = serial->port[i];
		port->read_urb = usb_alloc_urb(0, GFP_KERNEL);
		if (!port->read_urb) {
			dev_err(&interface->dev, "No free urbs available\n");
			goto probe_error;
		}
		buffer_size = max_t(int, serial->type->bulk_in_size,
				le16_to_cpu(endpoint->wMaxPacketSize));
		port->bulk_in_size = buffer_size;
		port->bulk_in_endpointAddress = endpoint->bEndpointAddress;
		port->bulk_in_buffer = kmalloc(buffer_size, GFP_KERNEL);
		if (!port->bulk_in_buffer) {
			dev_err(&interface->dev,
					"Couldn't allocate bulk_in_buffer\n");
			goto probe_error;
		}
		usb_fill_bulk_urb(port->read_urb, dev,
				usb_rcvbulkpipe(dev,
						endpoint->bEndpointAddress),
				port->bulk_in_buffer, buffer_size,
				serial->type->read_bulk_callback, port);
	}

	for (i = 0; i < num_bulk_out; ++i) {
		int j;

		endpoint = bulk_out_endpoint[i];
		port = serial->port[i];
		port->write_urb = usb_alloc_urb(0, GFP_KERNEL);
		if (!port->write_urb) {
			dev_err(&interface->dev, "No free urbs available\n");
			goto probe_error;
		}
		if (kfifo_alloc(&port->write_fifo, PAGE_SIZE, GFP_KERNEL))
			goto probe_error;
		buffer_size = serial->type->bulk_out_size;
		if (!buffer_size)
			buffer_size = le16_to_cpu(endpoint->wMaxPacketSize);
		port->bulk_out_size = buffer_size;
		port->bulk_out_endpointAddress = endpoint->bEndpointAddress;
		port->bulk_out_buffer = kmalloc(buffer_size, GFP_KERNEL);
		if (!port->bulk_out_buffer) {
			dev_err(&interface->dev,
					"Couldn't allocate bulk_out_buffer\n");
			goto probe_error;
		}
		usb_fill_bulk_urb(port->write_urb, dev,
				usb_sndbulkpipe(dev,
					endpoint->bEndpointAddress),
				port->bulk_out_buffer, buffer_size,
				serial->type->write_bulk_callback, port);
		for (j = 0; j < ARRAY_SIZE(port->write_urbs); ++j) {
			set_bit(j, &port->write_urbs_free);
			port->write_urbs[j] = usb_alloc_urb(0, GFP_KERNEL);
			if (!port->write_urbs[j]) {
				dev_err(&interface->dev,
						"No free urbs available\n");
				goto probe_error;
			}
			port->bulk_out_buffers[j] = kmalloc(buffer_size,
								GFP_KERNEL);
			if (!port->bulk_out_buffers[j]) {
				dev_err(&interface->dev,
					"Couldn't allocate bulk_out_buffer\n");
				goto probe_error;
			}
			usb_fill_bulk_urb(port->write_urbs[j], dev,
					usb_sndbulkpipe(dev,
						endpoint->bEndpointAddress),
					port->bulk_out_buffers[j], buffer_size,
					serial->type->write_bulk_callback,
					port);
		}
	}

	if (serial->type->read_int_callback) {
		for (i = 0; i < num_interrupt_in; ++i) {
			endpoint = interrupt_in_endpoint[i];
			port = serial->port[i];
			port->interrupt_in_urb = usb_alloc_urb(0, GFP_KERNEL);
			if (!port->interrupt_in_urb) {
				dev_err(&interface->dev,
						"No free urbs available\n");
				goto probe_error;
			}
			buffer_size = le16_to_cpu(endpoint->wMaxPacketSize);
			port->interrupt_in_endpointAddress =
						endpoint->bEndpointAddress;
			port->interrupt_in_buffer = kmalloc(buffer_size,
								GFP_KERNEL);
			if (!port->interrupt_in_buffer) {
				dev_err(&interface->dev,
				    "Couldn't allocate interrupt_in_buffer\n");
				goto probe_error;
			}
			usb_fill_int_urb(port->interrupt_in_urb, dev,
				usb_rcvintpipe(dev,
						endpoint->bEndpointAddress),
				port->interrupt_in_buffer, buffer_size,
				serial->type->read_int_callback, port,
				endpoint->bInterval);
		}
	} else if (num_interrupt_in) {
		dbg("the device claims to support interrupt in transfers, but read_int_callback is not defined");
	}

	if (serial->type->write_int_callback) {
		for (i = 0; i < num_interrupt_out; ++i) {
			endpoint = interrupt_out_endpoint[i];
			port = serial->port[i];
			port->interrupt_out_urb = usb_alloc_urb(0, GFP_KERNEL);
			if (!port->interrupt_out_urb) {
				dev_err(&interface->dev,
						"No free urbs available\n");
				goto probe_error;
			}
			buffer_size = le16_to_cpu(endpoint->wMaxPacketSize);
			port->interrupt_out_size = buffer_size;
			port->interrupt_out_endpointAddress =
						endpoint->bEndpointAddress;
			port->interrupt_out_buffer = kmalloc(buffer_size,
								GFP_KERNEL);
			if (!port->interrupt_out_buffer) {
				dev_err(&interface->dev,
				  "Couldn't allocate interrupt_out_buffer\n");
				goto probe_error;
			}
			usb_fill_int_urb(port->interrupt_out_urb, dev,
				usb_sndintpipe(dev,
						  endpoint->bEndpointAddress),
				port->interrupt_out_buffer, buffer_size,
				serial->type->write_int_callback, port,
				endpoint->bInterval);
		}
	} else if (num_interrupt_out) {
		dbg("the device claims to support interrupt out transfers, but write_int_callback is not defined");
	}

	/* if this device type has an attach function, call it */
	if (type->attach) {
		retval = type->attach(serial);
		if (retval < 0)
			goto probe_error;
		serial->attached = 1;
		if (retval > 0) {
			/* quietly accept this device, but don't bind to a
			   serial port as it's about to disappear */
			serial->num_ports = 0;
			goto exit;
		}
	} else {
		serial->attached = 1;
	}

	if (get_free_serial(serial, num_ports, &minor) == NULL) {
		dev_err(&interface->dev, "No more free serial devices\n");
		goto probe_error;
	}
	serial->minor = minor;

	/* register all of the individual ports with the driver core */
	for (i = 0; i < num_ports; ++i) {
		port = serial->port[i];
		dev_set_name(&port->dev, "ttyUSB%d", port->number);
		dbg ("%s - registering %s", __func__, dev_name(&port->dev));
		port->dev_state = PORT_REGISTERING;
		device_enable_async_suspend(&port->dev);

		retval = device_add(&port->dev);
		if (retval) {
			dev_err(&port->dev, "Error registering port device, "
				"continuing\n");
			port->dev_state = PORT_UNREGISTERED;
		} else {
			port->dev_state = PORT_REGISTERED;
		}
	}

	usb_serial_console_init(debug, minor);

exit:
	/* success */
	usb_set_intfdata(interface, serial);
	module_put(type->driver.owner);
	return 0;

probe_error:
	usb_serial_put(serial);
	module_put(type->driver.owner);
	return -EIO;
}
EXPORT_SYMBOL_GPL(usb_serial_probe);


void sycamore_usb_serial_disconnect(struct usb_interface *iface){
}
