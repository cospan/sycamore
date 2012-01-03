//sycamore_platform.h


/**
 * Sycamore Platform
 *
 * Description:
 *	first level of abstraction over the various ways to interface
 *	the platform bus and hardware interface is handled here
 *	functions include:
 *		-creates the sycamore context and registers the platform bus
 *		-destroys the sycamore context and deregisters the platform bus
 *		-write to the lower level hardware
 *		-read from lower level hardware
 *
 **/


#ifndef __SYCAMORE_PLATFORM_H__
#define __SYCAMORE_PLATFORM_H__

#include <linux/tty.h>
#include <linux/workqueue.h>
#include "sycamore.h"

#define SYCAMORE_BUS_NAME "sycamore"

#define SYCAMORE_WQ_NAME "sycamore_wq"



void sycamore_set_write_func(sycamore_t *sycamore, hardware_write_func_t write_func, void * data);
void sycamore_periodic(struct work_struct *work);
void sycamore_read_data(sycamore_t *sycamore, char * buffer, int lenth);
int sycamore_attach(sycamore_t *sycamore);
void sycamore_disconnect(sycamore_t *sycamore);
void sycamore_write_callback(sycamore_t *sycamore);



#endif //__SYCAMORE_PLATFORM_H__
