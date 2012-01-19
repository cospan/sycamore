//comm.c

#include "comm.h"

#include <stdio.h>
#include <malloc.h>
#include <sys/types.h>


struct _comm_t {
	struct ftdi_context ftdic;
	struct ftdi_device_list *dev;
};


comm_t *comm_init (void){
	comm_t *comm = NULL;
	comm = calloc (1, sizeof(comm_t));
	if (comm == NULL){
		printf ("%s: failed to allocate space for comm\n", __func__);
		return NULL;
	}
	if (ftdi_init (&comm->ftdic) < 0){
		//failed to get an FTDI context
		printf ("%s: failed to get an FTDI context\n", __func__);
		free(comm);
		return NULL;
	}

	return comm;
}

void comm_destroy(comm_t *comm){

    ftdi_deinit(&comm->ftdic);
	free (comm);
}


int comm_open_sycamore1(comm_t *comm){
	int result = 0;
	if ((result = ftdi_usb_open(
						&comm->ftdic, 
						0x0403, 
						0x6010)) < 0){
		printf ("%s: Failed to open FTDI device: %d (%s)\n",
						__func__,
						result,
						ftdi_get_error_string(&comm->ftdic));
		return -1;
	}
	return result;
}

int comm_close_sycamore1(comm_t *comm){
	int result = 0;
	if (result = ftdi_usb_close(&comm->ftdic) < 0){
		printf ("%s: Failed to close FTDI device: %d (%s)\n",
						__func__,
						result,
						ftdi_get_error_string(&comm->ftdic));
	}
	
}

void comm_list_all_devices(	comm_t *comm, 
							unsigned int vendor, 
							unsigned int product){
	int result = 0;
	int i = 0;
	struct ftdi_device_list *devlist;
	struct ftdi_device_list *curdev;
    char manufacturer[128];
	char description[128];


	//get a listing of all the FTDI devices that match the
	//	vendor:product ID
	result = ftdi_usb_find_all(	&comm->ftdic, 
								&devlist, 
								vendor, 
								product); 

	if (result < 0){
		printf ("%s: failed to find any devices with ID: %04X:%04X\n", 
							__func__, 
							vendor, 
							product);
		return;
	}
	printf ("%s: Number of devices found: %d\n", __func__, result);

	i = 0;
    for (curdev = devlist; curdev != NULL; i++){
		printf ("Checking device: %d\n", i);
		if ((result = ftdi_usb_get_strings(
										&comm->ftdic,
										curdev->dev,
										manufacturer,
										128,
										description,
										128,
										NULL,
										0)) < 0){
			printf ("%s: ftdi_usb_get_strings failed: %d (%s)\n",
										__func__,
										result,
										ftdi_get_error_string(
											&comm->ftdic));
			return;
		}

		printf ("Manufacturer: %s, Descriptor: %s\n\n",
										manufacturer,
										description);
		curdev = curdev->next;
	}

    ftdi_list_free(&devlist);
}



int comm_get_chipid(comm_t *comm){
	int result = -1;
	if (comm->ftdic.type = TYPE_R){
		unsigned int chipid;
		result = ftdi_read_chipid(&comm->ftdic, &chipid);	
		return chipid;
	}
	return result;
}


void comm_print_eeprom_values(comm_t *comm){
/*
	printf ("eeprom values: \n");
	printf ("vendor id:\t\t%04X\n", comm->eeprom.vendor_id);
	printf ("product id:\t\t%04X\n", comm->eeprom.product_id);
	printf ("self powered:\t\t%d\n", comm->eeprom.self_powered);
	printf ("remote wakeup:\t\t%d\n", comm->eeprom.remote_wakeup);
	printf ("chip type:\t\t%d\n", comm->eeprom.chip_type);
	printf ("in is isochronous:\t%d\n", 
								comm->eeprom.in_is_isochronous);
	printf ("out is iscohronous:\t%d\n", 
								comm->eeprom.out_is_isochronous);
	printf ("suspend pull downs:\t%d\n", 
								comm->eeprom.suspend_pull_downs);
	printf ("use serial:\t\t%d\n", comm->eeprom.use_serial);
	printf ("change usb version:\t%d\n", 
								comm->eeprom.change_usb_version);
	printf ("usb version:\t\t%d\n", comm->eeprom.usb_version);
	printf ("max  power:\t\t%d\n", comm->eeprom.max_power);
	printf ("manufacturer:\t\t%s\n", comm->eeprom.manufacturer);
	printf ("product:\t\t%s\n", comm->eeprom.product);
	printf ("serial num:\t\t%s\n", comm->eeprom.serial);
	printf ("cbus function:\t\t%d\n"
			"\t\t\t%d\n"
			"\t\t\t%d\n"
			"\t\t\t%d\n"
			"\t\t\t%d\n", 
									comm->eeprom.cbus_function[0],
									comm->eeprom.cbus_function[1],
									comm->eeprom.cbus_function[2],
									comm->eeprom.cbus_function[3],
									comm->eeprom.cbus_function[4]);
	printf ("high current:\t\t%d\n", comm->eeprom.high_current);
	printf ("invert:\t\t\t%d\n", comm->eeprom.invert);
	printf ("size:\t\t\t%d\n", comm->eeprom.size);
*/
}

int comm_reset_usb(comm_t *comm){
	int result = 0;
	result = ftdi_usb_reset(&comm->ftdic);
	return result;
}


