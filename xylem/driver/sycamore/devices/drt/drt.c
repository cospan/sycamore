//drt.c

#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include "drt.h"


//DRT state machine variable
#define DRT_READ_IDLE 			0
#define DRT_READ_START			1
#define DRT_READ_START_RESPONSE	2
#define DRT_READ_ALL			3
#define DRT_READ_ALL_RESPONSE	4
#define DRT_READ_SUCCESS 		5
#define DRT_READ_FAIL			6

struct _drt_t {

	u16 version;
	u32 number_of_devices;
	u32 drt_size;
	char * drt;	

	//state machine control
	u32 drt_state;

	sycamore_device_t *sd;

};

void drt_destroy(	sycamore_device_t *sd);
void drt_interrupt (sycamore_device_t *sd, u32 interrupt);

void drt_state_machine(	drt_t * drt, 
						u32 start_address,
						u32 position,
						u32 total_length,
						u32 size_left,
						u8 *data,
						u32 length){

	int i = 0;
	u32 addr = 0;
	u32 dw_data = 0;
	u32 dw_length = 0;
	u32 pos = 0;

	printk("%s: (sycamore) entered\n", __func__);


//XXX:data usually comes in as a 32bit set, or 4 data bytes

	if (length % 4){
		printk("%s: (sycamore) data is not a block of 4?\n", __func__);
		return;
	}
	dw_length = length / 4;

		switch (drt->drt_state){
			case (DRT_READ_IDLE):
				printk("%s: (sycamore) DRT Idle\n", __func__);
				//reset the DRT
				if (drt->drt != NULL){
					kfree(drt->drt);
					drt->drt = NULL;
				}
				drt->drt_size = 0;
				break;
			case (DRT_READ_START):
				printk("%s: (sycamore) DRT start\n", __func__);
				if (drt->drt != NULL){
					kfree(drt->drt);
					drt->drt = NULL;
				}
				drt->drt_size = 0;
				//initiate a request for the first 8 double words from the DRT
				bus_read(	drt->sd, 
							0x00, 
							DRT_TOC_SIZE * 8);
	
				drt->drt_state = DRT_READ_START_RESPONSE;
				return;
				break;
			case (DRT_READ_START_RESPONSE):
				printk("%s: (sycamore) DRT reading Table of Contents\n", __func__);
				for (i = 0; i < dw_length; i++){
					pos = i * 4;	

					addr = start_address + position;
					dw_data = (data[pos] << 24) | (data[pos + 1] << 16) | (data[pos + 2] << 8) | (data[pos + 3]);
					printk("%s: (sycamore) DRT TOC: Data: %4X %4X %4X %4X\n", __func__, data[pos], data[pos + 1], data[pos + 2], data[pos + 3]);
					printk("%s: (sycamore) DRT TOC: Data: %08X, Address: %08X\n", __func__, dw_data, addr);


					//received a response
					//start parsing all the data for the entire read

					switch (addr) {
						case (0x00):
							drt->version = dw_data >> 16;
							break;
						case (0x01):
							drt->number_of_devices = dw_data;
							drt->drt_size = ((drt->number_of_devices + 1) * 8 * 8);
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
							//we now have the number of devices in the DRT initiate a read for
							//the rest of the DRT data
							//allocate for all the space were going to need and send a request for
							//all the data


							printk("%s: (sycamore) ready to request all data size: %d\n", __func__, drt->drt_size);

							if (drt->drt != NULL){
								kfree(drt->drt);
								drt->drt = NULL;
							}

							
							drt->drt = kmalloc( drt->drt_size, GFP_KERNEL);
							memset(drt->drt, 0, drt->drt_size);

							bus_read(	drt->sd, 
										0x00, 
										drt->drt_size);

							drt->drt_state = DRT_READ_ALL_RESPONSE;
							break;
						default:
							//processing the rest of the data
							//something wrong here
							drt->drt_state = DRT_READ_IDLE;
							break;
					}
				}

				break;
			case (DRT_READ_ALL_RESPONSE):
				printk("%s: (sycamore) DRT reading all data\n", __func__);
				for (i = 0; i < dw_length; i++){
					pos = i * 4;	

					addr = start_address + position;
					dw_data = (data[pos] << 24) | (data[pos + 1] << 16) | (data[pos + 2] << 8) | (data[pos + 3]);

					printk("%s: (sycamore) DRT address: %08X, data: %08X\n", __func__, addr, dw_data);

					//receiving a response for all the data in the DRT
					sprintf (&drt->drt[addr * 8], "%08X", dw_data);

					//start putting the data into the DRT at the appropriate location

					printk("%s: (sycamore) DRT drt_size:%d\n", __func__, drt->drt_size);
					//if we got all the data go to success, otherwise go to fail
					if (addr == ((drt->drt_size / 8) - 1)){
						printk("%s Read all the DRT data!\ndrt:\n\n", __func__);
						for (i = 0; i < ((drt->number_of_devices + 1) * 8); i++){
							printk("%2d: %c%c%c%c%c%c%c%c\n", i, 
								drt->drt[(i * 8)], 
								drt->drt[(i * 8) + 1], 
								drt->drt[(i * 8) + 2], 
								drt->drt[(i * 8) + 3], 
								drt->drt[(i * 8) + 4], 
								drt->drt[(i * 8) + 5], 
								drt->drt[(i * 8) + 6], 
								drt->drt[(i * 8) + 7]);
						}
						drt->drt_state = DRT_READ_SUCCESS;
					}
				}

				break;
			case (DRT_READ_SUCCESS):
				printk("%s: (sycamore) DRT read success!\n", __func__);
				break;
			case (DRT_READ_FAIL):
				printk("%s: (sycamore) DRT reading fail\n", __func__);
				//tell the bus we failed to get all the data
				break;
			default:
				drt->drt_state = DRT_READ_IDLE;
//XXX:something went wrong, most likely we need to restart the DRT STATE MACHINE
				break;
	}
}


