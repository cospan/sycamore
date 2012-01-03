//sycamore_driver.h


/**
 * sycamore_driver: the level just above the hardware specific driver
 * 	regardless of what hardware device is attached this is the interface to
 *	the rest of sycamore
 *
 *	-handles all the low level sycamore functions for the sycamore_bus
 *	including:
 *		-detection with ping
 *		-obtaining the DRT
 *		-communicating with the low level hardware driver
 **/


 #ifndef __SYCAMORE_DRIVER_H__
 #define __SYCAMORE_DRIVER_H__

#include "sycamore_protocol.h"

typedef struct _sycamore_driver_t sycamore_driver_t;

//hardware callback whenever we want to perform a write to the controlling device
typedef int (*hardware_write_func_t) (	const void * data, 
										const unsigned char * buf, 
										int count);


struct _sycamore_driver_t {

	//protocol specific structure
	sycamore_protocol_t *sp;

	//hardware specific write function
	hardware_write_func_t write_func;
	void * write_data;


	//device rom table
	char *drt;	
};


void sycamore_driver_set_write_function(
						sycamore_driver_t *sd, 
						hardware_write_func_t write_func, 
						void *data);

void sycamore_driver_read_data(
						sycamore_driver_t *sd, 
						char *buffer, 
						int length);

sycamore_driver_t * sycamore_driver_init (void); 

void sycamore_driver_destroy(sycamore_driver_t *sd);

void sycamore_driver_write_callback(sycamore_driver_t *sd);


 #endif //__SYCAMORE_DRIVER_H__
