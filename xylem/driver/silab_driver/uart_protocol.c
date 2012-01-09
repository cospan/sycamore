//protocol_template.c

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
#include <linux/workqueue.h>
#include "../sycamore/sycamore_protocol.h"
#include "../sycamore/sycamore_bus.h"
#include "../sycamore/sycamore_commands.h"


#define READ_IDLE 			0
#define READ_SIZE 			1
#define READ_COMMAND 		2
#define READ_ADDRESS 		3
#define READ_DATA 			4

#define READ_BUF_SIZE		4

#define ENCODED_BUF_SIZE	512

struct _sycamore_protocol_t {
	//protocol specific data
	void * protocol;

	sycamore_bus_t sb;

	//hardware comm
	hardware_write_func_t write_func;
	void * write_data;

	
	//the current offset within the encoded buffer

	//read information
	int read_state;
	u32 read_command;
	u32	read_data;
	u32 read_size;
	u32 read_data_count;
	u32 read_data_pos;
	u32 read_address;
	u32 read_device_address;
	u32 read_pos;

	u8 read_out_data[READ_BUF_SIZE];

};



//local function prototypes
//sets up everything for a write to the hardware
int hardware_write (sycamore_protocol_t * sp,
					u32 command,
					u8 device_address,
					u32 offset,
					char * buffer,
					u32 length);


int encode_buffer(	u8 * enc_buffer,
					u8 * buffer_in, 
					int * enc_buffer_size, 
					int in_buffer_size, 
					int max_enc_buffer_size);
/**
 * protocol_template
 * Description: Modify this file to adapt a new hardware interconnect
 *
 */

typedef struct _my_protocol_t my_protocol_t;

struct _my_protocol_t {
	//update this variable to reflect the status of the command
	int command_status;
};



/**
 * sycamore_protocol_init
 * Description: initialize the hardware specific protocol
 *	modify the between CUSTOM_START, CUSTOM_END
 *
 * Return:
 *	returns an initialized sycamore_protocol_t structure
 *	NULL on failue
 **/
sycamore_protocol_t * sp_init(void){
	//don't change!	
	sycamore_protocol_t *sp = NULL;
	my_protocol_t *mp = NULL;

	printk("%s: (sycamore) initializing the protocol specific driver\n", __func__);
	//allocate space for the sycamore_protocol_t structure
	sp = (sycamore_protocol_t *) kzalloc(sizeof(sycamore_protocol_t), GFP_KERNEL);
	if (sp == NULL){
		//failed to allocate memory for sycamore_protocol
		goto fail2;
	}
	//allocate space for your specific protocol here
	mp = (my_protocol_t *) kzalloc(sizeof(my_protocol_t), GFP_KERNEL);
	if (mp == NULL){
		//failed to allocate memory for my_protocol_t
		goto fail1;
	}


	sp->write_data			= NULL;
	sp->write_func			= NULL;

	sp->read_command 		= 0;
	sp->read_size 			= 0;
	sp->read_data			= 0;
	sp->read_data_count		= 0;
	sp->read_data_pos		= 0;
	sp->read_pos			= 0;
	sp->read_address 		= 0;
	sp->read_device_address	= 0;
	sp->read_state			= READ_IDLE;
	memset (&sp->read_out_data[0], 0, READ_BUF_SIZE);


	//CUSTOM_START

	//initialize your variables here

	//CUSTOM_END

	sb_init(&sp->sb);

	return sp;

fail1:
	kfree(sp);
fail2:
	return NULL;
}


/**
 * sycamore_destroy
 * Description: cleans and removes anything that was done within init
 *
 * Return:
 *	nothing
 **/
void sp_destroy(sycamore_protocol_t *sp){
	//CUSTOM_START
	//stop anything you need to stop here, deallocate anything here
	//CUSTOM_END
	//free the custom protocol stuff
		
	printk("%s: (sycamore) destroy the protocol specific driver\n", __func__);


	kfree(sp->protocol);
	kfree(sp);
}

