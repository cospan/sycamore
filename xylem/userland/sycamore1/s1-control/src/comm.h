//comm.h

/**
 * comm.h
 * Description: wraps around all communcation with
 *	sycamore
 **/


#ifndef __COMM_H__
#define __COMM_H__
#include <ftdi.h>

typedef struct _comm_t comm_t;

//initialize
comm_t *comm_init (void);
//destroy
void comm_destroy(comm_t *comm);

int comm_open_sycamore1(comm_t *comm);
int comm_close_sycamore1(comm_t *comm);


//helper function
/*
void comm_list_all_devices(	comm_t *comm, 
							unsigned int vendor, 
							unsigned int product);

*/

int comm_get_chipid(comm_t *comm);

void comm_init_eeprom(comm_t *comm);
void comm_print_eeprom_values(comm_t* comm);
int comm_get_eeprom(comm_t *comm, unsigned char *eeprom);

void comm_set_eeprom_dual(comm_t *comm);
void comm_set_eeprom_normal(comm_t *comm);
void comm_set_eeprom_program(comm_t *comm);
int comm_reset_usb(comm_t *comm);

#endif //__COMM_H__
