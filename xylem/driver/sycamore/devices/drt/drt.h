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

#include "../devices.h"
#include "../../sycamore_bus.h"

#define DRT_TOC_SIZE 8

typedef struct _drt_t drt_t;


void *drt_init (				sycamore_device_t *sd,
								const char *name);
int drt_read 	(				void * device,
								u32 position,
								u32 start_address,
								u32 total_length,
								u32 size_left,
								u8 * data,
								u32 length);

//state machine functions
void drt_start (sycamore_device_t *sd);
void drt_reset (sycamore_device_t *sd);
bool drt_success (sycamore_device_t * sd);
bool drt_working (sycamore_device_t * sd);
bool drt_finished (sycamore_device_t * sd);

//drt devices functions
int drt_get_number_of_devices(	void * data);
int drt_get_device_data(		void * data, 
								int device_index, 
								u16 *type, 
								u16	*flags, 
								u32 *size,
								u32	*device_address); 

#endif //__DRT_H__
