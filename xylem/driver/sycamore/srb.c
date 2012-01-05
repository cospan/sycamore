//srb.c

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


#include <linux/kernel.h>
#include <linux/slab.h>
#include "srb.h"

/**
 * srb_new
 * Description: create a new SRB
 *
 * Return:
 *	if successful, a newly initialized SRB
 *	if an allocation error occured then NULL will be returned
 */
srb_t * srb_new(void){
	srb_t *srb = NULL;
	printk("%s: entered\n", __func__);

	srb = (srb_t *) kzalloc(sizeof(srb_t), GFP_KERNEL);

	if (srb == NULL){
		return NULL;
	}

	//initialize everything
	srb->state = SRB_IDLE;
	srb->device_index = 0;	
	srb->data_address_start = 0;
	srb->current_pos = 0;
	srb->size_of_total_data = 0;
	srb->size_of_srb_data = 0;
	srb->command = 0;
	memset(&srb->data[0], 0, SRB_BUF_SIZE);

	INIT_LIST_HEAD(&srb->lh);

	return srb;
}
void srb_destroy(srb_t * srb){
	printk("%s: entered\n", __func__);
	kfree(srb);
}

/**
 * srb_setup
 * Description: setup an srb with data
 *	the return value will indicate how many bytes are within the srb
 *	if the return value doesn't match up with the size_of_data then another
 *	SRB will be required to send all the data
 *
 * Return:
 *	the number of bytes within the SRB
 *	a negative value will be returned if an error occured
 **/
int srb_setup(	srb_t *srb,
				u32 command,
				u32 device_index,
				u32 data_address_start,
				u32 current_position,
				u32 size_of_data,
				u8 * data){
	printk("%s: entered\n", __func__);

	return 0;
}

/**
 * srb_reset
 * Description: clear out a SRB so that it will be ready for the next job
 *
 * Return:
 *	Nothing
 **/
void srb_reset( srb_t *srb){
	srb->state = SRB_IDLE;
	srb->device_index = 0;	
	srb->data_address_start = 0;
	srb->current_pos = 0;
	srb->size_of_total_data = 0;
	srb->size_of_srb_data = 0;
	srb->command = 0;
	//don't want to do an expensive memset command when I don't have to
	srb->data[0] = 0;
}

//getters
//	(these should probably be changed to inline static functions in the future)
u32 srb_get_command(srb_t *srb){
	printk("%s: entered\n", __func__);
	return srb->command;
}
u32	srb_get_device_index(srb_t *srb){
	printk("%s: entered\n", __func__);
	return srb->device_index;
}
u32 srb_get_start_of_data_address(srb_t *srb){
	printk("%s: entered\n", __func__);
	return srb->data_address_start;
}
u32 srb_get_current_data_position(srb_t *srb){
	printk("%s: entered\n", __func__);
	return srb->current_pos;
}
u32 srb_get_total_size_of_data(srb_t *srb){
	printk("%s: entered\n", __func__);
	return srb->size_of_total_data;
}
u32 srb_get_current_srb_data_size(srb_t *srb){
	printk("%s: entered\n", __func__);
	return srb->size_of_srb_data;
}

/**
 * srb_copy_data_from_srb
 * Description: copies data from the SRB's data buffer to the one
 *	supplied. Attempts to copy over the 'length' of data.
 *	the returned value indicates the total number of bytes copied
 *
 * Parameters:
 *	offset: offset into this SRB data of where to start reading data
 *	data: where to copy the data to
 *	length: total number of bytes to copy
 *
 * Return:
 *	total number of bytes copied from the SRB buffer
 **/
int srb_copy_data_from_srb(srb_t *srb, u32 offset, u8 * data, u32 length){
	printk("%s: entered\n", __func__);
	if (length > (srb->size_of_srb_data - offset)){
		length = (srb->size_of_srb_data - offset);	
	}

	memcpy(data, &srb->data[offset], length);
	return length;
}



//list stuff
/**
 * srb_get_list_head
 * Description: get the list_head structure from the srb
 *
 * Return:
 *	struct list_head pointer
 **/
struct list_head * srb_get_list_head(srb_t *srb){
	return &srb->lh;
}
/*
srb_t * srb_get_srb_from_list_head(struct list_head *lh){
	return container_of(lh, srb_t, lh);
}
*/


