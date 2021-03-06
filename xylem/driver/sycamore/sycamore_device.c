//sycamore_device.c
#include "sycamore_bus.h"
#include "devices/devices.h"

/**
 * device
 * Description: this is generic device, based on the 'type' specified in the
 *	resources a more specific version of the device can be loaded.
 *	the generic version will create a platform driver that can be
 *	read and written to using the lseek command to speicify the location
 *	of the write
 **/


/**
 * device_init
 * Description: initialize the device. The type of the device is dependent
 *	on the 'type' variable specified in the reousres of the platform device
 *	call the type specific init in here
 *
 * Return:
 *	Nothing
 **/
void sycamore_device_init(	sycamore_bus_t *sb, 
							sycamore_device_t *sd, 
							u16 type, 
							u16 flags, 
							u32 device_address,
							u32 size){


	printk("%s: (sycamore) entered\n", __func__);	
	sd->type = type;
	sd->flags = flags;
	sd->device_address = device_address;
	sd->sb = sb;

	sd->destroy = NULL;
	sd->interrupt = NULL;
	sd->read = NULL;

	switch (type){
		case (DEVICE_DRT):
			printk("%s: initializing device DRT\n", __func__);
			sd->device = drt_init(sd, DEVICE_DRT_NAME);
			break;
		case (DEVICE_GPIO):
			printk("%s: initializing device GPIO\n", __func__);
			sd->device = gpio_dev_init(sd, DEVICE_GPIO_NAME);
			break;
		case (DEVICE_UART):
			printk("%s: initializing device UART\n", __func__);
			break;
		case (DEVICE_I2C):
			printk("%s: initializing device I2C\n", __func__);
			break;
		case (DEVICE_SPI):
			printk("%s: initializing device SPI\n", __func__);
			break;
		case (DEVICE_MEMORY):
			printk("%s: initializing device Memory\n", __func__);
			break;
		case (DEVICE_CONSOLE):
			printk("%s: initializing device Console\n", __func__);
			break;
		case (DEVICE_FSMC):
			printk("%s: initializing device FSMC\n", __func__);
			break;
		case (DEVICE_FRAME_BUFFER):
			printk("%s: initializing device Frame Buffer\n", __func__);
			break;
		default:
			//load the default device
			printk("%s: loading the default device\n", __func__);
			break;
	}
}

/**
 * device_destroy
 * Description: clean up any resources allocated/used
 *	call the type specific destroy in here
 *
 * Return:
 *	Nothing
 **/
void sycamore_device_destroy(sycamore_device_t *sd){
	if (sd->destroy != NULL){
		sd->destroy(sd);
	}
}


/**
 * device_read_callback (generic)
 * Description: called when a device specifies a read
 *	since the write context is left then this function is used to wait for a
 *	response
 *	-If a specific type of device is not specified then this function is called
 *
 * Return:
 *	Nothing
 **/
void sycamore_device_read_callback(sycamore_device_t *sd, 
									u32 position,
									u32 start_address,
									u32 total_length,
									u32 size_left,
									u8 * data,
									u32 length){


	if (sd->read != NULL){
		sd->read( 	sd->device,
					position,
					start_address,
					total_length,
					size_left,
					data,
					length);
	}
	else {
		printk("%s: read not defined\n", __func__);
	}
}

/**
 * device_interrupt (generic)
 * Description: called whenever an interrupt is detected for the specified device
 *
 * Return:
 *	Nothing
 **/
void device_interrupt(sycamore_device_t *sd, u32 interrupt){
	if (sd->interrupt != NULL){
		sd->interrupt(sd->device, interrupt); 
	}
	else {
		printk("%s: interrupt not defined\n", __func__);
	}

}

