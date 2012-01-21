//main.c
#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include <stdbool.h>
#include <malloc.h>
#include "comm.h"
#include "eeprom.h"

/**
 * s1-control
 * Description: controls the communication and eeprom of sycamore1
 *
 **/
typedef struct _sycamore_command_t sycamore_command_t;
typedef struct _state_t	state_t;


static void usage (void);
static int cmd_test (state_t *state, const char *cmd, int argc, char **argv);
static int cmd_mode (state_t *state, const char *cmd, int argc, char **argv);


struct _state_t{
	comm_t *comm;
	eeprom_t *eeprom;
};

struct _sycamore_command_t {
	const char 		*name;
    int (*handle) (state_t *state, const char *cmd, int argc, char **argv);
	void *		 	data_pointer;
	bool			data_required;
	const char		*data_name;
	const char 		*description;
};


static sycamore_command_t SYCAMORE_COMMANDS[] ={
	{"test",	cmd_test, 	NULL, false, NULL, "Test Function"},
	{"mode", 	cmd_mode,	NULL, false, NULL, "Sets mode to 25MBps (normal), or 8MBps (config mode)"},
	{NULL,			NULL, 		NULL, false, NULL, NULL},
};

//print out the usage statement
static void usage (void){
	int i = 0;
	printf (
	"\n"
	"usage: s1-control [options] <cmd>\n"
	"\n"
	"Description: sets communication mode and programs SPI flash\n"
	"\n"
	"Options:\n"
	"\t-h, --help\t\tShows this help text and exits\n"
	"\n"
	"Commands: \n"
	);
	for (i = 0; SYCAMORE_COMMANDS[i].name; i++){
		printf ("\t%s: \n\t\tDescription: %s", SYCAMORE_COMMANDS[i].name, SYCAMORE_COMMANDS[i].description);	
		if (SYCAMORE_COMMANDS[i].data_required) {
			printf ("\n\t\t data name: %s", SYCAMORE_COMMANDS[i].data_name);
		}
		else {
			printf ("\n");
		}
	}
	printf (
	"\n" "Example: s1-control\n"
	"\n");

}




int main(int argc, char** argv){
	char * optstring = "hc:d:";
	int c;
	state_t state;
	state.comm = NULL;
	int i = 0;
	int result = 0;

	struct option long_opts[] = {
		{"help", no_argument, 0, 'h'},
		{0, 0, 0, 0}
	};

    while ((c = getopt_long (argc, argv, optstring, long_opts, 0)) >= 0) {
     switch (c) {
            case 'h':
            default:
                usage();
				comm_destroy(state.comm);
				return 0;
        }
    }

	//get the remaining command line argument
    if(optind > argc - 1) {
		printf ("Error: no command found\n\n");
        usage();
		comm_destroy(state.comm);
		return 2;
    }
    const char *cmd_name = argv[optind];

    char **cmd_args = &argv[optind+1];
    int cmd_nargs = argc - optind - 1;

	//search for the desried command and execute it	
	bool found_cmd = false;
	for (i = 0; SYCAMORE_COMMANDS[i].name && !found_cmd; i++){
		if (!strcmp(cmd_name, SYCAMORE_COMMANDS[i].name)){
			result = SYCAMORE_COMMANDS[i].handle(&state, cmd_name, cmd_nargs, cmd_args);
			found_cmd = true;
		}
	}

	if (!found_cmd){
		printf ("Unrecognized command %s\n", cmd_name);
		return 1;
	}
	

	return result;
}

static int cmd_test (state_t *state, const char *cmd, int argc, char **argv){
	int i = 0;
	int result = 0;
	int size = 0;
	char buffer[1024];
	printf ("unit-test\n");
	state->comm = comm_init();
	state->eeprom = eeprom_init();


	
	printf ("liting all devices...\n");
	comm_list_all_devices(state->comm, 0x0403, 0x6010); 


	printf ("opening sycamore1...");
	result = comm_open_sycamore1(state->comm);
	if (result != 0){
		printf ("failed\n");
	}
	else {
		printf ("success!\n");
	}

	//read the chipid
	printf ("reading chipid:...");
	result = comm_get_chipid(state->comm);
	if (result < 0){
		printf ("failed!, can only read chipids from R type devices\n");
	}
	else {
		printf ("success!\n");
		printf ("chipid: %d\n", result);
	}

	//test out the eeprom
	printf ("retreiving size of eeprom\n");
	size = eeprom_calculate_size(state->eeprom);
	printf ("size: %d\n", size);

	printf ("generating the eeprom raw file\n");
	size = eeprom_generate_byte_string(	state->eeprom, 
										&buffer[0], 
										1024);
	printf ("writing to file");

	FILE *f = fopen("usb_descriptor.hex", "w");
	if (f == NULL){
		printf ("failed to open the file\n");
	}
	else {
		size = fwrite(&buffer, 1, size, f);
		printf ("wrote %d bytes\n", size);
		fclose(f);
	}
	

	//initializing the EEPROM
/*
	printf ("initializing the EEPROM...\n");
	comm_init_eeprom(state->comm);

	printf ("printing the contents of the EEPROM...\n");
	comm_print_eeprom_values(state->comm);

	printf ("generaing the eeprom byte array...");
	result = comm_get_eeprom(state->comm, &eeprom[0]);
	if (result < 0){
		printf ("failed\n");
	}
	else {
		printf ("success!\n");
		printf ("eeprom size: %d\n", result);
//		printf ("eeprom contents:\n");
//		for (i = 0; i < result; i++){
//			printf ("%8X ", eeprom[i]);
//		}
	}
	printf ("\n");

*/
	printf ("closing sycamore1...");
	result = comm_close_sycamore1(state->comm);
	if (result != 0){
		printf ("failed\n");
	}
	else {
		printf ("success!\n");
	}
	eeprom_destroy(state->eeprom);
	comm_destroy(state->comm);


}
 
static int cmd_mode (state_t *state, const char *cmd, int argc, char **argv){
	printf ("set mode\n");
}
