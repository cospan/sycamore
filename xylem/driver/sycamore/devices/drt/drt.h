//drt.h

/**
 * DRT (Device ROM Table)
 * Description:
 *	device 0 of all sycamore buses, this contains all the information needed 
 *	to generate sycamore devices this device will not be directly accessable
 *	to the user with a platform driver,	but will be accessable within the 
 *	sysfs directory. For normal operation the user may never be aware of the
 *	DRT
 **/

#ifndef __DRT_H__
#define __DRT_H__

#include "../../sycamore_bus.h"

#define DRT_TOC_SIZE 8
typedef struct _drt_t drt_t;

struct _drt_t {

	u16 version;
	u32 number_of_devices;
	u32 drt_size;
	char * drt;	

	//state machine control
	u32 drt_state;

	sycamore_device_t *sd;

};



void *drt_init (sycamore_device_t *sd);
void drt_destroy(void * data);

int drt_read 	(	void * device,
					u32 position,
					u32 start_address,
					u32 total_length,
					u32 size_left,
					u8 * data,
					u32 length);
void drt_interrupt (void * data, u32 interrupt);
void drt_start (sycamore_device_t *sd);
void drt_reset (sycamore_device_t *sd);
bool drt_finished (sycamore_device_t * sd);
bool drt_success (sycamore_device_t * sd);
bool drt_working (sycamore_device_t * sd);

#endif //__DRT_H__
