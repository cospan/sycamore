//sycamore_bus.h


/**
 * sycamore_bus: the level just above the protocol specific driver
 * 	regardless of what hardware device is attached this is the interface to
 *	the rest of sycamore
 *
 *	-handles all the low level sycamore functions for the sycamore_bus
 *	including:
 *		-detection with ping
 *		-obtaining the DRT
 *		-communicating with the low level hardware driver
 **/


#ifndef __SYCAMORE_BUS_H__
#define __SYCAMORE_BUS_H__

#include <linux/types.h>

typedef struct _sycamore_bus_t sycamore_bus_t;


struct _sycamore_bus_t {

	bool sycamore_found;
	//device rom table
	int size_of_drt;
	char *drt;	
};

sycamore_bus_t * sycamore_bus_init (void); 

void sycamore_bus_destroy(sycamore_bus_t *sd);

//write to the FPGA
int sp_write(	
				sycamore_protocol_t *sp, 
				u8 device_address, 
				u32 offset, 
				char * out_buffer, 
				u32 length);

//read from the FPGA
void sp_read(	
				sycamore_protocol_t *sp,
				u8 device_address, 
				u32 offset, 
				char * in_buffer, 
				u32 length);
//ping the FPGA
void sp_ping(
				sycamore_protocol_t *sp);

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

#endif //__SYCAMORE_BUS_H__
