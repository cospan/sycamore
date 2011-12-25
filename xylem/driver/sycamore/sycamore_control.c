//sycamore_control.c

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
#include "sycamore_control.h"
#include "sycamore_commands.h"



bool is_drt_read(sycamore_t *sycamore){
	return (sycamore->drt_state == DRT_READ_SUCCESS);
}

//see if this is a device response
bool is_control_response(sycamore_t *s){
	if (s->read_command == SYCAMORE_READ && 
			(
				(s->read_device_address == 0x00) || (s->read_device_address == 0xFF)
			)
		){
		return true;
	}
	if (s->read_command == SYCAMORE_PING){
		return true;
	}
	return false;
}

bool is_ping_response(sycamore_t *s){
	if (s->read_command == SYCAMORE_PING){
		return true;
	}
	return false;
}

void process_control_response(sycamore_t *s){


	//s->read_size + 1 = size of the entire read
	//s->read_data_pos = position within the read_size + 1
	//s->read_command  = commmand that sycamore returned
	//s->read_data = 32 bit data to read
	//s->read_address = address of read
	//s->read_device_address = address of device to read from


	u32 addr = s->read_address + s->read_data_pos;


	//check if this is a DRT response
	switch (s->read_command) {
		case (SYCAMORE_PING):
			if (s->drt_state == DRT_READ_INIT){
				//initialize a DRT read
				s->drt_state = DRT_READ_START;
			}
			break;
		case (SYCAMORE_READ):
			if (s->read_device_address == 0x00){
				//reading from the DRT
				switch (s->drt_state){
					case (DRT_READ_INIT):
						if (s->drt){
							//erase the current DRT string
							kfree(s->drt);
							s->drt = NULL;
						}
						break;
					//need to read a total of 8 data items
					case (DRT_READ_START):
						if (s->drt_waiting) {
							s->drt_state = DRT_READ_START_WAIT;
						}
						break;
					case (DRT_READ_START_WAIT):
						if (s->drt_waiting) {
							//position
							switch (addr) {
								case (0x00):
									s->drt_version = s->read_data >> 16;
									break;
								case (0x01):
									s->number_of_devices = s->read_data;
									s->size_of_drt = ((s->number_of_devices + 1) * 8 * 4);
									break;
								case (0x02):
//XXX: RFU DRT Implementation
									break;
								case (0x03):
//XXX: RFU DRT Implementation
									break;
								case (0x04):
//XXX: RFU DRT Implementation
									break;
								case (0x05):
//XXX: RFU DRT Implementation
									break;
								case (0x06):
//XXX: RFU DRT Implementation
									break;
								case (0x07):
//XXX: RFU DRT Implementation
									s->drt_state = DRT_READ_ALL;
								break;
								default:
									//processing the rest of the data
									//something wrong here
									s->drt_state = DRT_READ_INIT;
									break;

							}
						}

						break;
					case (DRT_READ_ALL):
						if (s->drt_waiting){
							s->drt_state = DRT_READ_ALL_WAIT;
						}
						break;
					case (DRT_READ_ALL_WAIT):
						//reading the entire DRT right now
						if (addr + 3 < s->size_of_drt){
							s->drt[addr] 		= (u8) (s->read_data & 0x000F);
							s->drt[addr + 1] 	= (u8) (s->read_data & 0x00F0 >> 8);
							s->drt[addr + 2]	= (u8) (s->read_data & 0x0F00 >> 16);
							s->drt[addr + 3]	= (u8) (s->read_data & 0xF000 >> 24);

							//if addr + 3 == s->size_of_drt then we've read everything
						}
						if (addr + 3 == s->size_of_drt){
							s->drt_state = DRT_READ_SUCCESS;
						}

						break;
					case (DRT_READ_SUCCESS):
						//don't do anything
						break;
					default:
						s->drt_state = DRT_READ_INIT;
						break;
						//if addr + 3 == s->size_of_drt then we've read everything
					}
				}
				//check if this is a response to the wishbone_master control
				else if (s->read_device_address == 0xFF){
				//response to a wishbone master control
//XXX: process info from the wishbone master
					//things to process:
						//state machine behavior
						//sycamore main paramters
				}

			break;
		case (SYCAMORE_INTERRUPTS):

//XXX: process interrupts
			
			break;
		default:
			break;
	}
}


