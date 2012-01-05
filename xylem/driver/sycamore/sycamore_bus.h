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
#include <linux/list.h>
#include <linux/wait.h>
#include "srb.h"

#define MAX_NUM_DEVICES 256

#define NUM_OF_SRBS 4

typedef struct _sycamore_device_t sycamore_device_t;
typedef struct _sycamore_bus_t sycamore_bus_t;

struct _sycamore_device_t {
	char *name;	

	u32 index;
	u16 flags;
	u16 type;

	//read variables

	bool blocking;
	bool write_in_progress;

	//write variables
	sycamore_bus_t *sb;
};

struct _sycamore_bus_t {

	bool sycamore_found;

	atomic_t bus_busy;
	//device rom table
//	int drt_state;
//	int size_of_drt;
//	char *drt;	

	//srb lists
	struct list_head available_queue;
	struct list_head ready_queue;
	//so we always have a link to the SRB's
	struct list_head busy_queue;


	struct work_struct control_work;
	wait_queue_head_t write_wait_queue;

	void * sleeping_context;
	sycamore_device_t * working_device;
	
	sycamore_device_t devices[MAX_NUM_DEVICES];
};


//srb queue functions

//sycamore bus
int sb_init(sycamore_bus_t * sb); 
void sb_destroy(sycamore_bus_t *sb);

//sycamore device
void sd_init(sycamore_device_t *sd);
void sd_destroy(sycamore_device_t *sd);


//********** TO THE UPPER LEVEL (sycamore device) **********
void sb_sd_read(sycamore_device_t *sd, int size);
void sb_sd_interrupt(sycamore_device_t *sd);


//********** FROM THE UPPER LEVEL (sycamore device) **********
int sd_sb_write(sycamore_device_t *sd, u32 address, u8 * data, u32 size);
void sd_sb_read(sycamore_device_t *sd, u32 address, u32 size);
//read from a device



//********** TO THE LOWER LEVEL (sycamore protocol) **********
//write to the FPGA
int sb_sp_write_start(
				sycamore_bus_t *sb,
				u32 command,
				u8 device_index,
				u32 address,
				u32 length);

//called from the write callback
int sb_sp_write_srb(	
				srb_t *srb);



//********** FROM THE LOWER LEVEL **********
//a ping response from the FPGA
void sp_sb_ping_response(
				sycamore_bus_t *sb);
//interrupts
void sp_sb_interrupt(
				sycamore_bus_t *sb,
				u32 interrupts);

//write from the sycamore protocol layer to here
void sp_sb_read(sycamore_bus_t *sb,
				u8 device_address,	//device to write to
				u32 offset,			//where in the offset we started
				u32 position,		//position in the read
				u32 length,			//length of this read
				u32 size_left);		//how much more we have to read


void sp_sb_write_callback(sycamore_bus_t *sb);


#endif //__SYCAMORE_BUS_H__
