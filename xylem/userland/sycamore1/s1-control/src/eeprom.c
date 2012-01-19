//eeprom.c
#include "eeprom.h"
#include <string.h>
#include <sys/types.h>
#include <malloc.h>


//EEPROM for a FT2232H
typedef struct _eeprom_t eeprom_t;


#define SYCAMORE1_VENDOR_ID 	0x0409
#define SYCAMORE1_PRODUCT_ID 	0x6010
#define SYCAMORE1_CHIP_TYPE		0xC594
#define SYCAMORE1_VENDOR		"Cospan Design"
#define SYCAMORE1_PRODUCT		"Sycamore 1"
#define SYCAMORE1_SERIAL		"001"
#define SYCAMORE1_NORMAL		"Normal Mode"
#define SYCAMORE1_PROGRAM		"Programming Mode"




struct _eeprom_t {

	//device descriptor
	uint8_t bdevice_length;
	uint8_t bdevice_type;
	uint16_t wBCDusb_version;
	uint8_t bdevice_class;
	uint8_t bdevice_subclass;
	uint8_t bdevice_protocol;
	uint8_t bmax_packet_size;
	uint16_t wvendor_id;
	uint16_t wproduct_id;
	uint16_t wBCDversion;
	uint8_t ivendor;
	uint8_t iproduct;
	uint8_t iserial;
	uint8_t bnum_configuration;

	//configuration 0 (program mode)
	uint8_t bconf0_length;
	uint8_t bconf0_type;
	uint16_t wconf0_total_length;
	uint8_t bconf0_num_interfaces;
	uint8_t bconf0_value;
	uint8_t iconf0_name;
	uint8_t bmconf0_attr;
	uint8_t bconf0_max_power;
	
	//interface 0 descriptor (8MB/s FIFO)
	uint8_t bif00_length;	
	uint8_t bif00_type;
	uint8_t bif00_number;
	uint8_t bif00_alt;
	uint8_t bif00_num_endpoints;
	uint8_t bif00_class;
	uint8_t bif00_sub_class;
	uint8_t bif00_protocol;
	uint8_t bif00_iinterface;

	//endpoint 0 descriptor (in)
	uint8_t bep000_length;
	uint8_t bep000_type;
	uint8_t bep000_addr;
	uint8_t bmep000_attr;
	uint16_t wep000_packet_size;
	uint8_t bep000_interval;

	//endpoint 1 descriptor (out)
	uint8_t bep001_length;
	uint8_t bep001_type;
	uint8_t bep001_addr;
	uint8_t bmep001_attr;
	uint16_t wep001_packet_size;
	uint8_t bep001_interval;

	//interface 1 descriptor (SPI/bitbang)
	uint8_t bif01_length;	
	uint8_t bif01_type;
	uint8_t bif01_number;
	uint8_t bif01_alt;
	uint8_t bif01_num_endpoints;
	uint8_t bif01_class;
	uint8_t bif01_sub_class;
	uint8_t bif01_protocol;
	uint8_t bif01_iinterface;

	//endpoint 0 descriptor (in)
	uint8_t bep010_length;
	uint8_t bep010_type;
	uint8_t bep010_addr;
	uint8_t bmep010_attr;
	uint16_t wep010_packet_size;
	uint8_t bep010_interval;

	//endpoint 1 descriptor (out)
	uint8_t bep011_length;
	uint8_t bep011_type;
	uint8_t bep011_addr;
	uint8_t bmep011_attr;
	uint16_t wep011_packet_size;
	uint8_t bep011_interval;

	//configuration 1 (normal mode)
	uint8_t bconf1_length;
	uint8_t bconf1_type;
	uint16_t wconf1_total_length;
	uint8_t bconf1_num_interfaces;
	uint8_t bconf1_value;
	uint8_t iconf1_name;
	uint8_t bmconf1_attr;
	uint8_t bconf1_max_power;
	
