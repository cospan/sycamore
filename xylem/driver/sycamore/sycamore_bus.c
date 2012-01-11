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
#include "devices/drt/drt.h"
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/sched.h>


//local function prototypes
void control_work(struct work_struct *work);
void reset_sycamore_devices(sycamore_bus_t *sb);
void destroy_sycamore_devices(sycamore_bus_t *sb);
void initialize_sycamore_devices(sycamore_bus_t *sb);
int protocol_write(sycamore_device_t *sd, u32 command, u32 address, u8 *data, u32 size);
void ping (sycamore_bus_t * sb);



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

	printk("%s: (sycamore) entered\n", __func__);

	//initialize all things sycmore_driver_t
	sb->sycamore_found = false;
	atomic_set(&sb->bus_busy, 0);
	INIT_DELAYED_WORK(&sb->control_work, control_work); 

	//initialize the wait queue
	init_waitqueue_head(&sb->write_wait_queue);

	initialize_sycamore_devices(sb);

	//gotta start the ball rolling
	schedule_delayed_work(&sb->control_work, CONTROL_TIMEOUT);

	sb->pdev = platform_device_register_simple(SYCAMORE_BUS_NAME, -1, 0, 0);

	//initialize the DRT
	sycamore_device_init(sb, &sb->devices[0], 0, 0, 0, 0);
	return 0;
}


/**
 * sycamore_bus_destroy
 * Description: cleans up and removes any resources the driver used
 *
 * Return:
 *	nothing
 */
void sb_destroy(sycamore_bus_t *sb){

	printk("%s: (sycamore) entered\n", __func__);
	//clean up any resources
	//kill off the control work struct
	cancel_delayed_work_sync(&sb->control_work);

	//stop any new transactions
	atomic_set(&sb->bus_busy, 1);
	reset_sycamore_devices(sb);
	destroy_sycamore_devices(sb);

	//destroy the drt
	sycamore_device_destroy(&sb->devices[0]);

	platform_device_unregister(sb->pdev);


	//free the string
	kfree(sb->pdrv.driver.name);
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
				u32 start_address,	//where in the offset we started
				u32 position,		//position in the read
				u32 total_length,	//total length of data to read in
				u32 length,			//length of this read
				u32 size_left,		//how much more we have to read
				u8 * data){		

	u32 interrupts = 0;
	printk("%s: (sycamore) entered\n", __func__);
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
				schedule_delayed_work(&sb->control_work, 0);
			}
			break;
		case (SYCAMORE_PING):
			//response from a ping
			sb->sycamore_found = true;
			schedule_delayed_work(&sb->control_work, 0);
			break;
		case (SYCAMORE_WRITE):
//XXX: Tell the appropriate device that the write was acknowledged
			break;
		case (SYCAMORE_READ):
//XXX: Feed the device data to be read in
			//we feed the device one double word at a time, the device must put it together
			//once the data is all read in then we need to tell the read that it's done
			
			sycamore_device_read_callback(	&sb->devices[device_address],
											position,
											start_address,
											total_length,
											size_left,
											data,
											length);
			if (device_address == 0){
				schedule_delayed_work(&sb->control_work, 0);
			}
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
	atomic_set(&sb->bus_busy, 0);
	wake_up(&sb->write_wait_queue);
	

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
	int i = 0;
	sycamore_bus_t *sb = NULL;

	//device variables
	int device_count = 0;
	u32 type = 0;
	u32 flags = 0;
	u32 size = 0;
	u32 dev_address = 0;


	printk("%s: (sycamore) entered\n", __func__);

	sb = container_of (work, sycamore_bus_t, control_work.work);

	//check if sycamore has been found
	if (!sb->sycamore_found){
		printk("%s: (sycamore) pinging sycamore\n", __func__);
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
	else {
		printk("%s: (sycamore) got a ping response\n", __func__);
		//drt_state_machine(sb);

		if (!drt_working(&sb->devices[0])){
			drt_start (&sb->devices[0]);
		}
		else {

			if (drt_finished(&sb->devices[0])){
				if (drt_success(&sb->devices[0])){

					printk("%s: (sycamore) Successfully read DRT!\n", __func__);

					device_count = drt_get_number_of_devices(&sb->devices[0]);

					//i = 0 is the DRT
					printk("%s: (sycamore) Number of devices: %d\n",
									__func__,
									device_count);

					for (i = 1; i <= device_count; i++){
						printk("%s: (sycamore) device num: %d\n", 
									__func__,
									i);
						if (drt_get_device_data(	&sb->devices[0],
													i,
													&type,
													&flags,
													&size,
													&dev_address) < 0){
							printk("%s: (sycamore) failed to get device data\n",
									__func__);
							continue;
						}
						printk("%s: (sycamore) found a device\n", __func__);
						printk("\ttype:\t\t%08X\n", type);
						printk("\tflags:\t\t%08X\n", flags);
						printk("\tsize:\t\t%08X\n", size);
						printk("\taddress:\t%08X\n", dev_address);
						sycamore_device_init(	sb,
												&sb->devices[i],
												type,
												flags,
												dev_address,
												size);
					}

					printk("%s: (sycamore) Finished\n", __func__);
				}
			}
		}
	}
}

