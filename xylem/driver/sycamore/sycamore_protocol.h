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

#define TIMED_OUT			-2
#define PROTOCOL_ERROR		-1
#define INITIALIZED			0
#define NOT_FINISHED		1
#define READ_RESPONSE		2
#define WRITE_ACK			3
#define PING_RESPONSE		4
#define DRT_RESPONSE		5
#define CONTROL_RESPONSE	6

typedef struct _sycamore_protocol_t sycamore_protocol_t;

struct _sycamore_protocol_t {
	//protocol specific data
	void * protocol;

	void * protocol_data;

	//generic items in all protocols
	int command_status;

	int size_of_drt;
	char *drt;
};

sycamore_protocol_t * sp_init (void * protocol_data);

void sp_destroy(sycamore_protocol_t *sp);

int sp_format_new_write(	sycamore_protocol_t *sp,
							char * buffer_out, 
							char * buffer_in, 
							int size);
int sp_format_cont_write(	sycamore_protocol_t *sp,
							char * buffer_out, 
							char * buffer_in, 
							int size);

int sp_parse_read(	sycamore_protocol_t *sp, 
					char * buffer_in,
					int size);

bool sp_is_control_response ( sycamore_protocol_t *sp);
void sp_start_read_drt (sycamore_protocol_t *sp);
bool sp_is_ping_response(sycamore_protocol_t *sp);
int sp_get_command_status(sycamore_protocol_t *sp);



#endif //__SYCAMORE_PROTOCOL_H__