	//interface 0 descriptor (25MB/s FIFO)
	uint8_t bif10_length;	
	uint8_t bif10_type;
	uint8_t bif10_number;
	uint8_t bif10_alt;
	uint8_t bif10_num_endpoints;
	uint8_t bif10_class;
	uint8_t bif10_sub_class;
	uint8_t bif10_protocol;
	uint8_t bif10_iinterface;


	//endpoint 0 descriptor (in)
	uint8_t bep100_length;
	uint8_t bep100_type;
	uint8_t bep100_addr;
	uint8_t bmep100_attr;
	uint16_t wep100_packet_size;
	uint8_t bep100_interval;


	//endpoint 1 descriptor (out)
	uint8_t bep101_length;
	uint8_t bep101_type;
	uint8_t bep101_addr;
	uint8_t bmep101_attr;
	uint16_t wep101_packet_size;
	uint8_t bep101_interval;


	//string
	uint8_t bstr_length;
	uint8_t bstr_type;
	uint16_t wstr_langid0;

	uint8_t bvendor_length;
	uint8_t bvendor_type;
	uint8_t *vendor_string;

	uint8_t bprod_length;
	uint8_t bprod_type;
	uint8_t *prod_string;

	uint8_t bif0_length;
	uint8_t bif0_type;
	uint8_t *if0_string;

	uint8_t bif1_length;
	uint8_t bif1_type;
	uint8_t *if1_string;
	
};

