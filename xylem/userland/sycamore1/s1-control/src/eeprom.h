//eeprom.h

/**
 * eeprom controller
 **/


#ifndef __EEPROM_H__
#define __EEPROM_H__
#include <ftdi.h>
#include <stdbool.h>

typedef struct _eeprom_t eeprom_t;


eeprom_t * eeprom_init();

void eeprom_destroy(eeprom_t *eeprom);

void eeprom_set_vendor_id(
					eeprom_t *eeprom, 
					unsigned int vendor_id);

void eeprom_set_product_id(
					eeprom_t *eeprom,
					unsigned int product_id);

void eeprom_set_vendor_string(
					eeprom_t *eeprom,
					const char * manufacturer);

void eeprom_set_product_string(
					eeprom_t *eeprom,
					const char * product);

int eeprom_calculate_size(
					eeprom_t *eeprom);

void eeprom_set_interface_0_string (
					eeprom_t *eeprom,
					const char * interface_string);
void eeprom_set_interface_1_string (
					eeprom_t *eeprom,
					const char * interface_string);


int eeprom_generate_byte_string (eeprom_t *eeprom, uint8_t *data, int max_length);

#endif //__EEPROM_H__
