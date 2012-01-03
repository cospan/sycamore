//sycamore_driver.c
#include "sycamore_driver.h"
#include <linux/kernel.h>
#include <linux/slab.h>

/**
 * sycamore_driver_set_write_function
 * Description: sets the driver specific write function, this is what
 *	all the functions will use to write to the FPGA
 *
 * Return:
 *	nothing
 **/
void sycamore_driver_set_write_function(
						sycamore_driver_t *sd, 
						hardware_write_func_t write_func, 
						void *data){
	printk("%s: setting the write function to %p\n", __func__, write_func);
	sd->write_func = write_func;
	sd->write_data = data;
}

/**
 * sycamore_driver_read_data
 * Description: reads the data from the low level driver
 *	some drivers send data in a 'peice meal' fashion so
 *	this function will accept all or part of the data received
 *	and put it together for the higher level functions
 *
 * Return:
 *	nothing
 */
void sycamore_driver_read_data(
						sycamore_driver_t *sd, 
						char *buffer, 
						int length){
}


/**
 * sycamore_driver_init
 * Description: Initializes the sycamore_driver
 *	-creates an instance
 *	-initializes the variables
 *
 * Return:
 *	sycamore_driver_t instantiation initialized
 *	NULL on failure
 */

sycamore_driver_t * sycamore_driver_init(void){
	sycamore_driver_t * sd = NULL;
	sd = (sycamore_driver_t *) kzalloc(sizeof(sycamore_driver_t), GFP_KERNEL);
	if (sd == NULL){
		printk ("%s: Failed to allocate sycamore_driver_t\n", __func__);
		return NULL;
	}

	//initialize the variables
	sd->write_func = NULL;
	sd->write_data = NULL;

	//initialize all things sycmore_driver_t
	return sd;
}

/**
 * sycamore_driver_destroy
 * Description: cleans up and removes any resources the driver used
 *
 * Return:
 *	nothing
 */
void sycamore_driver_destroy(sycamore_driver_t *sd){
	//clean up any resources
	sd->write_func = NULL;
	sd->write_data = NULL;
	
	//free sycamore_driver_t
	kfree(sd);
}

/**
 * sycamore_driver_write_callback
 * Description: called when a write has been completed
 *	if there is a long write, then this is used to send the rest of 
 *	the rest of the data
 *
 * Return:
 *	nothing
 **/
void sycamore_driver_write_callback(sycamore_driver_t *sd){
}


