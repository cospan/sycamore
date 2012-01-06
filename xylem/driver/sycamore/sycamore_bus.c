//sycamore_bus.c

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


#include "sycamore_bus.h"
#include "sycamore_commands.h"
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/sched.h>

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
void reset_sycamore_devices(sycamore_bus_t *sb);
int protocol_write(sycamore_device_t *sd, u32 command, u32 address, u8 *data, u32 size);
void ping (sycamore_bus_t * sb);
//void drt_state_machine(sycamore_bus_t *sb);
/**
 * sycamore_bus_init
 * Description: Initializes the sycamore_bus
 *	-creates an instance
 *	-initializes the variables
 *
 * Return:
 *	sycamore_bus_t instantiation initialized
 *	-1 on failure
 */

int sb_init(sycamore_bus_t *sb){
	//initialize the variables
	int i = 0;
	srb_t * srb = NULL;

	printk("%s: entered\n", __func__);

	//initialize all things sycmore_driver_t
	sb->sycamore_found = false;
	atomic_set(&sb->bus_busy, 0);
//	sb->size_of_drt = 0;
//	sb->drt = NULL;
	INIT_WORK(&sb->control_work, control_work); 


	//setup the SRB lists
	INIT_LIST_HEAD(&sb->available_queue);
	INIT_LIST_HEAD(&sb->ready_queue);
	INIT_LIST_HEAD(&sb->busy_queue);

	//initialize the wait queue
	init_waitqueue_head(&sb->write_wait_queue);

	//add SRB's to the available_queue
	for (i = 0; i < NUM_OF_SRBS; i++){
		srb = srb_new();	
		if (srb == NULL){
			printk("%s: failed to instantiate an SRB\n", __func__);
			goto fail1;
		}
		//add it to the available queue
		list_add_tail(srb_get_list_head(srb), &sb->available_queue);
	}
	//gotta start the ball rolling
	schedule_work(&sb->control_work);

	return 0;

fail1:
	return -1;
}


/**
 * sycamore_bus_destroy
 * Description: cleans up and removes any resources the driver used
 *
 * Return:
 *	nothing
 */