void *drt_init(		sycamore_device_t *sd,
					const char * name){
	drt_t *drt = NULL;
//	struct platform_device * parent = NULL;
	printk("%s: (sycamore) entered\n", __func__);
	drt = (drt_t *) kzalloc(sizeof(drt_t), GFP_KERNEL);
	if (drt == NULL){
		return NULL;
	}

	drt->drt_size = 0;
	drt->drt = NULL;
	drt->drt_state = DRT_READ_IDLE;
	drt->sd = sd;

	sd->device = drt;
	sd->read = drt_read;
	sd->interrupt = drt_interrupt;
	sd->destroy = drt_destroy;
//	parent = get_sycamore_bus_pdev(sd->sb);
	sd->pdev = platform_device_register_resndata( 
											NULL,
											name,
											-1,
											NULL,
											0,
											sd,
											1);
	return drt;
}

void drt_destroy(	sycamore_device_t *sd){
	drt_t *drt = NULL;
	drt = (drt_t *) sd->device;
	printk("%s: (sycamore) entered\n", __func__);

	//unregister the platform from the sycamore bus
	platform_device_unregister(sd->pdev);
	if (drt->drt != NULL){
		kfree(drt->drt);
		drt->drt = NULL;
	}
	drt->drt_size = 0;
}

int drt_read 	(	void * device,
					u32 position,
					u32 start_address,
					u32 total_length,
					u32	size_left,
					u8 	*data,
					u32	length){
	drt_t *drt = NULL;

	printk("%s: (sycamore) entered\n", __func__);

	drt = (drt_t *) device;
	drt_state_machine (		drt, 
							start_address,
							position,
							total_length,
							size_left,
							data,
							length);

	return 0;
}
void drt_interrupt (sycamore_device_t *sd, u32 interrupt){
	//don't response to an interrupt
}



//sycamore bus interface
bool drt_finished (sycamore_device_t * sd){
	drt_t *drt = NULL;
	printk("%s: (sycamore) entered\n", __func__);
	drt = sd->device;

	return (drt->drt_state == DRT_READ_SUCCESS || drt->drt_state == DRT_READ_FAIL);
}
bool drt_success (sycamore_device_t * sd){
	drt_t *drt = NULL;
	printk("%s: (sycamore) entered\n", __func__);
	drt = sd->device;

	return (drt->drt_state == DRT_READ_SUCCESS);
}

bool drt_working (sycamore_device_t * sd){
	drt_t *drt = NULL;
	printk("%s: (sycamore) entered\n", __func__);
	drt = sd->device;

	return !(drt->drt_state == DRT_READ_IDLE);
}

void drt_reset(sycamore_device_t *sd){
	drt_t *drt = NULL;
	printk("%s: (sycamore) entered\n", __func__);
	drt = sd->device;

	drt->drt_state = DRT_READ_IDLE;
	drt_state_machine(drt, 0, 0, 0, 0, NULL, 0);
}

void drt_start(sycamore_device_t *sd){
	drt_t *drt = NULL;
	drt = sd->device;

	printk("%s: (sycamore) entered\n", __func__);

	drt->drt_state = DRT_READ_START;
	drt_state_machine(drt, 0, 0, 0, 0, NULL, 0);
}

int drt_get_number_of_devices(sycamore_device_t *sd){
	drt_t *drt = NULL;
	drt = sd->device;

	printk("%s: (sycamore) entered\n", __func__);

	return drt->number_of_devices;
}

u32 hstring_to_num(char * str, int length){
	int i = 0;
	u32 num = 0;
	for (i = 0; i < length; i++){
		num *= 16;
		if (str[i] >= 'A'){
			num += str[i] - ('A' + 10); 
		}
		else {
			num += str[i] - '0';
		}
	}
	return num;
}

int drt_get_device_data(		sycamore_device_t *sd,
								int dev_index,
								u32 *type,
								u32 *flags,
								u32 *size,
								u32 *device_address){

	drt_t *drt = NULL;
	int offset = 0;	
	drt = sd->device;

	printk("%s: (sycamore) entered\n", __func__);

	if (dev_index > drt->number_of_devices){
		return -1;
	}

	offset = (dev_index) * 8 * 8;

	printk("%s: (sycamore) index: %d\n", __func__, offset);

	//don't count the drt device
	*type = (u32) hstring_to_num(&drt->drt[offset], 8);
	*flags = (u32) hstring_to_num(&drt->drt[offset + 8], 8);
	*device_address = (u32) hstring_to_num(&drt->drt[offset + 16], 8);
	*size = (u32) hstring_to_num(&drt->drt[offset + 24], 8);
	return 0;
}




