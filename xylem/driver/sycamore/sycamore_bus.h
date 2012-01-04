//sycamore_bus.h


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

#define MAX_NUM_DEVICES 256

typedef struct _sycamore_device_t sycamore_device_t;
typedef struct _sycamore_bus_t sycamore_bus_t;

struct _sycamore_device_t {
	char *name;	

	u16 flags;
	u16 type;

	//read variables
	u8 *read_buffer;
	u8 read_address;
	u32	read_size;

	bool read_in_progress;

	//write variables

};

struct _sycamore_bus_t {

	bool sycamore_found;
	//device rom table
	int drt_state;
	int size_of_drt;
	char *drt;	

	struct work_struct control_work;

	sycamore_device_t devices[MAX_NUM_DEVICES];
};

//sycamore bus
void sycamore_bus_init (sycamore_bus_t * sb); 
void sycamore_bus_destroy(sycamore_bus_t *sb);

//sycamore device
void sd_init(sycamore_device_t *sd);
void sd_destroy(sycamore_device_t *sd);


//********** TO THE UPPER LEVEL (sycamore device) **********
void sd_read(sycamore_device_t *sd, int size);
void sd_interrupt(sycamore_device_t *sd);


//********** FROM THE UPPER LEVEL (sycamore device) **********
void sb_write(sycamore_device_t *sd);



//********** TO THE LOWER LEVEL (sycamore protocol) **********
//write to the FPGA
int sp_write(	
				sycamore_bus_t *sb, 
				u8 device_address, 
				u32 offset, 
				char * out_buffer, 
				u32 length);

//read from the FPGA
void sp_read(	
				sycamore_bus_t *sb,
				u8 device_address, 
				u32 offset, 
				char * in_buffer, 
				u32 length);
//ping the FPGA
void sp_ping(
				sycamore_bus_t *sb);





//********** FROM THE LOWER LEVEL **********
//a ping response from the FPGA
void sb_ping_response(
				sycamore_bus_t *sb);
//interrupts
void sb_interrupt(
				sycamore_bus_t *sb,
				u32 interrupts);

//write from the sycamore protocol layer to here
void sb_read(sycamore_bus_t *sb,
				u8 device_address,	//device to write to
				u32 offset,			//where in the offset we started
				u32 position,		//position in the read
				u32 length,			//length of this read
				u32 size_left);		//how much more we have to read


void sb_write_callback(sycamore_bus_t *sb);


#endif //__SYCAMORE_BUS_H__