eeprom_t * eeprom_init(){
	eeprom_t *eeprom = NULL;
	eeprom = (eeprom_t *) calloc(1, sizeof(eeprom_t));


	//Device
	eeprom->bdevice_length			= 18;
	eeprom->bdevice_type			= 1;
	eeprom->wBCDusb_version			= 200;
	eeprom->bdevice_class			= 0;
	eeprom->bdevice_subclass		= 0;
	eeprom->bdevice_protocol		= 0;
	eeprom->bmax_packet_size		= 64;
	//vendor id
	eeprom->wvendor_id				= SYCAMORE1_VENDOR_ID; 
	//product id
	eeprom->wproduct_id				= SYCAMORE1_PRODUCT_ID;
	eeprom->wBCDversion				= 700;
	eeprom->ivendor					= 1;
	eeprom->iproduct				= 2;
	eeprom->iserial					= 0;
	eeprom->bnum_configuration		= 2;
	

	//Configuration 0
	eeprom->bconf0_length			= 9;
	eeprom->bconf0_type				= 2;
	eeprom->wconf0_total_length		= 55; //configuration total size
	eeprom->bconf0_num_interfaces	= 2;
	eeprom->bconf0_value			= 1;
	eeprom->iconf0_name				= 3;
	eeprom->bmconf0_attr			= 0x80;
	eeprom->bconf0_max_power		= 250;	

	//Interface 0:0
	eeprom->bif00_length			= 9;
	eeprom->bif00_type				= 4;
	eeprom->bif00_number			= 0;
	eeprom->bif00_alt				= 0;
	eeprom->bif00_num_endpoints		= 2;
	eeprom->bif00_class				= 255;
	eeprom->bif00_sub_class			= 255;
	eeprom->bif00_protocol			= 255;
	eeprom->bif00_iinterface		= 0x04;

	//Endpoint 0:0:0
	eeprom->bep000_length			= 7;
	eeprom->bep000_type				= 5;
	eeprom->bep000_addr				= 0x81;
	eeprom->bmep000_attr			= 2;
	eeprom->wep000_packet_size		= 0x200;
	eeprom->bep000_interval			= 0;

	//Endpoint 0:0:1
	eeprom->bep001_length			= 7;
	eeprom->bep001_type				= 5;
	eeprom->bep001_addr				= 0x02;
	eeprom->bmep001_attr			= 2;
	eeprom->wep001_packet_size		= 0x200;
	eeprom->bep001_interval			= 0;

	//Interface 0:1
	eeprom->bif01_length			= 9;
	eeprom->bif01_type				= 4;
	eeprom->bif01_number			= 1;
	eeprom->bif01_alt				= 0;
	eeprom->bif01_num_endpoints		= 2;
	eeprom->bif01_class				= 255;
	eeprom->bif01_sub_class			= 255;
	eeprom->bif01_protocol			= 255;
	eeprom->bif01_iinterface		= 0x05;

	//Endpoint 0:1:0
	eeprom->bep010_length			= 7;
	eeprom->bep010_type				= 5;
	eeprom->bep010_addr				= 0x83;
	eeprom->bmep010_attr			= 2;
	eeprom->wep010_packet_size		= 0x200;
	eeprom->bep010_interval			= 0;

	//Endpoint 0:1:1
	eeprom->bep011_length			= 7;
	eeprom->bep011_type				= 5;
	eeprom->bep011_addr				= 0x04;
	eeprom->bmep011_attr			= 2;
	eeprom->wep011_packet_size		= 0x200;
	eeprom->bep011_interval			= 0;


	//Configuration 1
	eeprom->bconf1_length			= 9;
	eeprom->bconf1_type				= 2;
	eeprom->wconf1_total_length		= 32; //total size
	eeprom->bconf1_num_interfaces	= 1;
	eeprom->bconf1_value			= 2;
	eeprom->iconf1_name				= 4;
	eeprom->bmconf1_attr			= 0x80;
	eeprom->bconf1_max_power		= 250;	

	//Interface 1:0
	eeprom->bif10_length			= 9;
	eeprom->bif10_type				= 4;
	eeprom->bif10_number			= 0;
	eeprom->bif10_alt				= 0;
	eeprom->bif10_num_endpoints		= 2;
	eeprom->bif10_class				= 255;
	eeprom->bif10_sub_class			= 255;
	eeprom->bif10_protocol			= 255;
	eeprom->bif10_iinterface		= 0x04;

	//Endpoint 1:0:0
	eeprom->bep100_length			= 7;
	eeprom->bep100_type				= 5;
	eeprom->bep100_addr				= 0x81;
	eeprom->bmep100_attr			= 2;
	eeprom->wep100_packet_size		= 0x200;
	eeprom->bep100_interval			= 0;

	//Endpoint 1:0:1
	eeprom->bep101_length			= 7;
	eeprom->bep101_type				= 5;
	eeprom->bep101_addr				= 0x02;
	eeprom->bmep101_attr			= 2;
	eeprom->wep101_packet_size		= 0x200;
	eeprom->bep101_interval			= 0;



	//language
	eeprom->bstr_type				= 0x03;
	eeprom->wstr_langid0			= 0x0409;
	eeprom->bstr_length				= 3;

	//vendor string
	eeprom->bvendor_type			= 3;
	eeprom->vendor_string			= strdup(SYCAMORE1_VENDOR);
	eeprom->bvendor_length			= strlen(SYCAMORE1_VENDOR) + 2;
//	printf ("vendor length: %d\n", eeprom->bvendor_length);

	//product string
	eeprom->bprod_type				= 3;
	eeprom->prod_string				= strdup(SYCAMORE1_PRODUCT);
	eeprom->bprod_length			= strlen(SYCAMORE1_PRODUCT) + 2;
//	printf ("product length: %d\n", eeprom->bprod_length);

	//interface 0 string
	eeprom->bif0_type				= 3;
	eeprom->if0_string				= strdup(SYCAMORE1_PROGRAM);
	eeprom->bif0_length				= strlen(SYCAMORE1_PROGRAM) + 2;
//	printf ("if0 length: %d\n", eeprom->bif0_length);

	//interface 1 string
	eeprom->bif1_type				= 3;
	eeprom->if1_string				= strdup(SYCAMORE1_NORMAL);
	eeprom->bif1_length				= strlen(SYCAMORE1_NORMAL) + 2;
//	printf ("if1 length: %d\n", eeprom->bif1_length);

	return eeprom;

}

void eeprom_destroy(eeprom_t *eeprom){
	free(eeprom->vendor_string);
	free(eeprom->prod_string);
	free(eeprom->if0_string);
	free(eeprom->if1_string);
	free(eeprom);
}

void eeprom_set_vendor_id(
					eeprom_t *eeprom, 
					unsigned int vendor_id){
	eeprom->wvendor_id = vendor_id;
}

