//sycamore_control.h

#include "sycamore.h"

/**
 * Sycamore Control
 *
 * Description:
 *	this controls the main sycamore bus performing functions such as
 *	-getting the DRT
 *	-sending ping
 *	-processing input
 *
 **/

#ifndef __SYCAMORE_CONTROL_H__
#define __SYCAMORE_CONTROL_H__

int sycamore_write(sycamore_t * sycamore, 
					u32 command,
					u32 device_address,
					u32 offset,
					char *buffer, u32 length);

int sycamore_control_process_read_data(sycamore_t * sycamore, char * buffer, int length); 
void sycamore_control_periodic (sycamore_t * sycamore);


#endif //__SYCAMORE_CONTROL_H__