void sb_destroy(sycamore_bus_t *sb){

	struct list_head *pos = NULL;
	srb_t *srb = NULL;

	printk("%s: entered\n", __func__);
	//clean up any resources
	//kill off the control work struct
	cancel_work_sync(&sb->control_work);

	//stop any new transactions
	atomic_set(&sb->bus_busy, 1);

	reset_sycamore_devices(sb);

	if (!list_empty_careful(&sb->ready_queue)){
		list_for_each(pos, &sb->ready_queue){
			list_add_tail(pos, &sb->busy_queue); 
		}
	}
	if (!list_empty_careful(&sb->available_queue)){
		list_for_each(pos, &sb->available_queue){
			list_add_tail(pos, &sb->busy_queue); 
		}

	}
	//destroy all the SRB
	if (!list_empty_careful(&sb->busy_queue)){
		list_for_each_entry(srb, &sb->busy_queue, lh){
			srb_destroy(srb);		
		}
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
void sp_sb_read(sycamore_bus_t *sb,
				u32 command,
				u8 device_address,	//device to write to
				u32 offset,			//where in the offset we started
				u32 position,		//position in the read
				u32 total_length,	//total length of data to read in
				u32 length,			//length of this read
				u32 size_left,		//how much more we have to read
				u8 * data){		

	u32 interrupts = 0;
	printk("%s: entered\n", __func__);
	//if the device doesn't exists throw all this away


	switch (command){
		case (SYCAMORE_INTERRUPTS):
			interrupts |= (u32) (data[0] << 24);
			interrupts |= (u32) (data[1] << 16);
			interrupts |= (u32) (data[2] << 8);
			interrupts |= (u32) (data[3]);
			//this assumes that the bytes for an int ar arranged correctly
			if (interrupts & 0x01){
				//FPGA was reset
//XXX: FPGA reset here! (make a function that will reset everything
				sb->sycamore_found = false;
				schedule_work(&sb->control_work);
			}
			break;
		case (SYCAMORE_PING):
			//response from a ping
			sb->sycamore_found = true;
			schedule_work(&sb->control_work);
			break;
		case (SYCAMORE_WRITE):
//XXX: Tell the appropriate device that the write was acknowledged
			break;
		case (SYCAMORE_READ):
//XXX: Feed the device data to be read in
			//we feed the device one double word at a time, the device must put it together
			//once the data is all read in then we need to tell the read that it's done
			break;
		default:
			//an undefined command??
			printk("%s: received an illegal command: %8X\n", __func__, command);
			break;
	}
	/*
		grab the read buffer of the virtual device and start copying the data
		into it
	*/

	//when we read all the data then call the read function to notify the device

	/*
		launch off a workqueue so that the virtual device is not operating in
		an interrupt
	*/


	/*
		determine if this is a ping
	*/
	/* when were done we need to release the context */ 
	atomic_set(&sb->bus_busy, 1);
	wake_up(&sb->write_wait_queue);
	

}

/**
 * sb_write_callback
 * Description: called when a write request is finished
 *	but before we got a response from the FPGA
 *
 * Return:
 *	Nothing
 **/
void sp_sb_write_callback(sycamore_bus_t *sb){
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
	sycamore_bus_t *sb = NULL;
	printk("%s: entered\n", __func__);

	sb = container_of (work, sycamore_bus_t, control_work);

	//check if sycamore has been found
	if (!sb->sycamore_found){
		/*
			clear out all of the devices, this could be either from initialization or
			if the FPGA was reset
		*/
		reset_sycamore_devices(sb);

/*		//reset the drt state machine
		drt_state_machine(sb);
*/

		//ping the FPGA
		ping(sb);
	}
	/*
	else {
		drt_state_machine(sb);
	}
	*/
}


/**
 * reset_sycamore_devices
 * Description: clears all the devices of the characteristics, performs just like a
 *	remove of a device
 *
 * Return:
 *	nothing
 **/
void reset_sycamore_devices(sycamore_bus_t *sb){
	int i;
	printk("%s: entered\n", __func__);

	for (i = 1; i < MAX_NUM_DEVICES; i++){
		//go through each of the devices and call the remove function
	}
}

/*
void drt_state_machine(sycamore_bus_t *sb){
	//int i = 0;
	//int retval = 0;

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
			sb->drt_state = DRT_READ_IDLE;
			//something went wrong, most likely we need to restart the DRT STATE MACHINE
			schedule_work(&sb->control_work);
			break;
	}
}
*/


/**
 * protocol_write
 * Description: initiate a write to the bus
 *	if the sd device implements blocking then the bus will hold the context
 *	in a wait queue until the bus is available
 *	regardless of if this is a read, or a write to the protocol layer it looks the same from here
 **/
int protocol_write(sycamore_device_t *sd, u32 command, u32 address, u8 *data, u32 size){
	//try and get a SRB from the available queue	
	sycamore_bus_t *sb = NULL;

	printk("%s: entered\n", __func__);
	sb = sd->sb;

	//check if the bus is busy right now
	if (atomic_read(&sb->bus_busy)){
		if (!sd->blocking){
			//the device is not blocking, so just return
			return -EAGAIN;
		}
		if (wait_event_interruptible_exclusive(sb->write_wait_queue, (atomic_read(&sb->bus_busy) == 0))){
			/*
				got an interupt before the system could respond,
				this could be due to closing sycamore
			*/
			return -ERESTARTSYS;
		}
		//woot! bus is free again
	}

	//grab the bus for myself
	atomic_set(&sb->bus_busy, 1);

	//all the SRB's should be available to me right now
	sb->working_device = sd;	
	sd->write_in_progress = 1;
	
	sb_sp_write(
						sb,
						command,
						sd->index,
						address,
						data,
						size);
//XXX: make the context sleep here until the the write is complete the read function should get an acknowledgement to the write
	return -1;

}
void sd_sb_read(sycamore_device_t *sd, u32 address, u32 size){
}