/**
 * sp_set_write_function
 * Description: sets the driver specific write function, this is what
 *	all the functions will use to write to the FPGA
 *
 * Return:
 *	nothing
 **/
void sp_set_write_function(
						sycamore_protocol_t *sp, 
						hardware_write_func_t write_func, 
						void *data){
	printk("%s: (sycamore) setting the write function to %p\n", __func__, write_func);
	sp->write_func = write_func;
	sp->write_data = data;
}



/**
 * sp_read_data
 * Description: reads the data from the low level driver
 *	some drivers send data in a 'peice meal' fashion so
 *	this function will accept all or part of the data received
 *	and put it together for the higher level functions

 *
 * Return:
 *	Nothing
 */
void sp_hardware_read(		
						sycamore_protocol_t *sp, 
						char *buffer, 
						int length){
	int i = 0;
	int ch = 0;
	int read_buffer_pos = 0; 
//	printk("%s: (sycamore) entered\n", __func__);
//XXX: I forgot why I needed to do '++i'
	for (i = 0; i < length; ++i){
		ch = buffer[i];
		if (ch == 'S'){
			printk("%s: Found S\n", __func__);
			//reset all variables
			sp->read_command		=	0;
			sp->read_size			=	0;
			sp->read_data			=	0;
			sp->read_data_count		=	0;
			sp->read_data_pos		=	0;
			sp->read_address		=	0;
			sp->read_device_address	=	0;
			sp->read_pos			=	0;
			sp->read_state			=	READ_SIZE;
			continue;
		}
		//read state machine
		switch (sp->read_state){
			case (READ_IDLE):
				//waiting for an 'S'
				continue;
				break;
			case (READ_SIZE):
				/* 
					next seven bytes is the nubmer of bytes to read
					not including the first 32 bit dword
				*/

				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				sp->read_pos++;
				sp->read_size += ch;

				//transition condition
				if (sp->read_pos == 7){
					
					//setup the read data count to at least read the first
					//32 bit word
					sp->read_data_count = sp->read_size + 1;
					sp->read_state = READ_COMMAND;
					sp->read_pos = 0;
					printk ("%s: read size = %d\n", __func__, sp->read_size);
				}
				else {
					//shift the data up by four
					sp->read_size = sp->read_size << 4;
				}
				break;
			case (READ_COMMAND):
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				sp->read_command += ch;	
				sp->read_pos++;
				//transition condition

				if (sp->read_pos == 8){
					 sp->read_command = ~(sp->read_command);
					 switch (sp->read_command){
					 	case (SYCAMORE_PING): 
							printk("%s: Received a ping response\n", __func__);
							break;
						case (SYCAMORE_WRITE):
							printk("%s: Received a write ack\n", __func__);
							break;
						case (SYCAMORE_READ):
							printk("%s: Received a read response\n", __func__);
							break;
						case (~SYCAMORE_INTERRUPTS):
							//this is the only command that isn't inverted
							printk("%s: Received an interrupt\n", __func__);
							sp->read_command = ~(sp->read_command);
							//respond to interrupts
							break;
						default:
							printk("%s: Received an illegal command!, resetting state machine: %8X\n", __func__, sp->read_command);
							sp->read_state = READ_IDLE;
							continue;
							break;
					 }
					/*
					   if the command was read we will need
					   to read all the data back
					 */

					sp->read_pos	=	0;
					sp->read_state = READ_ADDRESS;
				}
				else {
					sp->read_command = sp->read_command << 4;
				}
				break;
			case (READ_ADDRESS):
				/*
				   the next eight bytes is the address
				 */
				/*
				   if the address top two bytes == 0
				   then this is a control packet
				   if the address top two bytes == FF
				   then this is interrupts
				 */
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				sp->read_address += ch;	
				sp->read_pos++;

				//transition condition
				if (sp->read_pos == 8) {
					sp->read_device_address = (sp->read_address & 0xFF000000) >> 24;
					sp->read_address = (sp->read_address & 0x00FFFFFF);
					sp->read_state = READ_DATA;
					sp->read_pos = 0;
					sp->read_data = 0;
				}
				else {
					sp->read_address = sp->read_address << 4;
				}
				break;
			case (READ_DATA):
				/*
				   if the command was a read then we 
				   need to possibly count the data in
				   the first 8 bytes are always there
				 */
	
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				sp->read_data += ch;	
				sp->read_pos++;
				if (sp->read_pos == 8){

					sp->read_data_count--;
					sp->read_out_data[0] = (u8) (0x0FF & (sp->read_data >> 24));
					sp->read_out_data[1] = (u8) (0x0FF & (sp->read_data >> 16));
					sp->read_out_data[2] = (u8) (0x0FF & (sp->read_data >> 8));
					sp->read_out_data[3] = (u8) (0x0FF & sp->read_data);
					printk("%s: (sycamore) %08X: %4X, %4X, %4X, %4X\n",
											__func__,
											sp->read_data,
											sp->read_out_data[0],
											sp->read_out_data[1],
											sp->read_out_data[2],
											sp->read_out_data[3]);
					//send data up to the bus one double word at a time
					sp_sb_read(	&sp->sb,
								sp->read_command,
								sp->read_device_address,
								sp->read_address,
								sp->read_data_pos,
								sp->read_size + 1,
								READ_BUF_SIZE,
								sp->read_data_count,
								&sp->read_out_data[0]);
							/*
							the position is defined in terms of 4 * 8 = 32
							and were copying it into a byte array
							*/
					read_buffer_pos = sp->read_data_pos << 2;
/*
					if (sp->read_data_count == 0){
//XXX: tell the sycamore bus we are done with a read
//						dev->read_address = sp->read_address;
//						dev->read_address = sp->read_size + 1;
					}
*/
					if (sp->read_data_count == 0){
						sp->read_state = READ_IDLE;
						printk("%s: parsed data\n", __func__);
						printk("c:%8X\n", 
										sp->read_command);
						printk("a:%8X : %6X\n", 
										sp->read_device_address, 
										sp->read_address);
						printk("s:%8d\n", 
										sp->read_size + 1);
						printk("d:%.8X\n\n", 
										sp->read_data);

					}
					else {
						sp->read_pos = 0;
						sp->read_data = 0;
						sp->read_data_pos++;
					}
				}
				else {
					//shift everything up a nibble
					sp->read_data = sp->read_data << 4;
				}
				break;
			default:
				/*
				   how did we get here?
				   something went wrong
				 */
				sp->read_state = READ_IDLE;
				printk("%s: Entered Illegal state in read state machine", __func__);
				break;
		}
	}
}