void eeprom_set_product_id(
					eeprom_t *eeprom,
					unsigned int product_id){
	eeprom->wproduct_id = product_id;
}

void eeprom_set_vendor_string(
					eeprom_t *eeprom,
					const char * vendor_string){

	if (eeprom->vendor_string != NULL){
		free(eeprom->vendor_string);	
	}

	eeprom->vendor_string = strdup(vendor_string);
	eeprom->bvendor_length = strlen(vendor_string);
}

void eeprom_set_product_string(
					eeprom_t *eeprom,
					const char * product_string){
	if (eeprom->prod_string != NULL){
		free(eeprom->prod_string);
	}
	eeprom->prod_string = strdup(product_string);
	eeprom->bprod_length = strlen(product_string);
}
void eeprom_set_interface_0_string (
					eeprom_t *eeprom,
					const char * interface_string){
	if (eeprom->if0_string != NULL){
		free(eeprom->if0_string);
	}
	eeprom->if0_string = strdup(interface_string);
	eeprom->bif0_length = strlen(interface_string);
}
void eeprom_set_interface_1_string (
					eeprom_t *eeprom,
					const char * interface_string){
	if (eeprom->if1_string != NULL){
		free(eeprom->if1_string);
	}
	eeprom->if1_string = strdup(interface_string);
	eeprom->bif1_length = strlen(interface_string);

}
int eeprom_calculate_size(
					eeprom_t *eeprom){

	uint32_t size = 0;
	uint32_t start = (uint32_t ) eeprom;
	uint32_t end = (uint32_t) &eeprom->bvendor_type;

	printf ("%s: entered\n", __func__);

//	printf ("base: %d\n", base);
//	printf ("offset: %d\n", offset);


//	size = end - start;
	//total descriptor size

	size = 18 + 55 + 32;

	printf ("size: %d\n", size);
	//add the size of the string
	size += eeprom->bstr_length;
	printf ("bstr_length: %d\n", eeprom->bstr_length);
	//add the size of vendor string
	size += eeprom->bvendor_length;
	printf ("bvendor_length: %d\n", eeprom->bvendor_length);
	//add the size of product string
	size += eeprom->bprod_length;
	printf ("bprod_length: %d\n", eeprom->bprod_length);
	//add the size of interface 0 string
	size += eeprom->bif0_length;
	printf ("bif0_length: %d\n", eeprom->bif0_length);
	//add the size of interface 1 string
	size += eeprom->bif1_length;

	printf ("size: %d\n", size);

	//calculating total length of configuration 0
//	start = (uint32_t) &eeprom->bconf0_length;  
//	end = (uint32_t) &eeprom->bconf1_length;
//	eeprom->wconf0_total_length = end - start;
	printf ("conf0 total length: %d\n", eeprom->wconf0_total_length);

//	start = (uint32_t) &eeprom->bconf1_length;
//	end = (uint32_t) &eeprom->bstr_length;
//	eeprom->wconf1_total_length = end - start;
	printf ("conf1 total length: %d\n", eeprom->wconf1_total_length);

	printf ("size: %d\n", size);
	//need an even number of bytes
	if ((size % 2) != 0){
		size++;
	}
	return size;
}


/**
 * eeprom_generate_byte_string
 * Description: generate a byte array (little endian) that can
 *	be sent to the eeprom of the FTDI 2232h
 * 
 * Return: size
 *	-1 if an error
 **/
int eeprom_generate_byte_string (eeprom_t *eeprom, uint8_t *data, int max_length){
	int total_length = eeprom_calculate_size(eeprom);
	int descriptor_length = eeprom->bdevice_length + 
							eeprom->wconf0_total_length +
							eeprom->wconf1_total_length;

	int i = 0;
	bool carry_byte = false;

	if (max_length < total_length){
		return -1;
	}
	
	if ((descriptor % 2) != 0){
		carry_byte = true;
	}
	for (i = 0; i < descriptor_length; i+= 2){
		//go through each words, and flip the bytes 
		
	}


	return 0;
}