//sycamore-bus will send data here to be processed
int sycamore_control_process_read_data(sycamore_t * s, char * buffer, int length){
	int i = 0;
	char ch = 0;
	//since we are talking to the device, we can put off a ping
	s->do_ping = false;
	for(i = 0; i < length; ++i){
		ch = buffer[i];
//		printk ("%c", ch);
		//process each character as it comes in
		if (ch == 'S'){

			printk("\nFound S\n");
		/*
			if the current byte is is 'S' we are starting to read a new packet

			in this case there might be a chance that data didn't get all the way
			through so I might have to tell the current virtual device I'm
			writing to (from the device's point of view reading) that the
			rest of the data transfer was cancelled
		*/
			//reset all variables
			s->read_command 		= 0;
			s->read_size 			= 0;
			s->read_data			= 0;
			s->read_data_count		= 0;
			s->read_data_pos		= 0;
			s->read_address 		= 0;
			s->read_device_address	= 0;
			s->read_pos				= 0;
			s->read_state			= READ_SIZE;
			continue;
		}
		
		switch (s->read_state){
			case (READ_IDLE):
				//nothing to see here, move along
				continue;
				break;
			case (READ_SIZE):
				
				/*
				   the next seven bytes is the number
				   of bytes to read (not including
				   the first 32 bit word
				 */
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				s->read_pos++;
				s->read_size += ch;

				//transition condition
				if (s->read_pos == 7){
					
					//setup the read data count to at least read the first
					//32 bit word
					s->read_data_count = s->read_size + 1;
					s->read_state = READ_COMMAND;
					s->read_pos = 0;
					printk ("%s: read size = %d\n", __func__, s->read_size);
				}
				else {
					//shift the data up by four
					s->read_size = s->read_size << 4;
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
				s->read_command += ch;	
				s->read_pos++;
				//transition condition
				if (s->read_pos == 8){
					/*
					   the next eight bytes is the command
					   inverted from the write
					 */ 
//					 printk("%s: Received command: %8X\n", __func__, s->read_command);
					 s->read_command = ~(s->read_command);
					 switch (s->read_command){
					 	case (SYCAMORE_PING): 
							printk("%s: Received a ping response\n", __func__);
							s->sycamore_found = true;
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
							s->read_command = ~(s->read_command);
							//respond to interrupts
							break;
						default:
							printk("%s: Received an illegal command!, resetting state machine: %8X\n", __func__, s->read_command);
							s->read_state = READ_IDLE;
							continue;
							break;
					 }
					/*
					   if the command was read we will need
					   to read all the data back
					 */

					s->read_pos	=	0;
					s->read_state = READ_ADDRESS;
				}
				else {
					s->read_command = s->read_command << 4;
				}
				break;
			case (READ_ADDRESS):
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				s->read_address += ch;	
				s->read_pos++;

				/*
				   the next eight bytes is the address
				 */
				/*
				   if the address top two bytes == 0
				   then this is a control packet
				   if the address top two bytes == FF
				   then this is a interrupt
				 */

				//transition condition
				if (s->read_pos == 8) {
					s->read_device_address = (s->read_address & 0xFF000000) >> 24;
					s->read_address = (s->read_address & 0x00FFFFFF);
					s->read_state = READ_DATA;
					s->read_pos = 0;
					s->read_data = 0;
				}
				else {
					s->read_address = s->read_address << 4;
				}
				break;
			case (READ_DATA):
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				s->read_data += ch;	
				s->read_pos++;


				/*
				   if the command was a read then we 
				   need to possibly count the data in
				   the first 8 bytes are always there
				 */
				if (s->read_pos == 8){

					s->read_data_count--;
					//process the data out
					if (is_control_response(s)){
						process_control_response(s);
												
					}
//XXX need to write to the associated driver
					else if (s->devices[s->read_device_address] != NULL){
						sycamore_dev_t *dev = (sycamore_dev_t *) platform_get_drvdata(s->devices[s->read_device_address]); 	
//XXX: call the devices read function
						/*
							send the address
							send the total data size
							send the data position
						*/
						//the position is defined in terms of 4 * 8 = 32, and were copying it into a byte array
						int read_buffer_pos = s->read_data_pos << 2;

						if (read_buffer_pos < dev->read_buffer_size){
							//we are not going to do an overrun
							memcpy(&dev->read_buffer[read_buffer_pos], &s->read_data, 4);
						}
						if (s->read_data_count == 0){
							dev->read_address = s->read_address;
							dev->read_address = s->read_size + 1;
							atomic_set(&dev->read_data_ready, 1);
						}
					}

					//see if we are done
					if (s->read_data_count == 0){
						s->read_state = READ_IDLE;
						printk("%s: parsed data\n", __func__);
						printk("c:%8X\n", s->read_command);
						printk("a:%8X : %6X\n", s->read_device_address, s->read_address);
						printk("s:%8d\n", s->read_size + 1);
						printk("d:%.8X\n\n", s->read_data);
					}
					else {
						s->read_pos = 0;
						s->read_data = 0;
						s->read_data_pos++;
					}
				}
				else {
					s->read_data = s->read_data << 4;
				}
				break;
			default:
				/*
				   how did we get here?
				   something went wrong
				 */
				s->read_state = READ_IDLE;
				printk("%s: Entered Illegal state in read state machine", __func__);
				break;
		}
	}

	return 0;
}

/*
 *	sycamore-bus will call this every periodic 
 *	timeout to perform maitenance functions
*/
void sycamore_control_periodic (sycamore_t * sycamore){
	int retval = 0;
	printk("%s: DRT STATE: %d\n", __func__, sycamore->drt_state);
	if (atomic_read(&sycamore->port_lock) == 0){
		switch (sycamore->drt_state){
			case DRT_READ_START:
				sycamore->drt_waiting = true;
				atomic_set(&sycamore->port_lock , 1);
				retval = sycamore_write(sycamore, 
						SYCAMORE_READ, 
							0x00, 
							0x00, 
							NULL, 
							8); 	
				//hopefully get a response in 200 milliseconds
				schedule_delayed_work(&sycamore->work, 200);
				return;
				break;
			case (DRT_READ_START_WAIT):
				sycamore->drt_waiting = false;
				return;
				break;
			case DRT_READ_ALL:
				sycamore->drt_waiting = true;
				if (sycamore->drt == NULL){
					sycamore->drt_waiting = true;
					sycamore->drt = kmalloc( sycamore->size_of_drt, GFP_KERNEL);
					//send a request to receive all of the data
					sycamore_write(	sycamore, 
							SYCAMORE_READ,
							0x00,
							0x00,
							NULL,
							(u32) (sycamore->number_of_devices + 1) * 8); 
				}
				//hopefully get a response in 200 milliseconds
				schedule_delayed_work(&sycamore->work, 200);
				return;
				break;
			case DRT_READ_ALL_WAIT:
				sycamore->drt_waiting = false;
				return;
				break;
			default:
				if (sycamore->do_ping){
					atomic_set(&sycamore->port_lock , 1);
				}

				retval = sycamore_write (sycamore,
								SYCAMORE_PING,
								0,
								0,
								NULL,
								0);
	
				break;
		}
	}
	//schedule the next sycamore_periodic
	schedule_delayed_work(&sycamore->work, sycamore->ping_timeout);
}
void sycamore_write_work(struct work_struct *work){
	//int retval = 0;
	sycamore_t *s = NULL;
	s = container_of(work, sycamore_t, work.work);	

	//this is called from the write callback to handle non critical write functions
	//this is a response to a write request from a s virtual device

	//unlock the port if we don't have anything else to write to the FPGA
	if (s->write_out_count < s->write_out_size){
		//got more data to send out
		printk("sending the rest of the data (%d more bytes)\n", s->write_out_size - s->write_out_count);	
		s->write_out_count += s->write_func(
						s->write_data, 
						&s->write_buffer[s->write_out_count], 
						s->write_out_size - s->write_out_count);
		if (s->write_out_count != s->write_out_size){
		printk("%s: Didn't send all the data out! length of write == %d, length written = %d\n", 
						__func__, 
						s->write_out_size, 
						s->write_out_count);
		}
		else {
			printk("%s: Sent all the rest of the data\n", __func__);
		}
	
	}
	else {
		//finished sending data to the FPGA
		atomic_set(&s->port_lock, 0);
	}
}

int sycamore_write (sycamore_t * sycamore, 
					u32 command, 
					u8 device_address,
					u32 offset,
					char * buffer, 
					u32 length){

	u32 true_data_size = 0;
	sycamore->write_out_count = 0;
	//create the constant size string
	if (length > 0){
		true_data_size = length - 1;	
	}
	
	//horribly slow, but until I find a way around this I'll just copy over everything
	
	//for reading commands and the case where the data doesn't matter
	if ((length == 0) || ((0xFFFF & command) == READ_COMMAND)){
		sycamore->write_out_size = snprintf (&sycamore->write_buffer[0], WRITE_BUF_SIZE, "L%07X%08X%02X%06X%s", 
							true_data_size, 
							command, 
							device_address, 
							offset,
							"00000000");


	}
	else {
		sycamore->write_out_size = snprintf (&sycamore->write_buffer[0], WRITE_BUF_SIZE, "L%07X%08X%02X%06X%s", 
							true_data_size, 
							command, 
							device_address, 
							offset,
							buffer);
	}


	sycamore->write_buffer[sycamore->write_out_size] = 0;
	printk ("%s: length = %d, sending: %s\n", __func__, sycamore->write_out_size, &sycamore->write_buffer[0]);

	if (sycamore->write_func != NULL){
		sycamore->write_out_count = sycamore->write_func(sycamore->write_data, &sycamore->write_buffer[0], sycamore->write_out_size);
		if (sycamore->write_out_count != sycamore->write_out_size){
			printk("%s: Didn't send all the data out! length of write == %d, length written = %d\n", 
				__func__, 
				sycamore->write_out_size, 
				sycamore->write_out_count);
		}
		else {
			printk("%s: Sent all data at once!\n", __func__);
		}



		return sycamore->write_out_size;
	}

/*	
//GOOD FOR DEBUGGIN MULTIPLE SENDS


	out_length = snprintf (&sycamore->write_buffer[0], WRITE_BUF_SIZE, "L%07X%08X%02X%06X", 
							length, 
							command, 
							device_address, 
							offset);


	printk ("Writing the constant size string first: %s", &sycamore->write_buffer[0]);
	if (sycamore->write_func != NULL){
		retval += sycamore->write_func(sycamore->write_data, &sycamore->write_buffer[0], 24);	
	}
	//command that doesn't have data, just send 0's in place of the data
	//mask out the flags for the commands
	if ((length == 0) || (command == (0xFFFF  & READ_COMMAND))){
		printk("00000000\n");
		retval += sycamore->write_func (sycamore->write_data, "00000000", 8);
		return retval;
	}
	printk ("%s\n", buffer);
	//command that has data requires sending the buffer separeately
	if (sycamore->write_data != NULL){
		retval += sycamore->write_func(sycamore->write_data, buffer, length);
		return retval;
	}

*/
	//write function is not defined
	return -1;
}





