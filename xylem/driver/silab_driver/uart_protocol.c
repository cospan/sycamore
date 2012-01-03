//protocol_template.c
#include <linux/kernel.h>
#include <linux/slab.h>
#include "../sycamore/sycamore_protocol.h"
/**
 * protocol_template
 * Description: Modify this file to adapt a new hardware interconnect
 *
 */

typedef struct _my_protocol_t my_protocol_t;

struct _my_protocol_t {
	//update this variable to reflect the status of the command
	int command_status;
};



/**
 * sycamore_protocol_init
 * Description: initialize the hardware specific protocol
 *	modify the between CUSTOM_START, CUSTOM_END
 *
 * protocol_data:
 *	physical_layer specific data that might be required for communicating
 *	with the physical layer
 *
 * Return:
 *	returns an initialized sycamore_protocol_t structure
 *	NULL on failue
 **/
sycamore_protocol_t * sp_init(void * protocol_data){
	//don't change!	
	sycamore_protocol_t *sp = NULL;
	my_protocol_t *mp = NULL;

	printk("%s: initializing the protocol specific driver\n", __func__);
	//allocate space for the sycamore_protocol_t structure
	sp = (sycamore_protocol_t *) kzalloc(sizeof(sycamore_protocol_t), GFP_KERNEL);
	if (sp == NULL){
		//failed to allocate memory for sycamore_protocol
		goto fail2;
	}
	//allocate space for your specific protocol here
	mp = (my_protocol_t *) kzalloc(sizeof(my_protocol_t), GFP_KERNEL);
	if (mp == NULL){
		//failed to allocate memory for my_protocol_t
		goto fail1;
	}
	sp->command_status = INITIALIZED;
	sp->drt = NULL;
	sp->protocol_data = protocol_data;

	//CUSTOM_START

	//initialize your variables here

	//CUSTOM_END
	return sp;

fail1:
	kfree(sp);
fail2:
	return NULL;
}


/**
 * sycamore_destroy
 * Description: cleans and removes anything that was done within init
 *
 * Return:
 *	nothing
 **/
void sp_destroy(sycamore_protocol_t *sp){
	//CUSTOM_START
	//stop anything you need to stop here, deallocate anything here
	//CUSTOM_END
	//free the custom protocol stuff
	if (sp->drt != NULL){
		kfree(sp->drt);
	}
	kfree(sp->protocol);
	kfree(sp);
}


/**
 * sp_parse_read
 * Description: does a protocol specific parsing of data
 *
 * Return:
 *	the command status (see sycamore_protocol.h for the values)
 **/
int sp_parse_read(	sycamore_protocol_t *sp,
					char *buffer_in,
					int size){

	//CUSTOM_START
	
	//need to determine if this is a
		//TIMED_OUT: a timeout has occured within sycamore
		//PROTOCOL_ERROR: there is an error in the protocol
		//NOT_FINISHED: still waiting for more data from the driver
		//READ_RESPONSE: got a read from the FPGA
		//WRITE_ACK: got an ack from a previous write
		//PING_RESPONSE: got a ping response
		//DRT_RESPONSE: got a DRT related read
		//CONTROL_RESPONSE: got a response from a control 
	
	return PROTOCOL_ERROR;
	//CUSTOM_END
}


/**
 * sp_format_new_write
 * Description: this is a new write
 *
 * Return:
 *	number of bytes written
 *	negative value for error
 **/
int sp_format_new_write(	sycamore_protocol_t *sp,
							char * buffer_out, 
							char * buffer_in, 
							int size){
	return 0;
}

/**
 * sp_format_cont_write
 * Description: this is a continuation of a write
 *
 * Return:
 *	number of bytes written
 *	negative value for an error
 **/
int sp_format_cont_write(	sycamore_protocol_t *sp,
							char * buffer_out, 
							char * buffer_in, 
							int size){
	return 0;
}

/**
 * sp_is_control_response
 * Description: tells return true if this is a control type response
 *
 * Return:
 *	true: control response
 *	false: not a control response
 **/
bool sp_is_control_response ( sycamore_protocol_t *sp){
	return false;
}

/**
 * sp_start_read_drt
 * Description: start reading drt data
 *
 * Return:
 *	nothing
 **/
void sp_start_read_drt (sycamore_protocol_t *sp){
}

/**
 * sp_is_ping_response
 * Description: is this a ping response?
 *
 * Return:
 *	true: if this is a ping response
 *	false: if this is not a ping response
 **/
bool sp_is_ping_response(sycamore_protocol_t *sp){
	return false;
}
/**
 * sp_get_command_status
 * Description: get the numeric value of the command (see sycamore_protocol.h
 *	for a description
 *
 * Return:
 *	numeric command status value
 **/
int sp_get_command_status(sycamore_protocol_t *sp){
	return 0;
}