int sb_sp_write(
		sycamore_bus_t *sb,
		u32 command,
		u8 device_address,
		u32 offset,
		u8 * out_buffer,
		u32 length){

	sycamore_protocol_t *sp = NULL;
	int retval = 0;

	printk("%s: (sycamore) entered\n", __func__);
	sp = container_of(sb, sycamore_protocol_t, sb); 

	//it might be a good idea to zero out the encoded buffer
	retval = hardware_write (
				sp,
				command,
				device_address,
				offset,
				out_buffer,
				length);


	return retval;
}

/**
 * hardware write
 * Description: write raw bytes to the hardware driver
 *
 * Return:
 *	number of bytes written
 *	-1 if there is no hardware write function setup
 **/
int hardware_write (
				sycamore_protocol_t * sp,
				u32 command,
				u8 device_address,
				u32 address,
				char * write_buffer,
				u32 length){

	u32 buffer_size;
	u32 buffer_offset;
	u8 buffer[ENCODED_BUF_SIZE];

	u32 data_offset = 0;
	u32 data_size = 0;

//XXX:this might change in future versions of the UART protocol
	u32 true_data_size = 0;


	printk("%s: (sycamore) entered\n", __func__);

	printk("%s: (sycamore) length: %d\n", __func__, length);
	if (length > 0){
		true_data_size = length / 8;
		true_data_size -= 1;
	}

	//use the first encoded buffer to write the data out

	//for reading command and the case where data doesn't matter
	if ((length == 0) || ((0xFFFF & command) == SYCAMORE_READ)){
		buffer_size = snprintf(
						&buffer[0], 
						ENCODED_BUF_SIZE, 
						"L%07X%08X%02X%06X%s",
						true_data_size,
						command,
						device_address,
						address,
						"00000000");
	}
	else {
		buffer_size = snprintf (
						&buffer[0], 
						ENCODED_BUF_SIZE, 
						"L%07X%08X%02X%06X", 
						true_data_size, 
						command, 
						device_address, 
						address);
		//that will be handled by handled after
	}

	buffer[buffer_size] = 0;
	printk ("%s: length = %d, sending: %s\n", 
			__func__, 
			buffer_size, 
			buffer);


	if (sp->write_func != NULL){
		data_offset = 0;

		//spin until we send it all
		while (data_offset < buffer_size){
			buffer_size -= data_offset;
			data_offset = sp->write_func(
						sp->write_data, 
						&buffer[data_offset], 
						buffer_size);
		}
		//if we have a read funciton were done!
	
		if ((length == 0) || ((0xFFFF & command) == SYCAMORE_READ)){
			return 0;
		}
		//spin until we send all the data
		data_size = length;	
		data_offset = 0;
		while (data_offset < data_size){
			data_size -= data_offset;
			data_offset += encode_buffer(&buffer[0], write_buffer, &buffer_size, data_size, ENCODED_BUF_SIZE);

			buffer_offset = 0;
			while (buffer_offset < buffer_size){
				buffer_size -= buffer_offset;	
				buffer_offset = sp->write_func(
								sp->write_data,
								&buffer[buffer_offset],
								buffer_size);
			}

		}
		
		//need to make sure we align this data to a double word (x4)
		data_size = length % 4;
		if (data_size > 0){
			memset(&buffer[0], '0', data_size);
			data_offset = 0;
			while (data_offset < data_size){
				data_size -= data_offset;
				data_offset = sp->write_func (
									sp->write_data,
									&buffer[data_offset],
									data_size);
			}
		}

		return buffer_size;
	}

	//write function is not defined
//XXX: need to handle this error function
	return -1;
}



