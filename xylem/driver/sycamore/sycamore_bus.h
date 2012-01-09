//sycamore_bus.h

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
 * sycamore_bus: the level just above the protocol specific driver
 * 	regardless of what hardware device is attached this level doesn't change.
 *	this will control the communication between all the virtual devices
 *	and the FPGA
 *
 *	-handles all the low level sycamore functions for the sycamore_bus
 *	including:
 *		-detection with ping
 *		-obtaining the DRT
 *		-communicating with the protocol layer
 *		-communicating with virtual devices
 **/


#ifndef __SYCAMORE_BUS_H__
#define __SYCAMORE_BUS_H__

#include <linux/types.h>
#include <linux/workqueue.h>
#include <linux/wait.h>
#include <linux/platform_device.h>

#define MAX_NUM_DEVICES 256
#define CONTROL_TIMEOUT 100

typedef struct _sycamore_device_t sycamore_device_t;
typedef struct _sycamore_bus_t sycamore_bus_t;


/*--------------------------------------------------- */
//Devices
//hardware callback whenever we want to perform a write to the controlling device
typedef int (*device_read_func_t) 		(	void *device,
											u32 position,
											u32 start_address,
											u32 total_length,
											u32 size_left,
											u8 * data,
											u32 length
											);
typedef void (*device_interrupt_func_t) (	void *device,
											u32 interrupt);
typedef void (*device_destroy_func_t) 	(	void *device);


struct _sycamore_device_t {
	char *name;	

	u32 device_address;
	u16 flags;
	u16 type;

	//read variables

	bool blocking;
	bool write_in_progress;

	//write variables
	sycamore_bus_t *sb;

	//specific device
	void * device;

	//function table
	device_read_func_t 			read;
	device_interrupt_func_t 	interrupt;
	device_destroy_func_t		destroy;

	struct platform_device 		*pdev;
};

struct _sycamore_bus_t {

	bool sycamore_found;

	atomic_t bus_busy;

	struct delayed_work control_work;
	wait_queue_head_t write_wait_queue;

	sycamore_device_t * working_device;
	sycamore_device_t devices[MAX_NUM_DEVICES];
};


//sycamore device
void sycamore_device_init(sycamore_bus_t *sb, sycamore_device_t *sd, u16 type, u16 flags, u32 device_address);
void sycamore_device_destroy(sycamore_device_t *sd);


//********** TO THE UPPER LEVEL (sycamore device) **********
void sycamore_device_read_callback(sycamore_device_t *sd, 
									u32 position,
									u32 start_address,
									u32 total_length,
									u32 size_left,
									u8 * data,
									u32 length);

void sycmaore_device_interrupt(sycamore_device_t *sd, u32 interrupt);


//********** FROM THE UPPER LEVEL (sycamore device) **********
int bus_write(sycamore_device_t *sd, u32 address, u8 * data, u32 size);
void bus_read(sycamore_device_t *sd, u32 address, u32 size);
//read from a device


/*--------------------------------------------------- */
//Bus

int sb_init(sycamore_bus_t * sb); 
void sb_destroy(sycamore_bus_t *sb);


//********** TO THE LOWER LEVEL (sycamore protocol) **********
//write to the FPGA
int sb_sp_write(
				sycamore_bus_t *sb,
				u32 command,
				u8 device_index,
				u32 address,
				u8 * data,
				u32 length);



//********** FROM THE LOWER LEVEL **********
//write from the sycamore protocol layer to here
void sp_sb_read(sycamore_bus_t *sb,
				u32 command,
				u8 device_address,	//device to write to
				u32 offset,			//where in the offset we started
				u32 position,		//position in the read
				u32	total_length,	//total length of data to be read in
				u32 length,			//length of this read
				u32 size_left,
				u8 * data);		//how much more we have to read




#endif //__SYCAMORE_BUS_H__