/**
 * initialize_sycamore_devices
 * Description: sets all the parameters of every device to initial values
 *
 * Return:
 *	nothing
 **/

void initialize_sycamore_devices(sycamore_bus_t *sb){
	int i;
	printk("%s: (sycamore) entered\n", __func__);
	for (i = 1; i < MAX_NUM_DEVICES; i++){

		sb->devices[i].device_address 		=	0;
		sb->devices[i].flags 				=	0;
		sb->devices[i].type 				=	0;
		sb->devices[i].size 				=	0;

		sb->devices[i].blocking				=	false;
		sb->devices[i].write_in_progress	=	false;


		sb->devices[i].device				=	NULL;

		sb->devices[i].pdev					=	NULL;

		sb->devices[i].destroy				=	NULL;
		sb->devices[i].read					=	NULL;
		sb->devices[i].interrupt			=	NULL;
	}
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
	printk("%s: (sycamore) entered\n", __func__);

	for (i = 1; i < MAX_NUM_DEVICES; i++){
		//go through each of the devices and call the remove function
	}
}

/**
 * destory_sycamore_devices
 * Description: remove all devices
 *
 * Return:
 *	nothing
 **/

void destroy_sycamore_devices(sycamore_bus_t *sb){
	int i;
	printk("%s: (sycamore) entered\n", __func__);

	for (i = 1; i < MAX_NUM_DEVICES; i++){
		//go through each of the devices and call the remove function
		sycamore_device_destroy(&sb->devices[i]);
	}
}



/**
 * bus_write
 * Description: called from the device when it writes to the bus
 *	Note: this context can be put to sleep by the bus when waiting for
 *	other transactions to finish, or when this transaction is finished
 *
 * Return:
 *	0 on success (all bytes should be sent each time)
 *	-1 on failure
 **/
int bus_write(sycamore_device_t *sd, u32 address, u8 * data, u32 size){
	printk("%s: (sycamore) entered\n", __func__);
	return protocol_write(sd, SYCAMORE_WRITE, address, data, size);
}


/**
 * bus_read
 * Description: called from the device when it reads from the bus
 *	Note: this context can be put to sleep by the bus when waiting for
 *	other transactions to finish, and must sleep on it's own in order
 *	to wait for a read callback (readcallback) should wake up this context
 *
 * Return:
 *	Nothing
 **/
void bus_read(sycamore_device_t *sd, u32 address, u32 size){
	printk("%s: (sycamore) entered\n", __func__);
	protocol_write(sd, SYCAMORE_READ, address, NULL, size);
}

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

	printk("%s: (sycamore) entered\n", __func__);
	sb = sd->sb;


	//check if the bus is busy right now
	if (atomic_read(&sb->bus_busy)){
		printk("%s: (sycamore) read lock\n", __func__);
		if (!sd->blocking){
			//the device is not blocking, so just return
			printk("%s: (sycamore) non block\n", __func__);
			return -EAGAIN;
		}
		printk("%s: (sycamore) starting wait\n", __func__);
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
						sd->device_address,
						address,
						data,
						size);
//XXX: make the context sleep here until the the write is complete the read function should get an acknowledgement to the write
	return -1;

}

void ping (sycamore_bus_t * sb){
	printk("%s: (sycamore) entered\n", __func__);
	atomic_set(&sb->bus_busy, 1);
	sb_sp_write(
				sb,
				SYCAMORE_PING,
				0x00,
				0x00,
				NULL,
				0x00);
}


struct platform_device * get_sycamore_bus_pdev (sycamore_bus_t *sb){
	return sb->pdev;
}