/**
 * encode_buffer
 * Description: encodes data for the UART protocol
 *
 *	enc_buffer: encoded data buffer
 *	buffer_in: raw incomming data
 *	enc_buffer_size: size of the encoded buffer
 *	in_buffer_size: size of the in buffer
 *	max_enc_buffer_size: maximum size of the encoded buffer
 *
 * Return: size of incomming buffer used this can be used as the offset into the input buffer
 **/ 

int encode_buffer(u8 * enc_buffer, u8 * buffer_in, int * enc_buffer_size, int in_buffer_size, int max_enc_buffer_size){
	int i = 0;	
	int length;
	int buffer_index;
	u8 top_nibble;
	u8 bottom_nibble;

	printk("%s: (sycamore) entered\n", __func__);

	length = in_buffer_size * 2;
	if (max_enc_buffer_size < in_buffer_size * 2){
		length = max_enc_buffer_size;
	}

	for (i = 0; i < length; i++){
		buffer_index = i * 2;
		
		top_nibble = buffer_in[i] >> 4;
		bottom_nibble = buffer_in[i] & 0xF;

		if (top_nibble > 0x0A){
			top_nibble += ('A' - 10);
		}
		else {
			top_nibble += '0';
		}
		
		if (bottom_nibble > 0x0A){
			bottom_nibble += ('A' - 10);
		}
		else {
			bottom_nibble += '0';
		}

		enc_buffer[buffer_index] = top_nibble;
		enc_buffer[buffer_index + 1] = bottom_nibble;
	}
	*enc_buffer_size = length;
	return length / 2;
}


