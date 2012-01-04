//sycamore_bus.c
#include "sycamore_bus.h"
#include <linux/kernel.h>
#include <linux/slab.h>

//DRT state machine variable
#define DRT_READ_IDLE 			0
#define DRT_READ_START			1
#define DRT_READ_START_RESPONSE	2
#define DRT_READ_ALL			3
#define DRT_READ_ALL_RESPONSE	4
#define DRT_READ_SUCCESS 		5
#define DRT_READ_FAIL			6


//local function prototypes
void control_work(struct work_struct *work);
void reset_devices(sycamore_bus_t *sb);
void drt_state_machine(sycamore_bus_t *sb);

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

void sycamore_bus_init(sycamore_bus_t *sb){
	//initialize the variables
	printk("%s: entered\n", __func__);

	//initialize all things sycmore_driver_t
	sb->sycamore_found = false;
	sb->size_of_drt = 0;
	sb->drt = NULL;
	INIT_WORK(&sb->control_work, control_work); 

	schedule_work(&sb->control_work);
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
	//kill off the control work struct
	cancel_work_sync(&sb->control_work);

	reset_devices(sb);

	if (sb->drt != NULL){
		kfree(sb->drt);
	}
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
	if (interrupts & 0x01){
//XXX: (this feature hasn't been implemented on the FPGA) we have a system interrupt, so the FPGA was reset
		sb->sycamore_found = false;
		schedule_work(&sb->control_work);	
	}
	else {
		//send an interrupt to the appropriate device

//XXX: write the interrupt for the sycamore_device

	}

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
	sb->sycamore_found = true;
	schedule_work(&sb->control_work);	
}

/**
 * sb_write_callback
 * Description: called when a write request is finished
 *	but before we got a response from the FPGA
 *
 * Return:
 *	Nothing
 **/
void sb_write_callback(sycamore_bus_t *sb){
	printk("%s: entered\n", __func__);
}


/**
 * control_work
 * Description: pings the FPGA to determine it's state
 *	if the DRT needs to be requested this will be responsible for it
 *
 * Return:
 *	nothing
 */
void control_work(struct work_struct *work){
	sycamore_but_t *sb = NULL;
	printk("%s: entered\n", __func__);

	sb = container_of (work, sycamore_bus_t, control_work);

	//check if sycamore has been found
	if (!sb->sycamore_found){
		/*
			clear out all of the devices, this could be either from initialization or
			if the FPGA was reset
		*/
		reset_devices(sb);

		//reset the drt state machine
		drt_state_machine(sb);

		//ping the FPGA
		sp_ping(sb);
	}
	else {
		drt_state_machine(sb);
	}
}


/**
 * reset_devices
 * Description: clears all the devices of the characteristics, performs just like a
 *	remove of a device
 *
 * Return:
 *	nothing
 **/
void reset_devices(sycamore_bus_t *sb){
	printk("%s: entered\n", __func__);
	int i;

	for (i = 1; i < MAX_NUM_DEVICES; i++){
		//go through each of the devices and call the remove function
	}
}


void drt_state_machine(sycamore_bus_t *sb){
	int i = 0;
	int retval = 0;

	printk("%s: entered\n", __func__);
	if (sb->drt == NULL || 
		sb->size_of_drt == 0 || 
		!sb->sycamore_found){
		//all good reasons to reset the state machine
		sb->drt_state = DRT_READ_IDLE;		
	}

	switch (sb->drt_state){
		case (DRT_READ_IDLE):
			if (sb->sycamore_found){
				sb->drt_state = DRT_READ_START;
				schedule_work(&sb->control_work);
			}
			//reset the DRT
			if (sb->drt != NULL){
				kfree(sb->drt);
			}
			sb->size_of_drt = 0;
			break;
		case (DRT_READ_START):
			break;
		case (DRT_READ_START_RESPONSE):
			break;
		case (DRT_READ_ALL):
			break;
		case (DRT_READ_ALL_RESPONSE):
			break;
		case (DRT_READ_SUCCESS):
			break;
		default:
			s->drt_state = DRT_READ_IDLE;
			//something went wrong, most likely we need to restart the DRT STATE MACHINE
			schedule_work(&sb->control_work);
			break;
	}
}
