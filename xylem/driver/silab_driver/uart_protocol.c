//protocol_template.c
#include <linux/kernel.h>
#include <linux/slab.h>
#include "../sycamore/sycamore_protocol.h"
#include "../sycamore/sycamore_bus.h"
#include "../sycamore/sycamore_commands.h"


#define READ_IDLE 			0
#define READ_SIZE 			1
#define READ_COMMAND 		2
#define READ_ADDRESS 		3
#define READ_DATA 			4

struct _sycamore_protocol_t {
	//protocol specific data
	void * protocol;

	sycamore_bus_t * sb;

	//hardware comm
	hardware_write_func_t write_func;
	void * write_data;

	//write data
	int write_out_count;
	int write_out_size;
	char write_buffer[WRITE_BUF_SIZE];


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
};



//local function templates
int hardware_write (
				sycamore_protocol_t * sp,
				u32 command,
				u8 device_address,
				u32 offset,
				char * buffer,
				u32 length);


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

	printk("%s: initializing the protocol specific driver\n", __func__);
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

	sp->write_out_count		= 0;
	sp->write_out_size		= 0;

	sp->read_command 		= 0;
	sp->read_size 			= 0;
	sp->read_data			= 0;
	sp->read_data_count		= 0;
	sp->read_data_pos		= 0;
	sp->read_pos			= 0;
	sp->read_address 		= 0;
	sp->read_device_address	= 0;
	sp->read_state			= READ_IDLE;
	memset (&sp->write_buffer[0], 0, WRITE_BUF_SIZE);
	//CUSTOM_START

	//initialize your variables here

	//CUSTOM_END
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
	printk("%s: setting the write function to %p\n", __func__, write_func);
	sp->write_func = write_func;
	sp->write_data = data;
}



/**
 * sp_write_callback
 * Description: called when a write has been completed
 *	if there is a long write, then this is used to send the rest of 
 *	the rest of the data
 *
 * Return:
 *	Nothing
 **/
void sp_write_callback(sycamore_protocol_t *sp){
	printk("%s: entered\n", __func__);
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
	printk("%s: entered\n", __func__);
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
				   then this is a interrupt
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
//XXX need to indicate that there is data read to the sycamore_bus

					if (sp->sb != NULL){
					
						if (sp->read_command == SYCAMORE_INTERRUPTS){
							sb_interrupt(sp->sb, sp->read_data);		
							continue;
						}
						if (sp->read_command == SYCAMORE_PING){
							sb_ping_response(sp->sb);
							continue;
						}
//					sb_read(sp->sb, 
//XXX: send one double word at a time to the sycamore bus
						/*
							send the address
							send the total data size
							send the data position
							the position is defined in terms of 4 * 8 = 32
							and were copying it into a byte array
						*/
						read_buffer_pos = sp->read_data_pos << 2;
						if (sp->read_data_count == 0){
//XXX: tell the sycamore bus we are done with a read
//							dev->read_address = sp->read_address;
//							dev->read_address = sp->read_size + 1;
						}
					}
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


int sp_write(
		sycamore_protocol_t *sp,
		u8 device_address,
		u32 offset,
		char * out_buffer,
		u32 length){
	int retval = 0;
	printk("%s: entered\n", __func__);
	retval = hardware_write (
				sp,
				SYCAMORE_WRITE,
				device_address,
				offset,
				out_buffer,
				length);
	
	return retval;
}

/**
 * sp_read
 * Description:
 *	send a read request data from the FPGA
 *
 * Return:
 *	nothing
 **/
void sp_read(
		sycamore_protocol_t *sp,
		u8 device_address,
		u32 offset,
		char * out_buffer,
		u32 length){

	int retval = 0;
	printk("%s: entered\n", __func__);
	retval = hardware_write (
				sp,
				SYCAMORE_READ,
				device_address,
				offset,
				out_buffer,
				length);
}

/**
 * sp_ping
 * Description: ping the FPGA
 *
 * Return:
 *	nothing
 **/
void sp_ping(	sycamore_protocol_t *sp){
	printk("%s: entered\n", __func__);
	hardware_write(	sp,
					SYCAMORE_PING,
					0,
					0,
					NULL,
					0);
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
				u32 offset,
				char * buffer,
				u32 length){
	u32 true_data_size = 0;

	if (length > 0){
		true_data_size = length - 1;
	}

	/*
		horribly slow, but I until I figure out a way around this I'll
		just copy everything over to a local buffer
	*/

	//for reading command and the case where data doesn't matter
	if ((length == 0) || ((0xFFFF & command) == SYCAMORE_READ)){
		sp->write_out_size = snprintf(
						&sp->write_buffer[0], 
						WRITE_BUF_SIZE, 
						"L%07X%08X%02X%06X%s",
						true_data_size,
						command,
						device_address,
						offset,
						"00000000");
	}
	else {
		sp->write_out_size = snprintf (
						&sp->write_buffer[0], 
						WRITE_BUF_SIZE, 
						"L%07X%08X%02X%06X%s", 
						true_data_size, 
						command, 
						device_address, 
						offset,
						buffer);
	}

	sp->write_buffer[sp->write_out_size] = 0;
	printk ("%s: length = %d, sending: %s\n", 
			__func__, 
			sp->write_out_size, 
			&sp->write_buffer[0]);


	if (sp->write_func != NULL){
		sp->write_out_count = sp->write_func(
								sp->write_data, 
								&sp->write_buffer[0], 
								sp->write_out_size);

		if (sp->write_out_count != sp->write_out_size){
			printk("%s: Didn't send all the data out! length of write == %d, length written = %d\n", 
				__func__, 
				sp->write_out_size, 
				sp->write_out_count);
		}
		else {
			printk("%s: Sent all data at once!\n", __func__);
		}

		return sp->write_out_size;
	}

	//write function is not defined
	return -1;
}
