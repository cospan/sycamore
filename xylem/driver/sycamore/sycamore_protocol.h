//sycamore_protocol.h

/**
 * sycamore_protocol.h: hardware driver specific functions that must be filled
 *	out by the driver developer, it basically is the contract for each protocol
 *
 * 	this protocol must
 *		-set up a write
 *		-set up a read
 *		-perform a ping
 *		-handle the DRT state machine, returning the drt string
 *			upon success
 */


#ifndef __SYCAMORE_PROTOCOL_H__
#define __SYCAMORE_PROTOCOL_H__

#include <linux/types.h>

//hardware callback whenever we want to perform a write to the controlling device
typedef int (*hardware_write_func_t) (	const void * data, 
										const unsigned char * buf, 
										int count);

typedef struct _sycamore_protocol_t sycamore_protocol_t;

sycamore_protocol_t * sp_init (void);
void sp_destroy(sycamore_protocol_t *sp);
void sp_write_callback(sycamore_protocol_t *sp, u32 bytes_left);
void sp_set_write_function(
						sycamore_protocol_t *sp,
						hardware_write_func_t write_func,
						void *data);
void sp_hardware_read(
						sycamore_protocol_t *sp, 
						char *buffer, 
						int length);

#endif //__SYCAMORE_PROTOCOL_H__
