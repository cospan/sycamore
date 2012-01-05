//srb.h
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
 * Sycamore Request Block
 * Descrption: much like (almost identical to) the USB request block (URB)
 *	the SRB is a communication block for the sycamore stack, this is used
 *	between the sycamore_bus and the sycamore_protocol layer in order to
 *	keep track of the incomming and outgoing data.
 **/

#ifndef __SYCAMORE_REQUEST_BLOCK_H__
#define __SYCAMORE_REQUEST_BLOCK_H__


#include <linux/types.h>
#include <linux/list.h>

typedef struct _srb_t srb_t;

#define SRB_BUF_SIZE 512


//states (may not even need this)
#define SRB_IDLE 0
#define SRB_BUSY 1

struct _srb_t {

	//state of the SRB
	u32 state;

	//the address of the device that the SRB is from/for
	u32 device_index;
	//start of the address of the data in the FPGA 
	u32 data_address_start;
	//current position of the data within the read/write 
		//(this is for incomplete read/writes)
	u32 current_pos;

	//total number of bytes to be read
	u32 size_of_total_data;
	//number of bytes within this SRB
	u32 size_of_srb_data;


	//command of the data incomming our outgoing
	u32	command;

	//data (in raw bytes)
	u8 data[SRB_BUF_SIZE];

	struct list_head lh;
};


//functions
srb_t * srb_new(void);
void srb_destroy(srb_t * srb);
/**
 * setup an srb with data
 * the return value will indicate how many bytes are within the srb
 * if the return value doesn't match up with the size_of_data then another
 * SRB will be required to send the data
 **/
int srb_setup(	srb_t *srb,
				u32 command,
				u32 device_index,
				u32 data_address_start,
				u32 current_position,
				u32 size_of_data,
				u8 * data);
void srb_reset( srb_t *srb);

u32 srb_get_command(srb_t *srb);
u32	srb_get_device_index(srb_t *srb);
u32 srb_get_start_of_data_address(srb_t *srb);
u32 srb_get_current_data_position(srb_t *srb);
u32 srb_get_total_size_of_data(srb_t *srb);
u32 srb_get_current_srb_data_size(srb_t *srb);
struct list_head * srb_get_list_head(srb_t *srb);
//don't need this, use 'list_entry'
//srb_t * srb_get_srb_from_list_head(struct list_head *lh);

int srb_copy_data_from_srb(srb_t *srb, u32 offset, u8 * data, u32 length);

#endif //__SYCAMORE_REQUEST_BLOCK_H__
