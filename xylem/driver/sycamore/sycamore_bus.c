//sycamore_bus.c
#include "sycamore_bus.h"
#include <linux/kernel.h>
#include <linux/slab.h>



/**
 * sycamore_bus_init
 * Description: Initializes the sycamore_bus
 *	-creates an instance
 *	-initializes the variables
 *
 * Return:
 *	sycamore_bus_t instantiation initialized
 *	NULL on failure
 */

sycamore_bus_t * sycamore_bus_init(void){
	sycamore_bus_t * sb = NULL;
	sb = (sycamore_bus_t *) kzalloc(sizeof(sycamore_bus_t), GFP_KERNEL);
	if (sb == NULL){
		printk ("%s: Failed to allocate sycamore_bus_t\n", __func__);
		return NULL;
	}

	//initialize the variables

	//initialize all things sycmore_driver_t


	return sb;
}


/**
 * sycamore_bus_destroy
 * Description: cleans up and removes any resources the driver used
 *
 * Return:
 *	nothing
 */
void sycamore_bus_destroy(sycamore_bus_t *sb){
	//clean up any resources
	
	//free sycamore_bus_t
	kfree(sb);
}



/**
 * sb_read
 * Description: data is commign from the protocol layer to here
 *
 *	device_address: the address of the virtual device to send the data to
 *	offset:	the offset into the virtual device memory
 *	position: the position of this read because data may come in
 *		a portion at a time
 *	length: the length of this particular read
 *	size_left: the number of bytes left to read from the device
 *
 * Return:
 *	Nothing
 **/
void sb_read(sycamore_bus_t *sb,
				u8 device_address,	//device to write to
				u32 offset,			//where in the offset we started
				u32 position,		//position in the read
				u32 length,			//length of this read
				u32 size_left){		//how much more we have to read

	printk("%s: entered\n", __func__);
	//if the device doesn't exists throw all this away


	/*
		grab the read buffer of the virtual device and start copying the data
		into it
	*/

	//when we read all the data then call the read function to notify the device

	/*
		launch off a workqueue so that the virtual device is not operating in
		an interrupt
	*/

}

/**
 * sb_interrupts
 * Description: this is called when an interrupt is detected from
 *	the FPGA
 *	NOTE: THIS IS CALLED FROM AN INTERRUPT CONTEXT, AND ANY REAL WORK
 *		MUST BE DONE IN A WORKQUEUE (don't be dick to the kernel man)
 *
 * Return:
 *	Nothing
 **/
void sb_interrupt(
				sycamore_bus_t *sb,
				u32 interrupts){
	printk("%s: entered\n", __func__);

	//check if this is an interrupt for the system
}


/**
 * sb_ping_respone
 * Description: this is called when the FPGA responds to a ping request
 *
 * Return:
 *	Nothing
 **/
void sb_ping_response(
				sycamore_bus_t *sb){
	printk("%s: entered\n", __func__);
	//check if need to get the DRT
	//if so send a request for the first 8 double words
}
