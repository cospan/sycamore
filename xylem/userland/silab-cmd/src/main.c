#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include <stdbool.h>
#include <malloc.h>
#include "serial.h"


#define IOCTL_PING 0x40
#define IOCTL_DRT 0x41

static void usage (void);

typedef struct _sycamore_command_t sycamore_command_t;
typedef struct _state_t	state_t;

struct _state_t{
	int serial_fd;
};

struct _sycamore_command_t {
	const char 		*name;
	unsigned int 	ioctl_number;
    int (*handle) (state_t *state, const char *cmd, int argc, char **argv);
	void *		 	data_pointer;
	bool			data_required;
	const char		*data_name;
	const char 		*description;
};
//command_functions
static int cmd_ping (state_t *state, const char *cmd, int argc, char **argv) {
	printf ("ping sycamore device\n");
	ioctl(state->serial_fd, IOCTL_PING, NULL);
}
static int cmd_drt (state_t *state, const char *cmd, int argc, char **argv){
	printf ("get the DRT\n");
}
 

static sycamore_command_t SYCAMORE_COMMANDS[] ={
	{"ping", 	IOCTL_PING, cmd_ping, 	NULL, false, NULL, "Ping Sycamore device"},
	{"drt", 	IOCTL_DRT, 	cmd_drt, 	NULL, false, NULL, "Get the Device ROM Table (DRT)"},
	{NULL, 		0, 			NULL, 		NULL, false, NULL, NULL},
};



//print out the usage statement
static void usage (void){
	int i = 0;
	printf (
	"usage: silab-cmd [options] <cmd>\n"
	"\n"
	"Description: send a command to the sycamore and get a response\n"
	"\n"
	"Options:\n"
	"\t-h, --help\t\tShows this help text and exits\n"
	"\t-d, --devicename <s>\tDevice to connect to (default: /dev/ttyUSB0)\n"
	"\t-b, --baud <b>\t\tBaud rate: one of 9600(default), 19200, 57600, 115200\n"
	"\t\t\t\t200000, 250000, 400000, 500000, 1000000\n"
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
	printf ("\n" "Example: ./silab-cmd --baud 9600 -devicename /dev/ttyUSB0\n"
			"\n");

}

int main(int argc, char** argv){

	char * optstring = "hc:d:";
	int c;
	state_t state;
	state.serial_fd = 0;
	int i = 0;
	int result = 0;

	struct option long_opts[] = {
		{"help", no_argument, 0, 'h'},
		{"baud", required_argument, 0, 'b'},
		{"devicename", optional_argument, 0, 'b'},
		{0, 0, 0, 0}
	};

	int baud = 9600;
	char *devicename = strdup("/dev/ttyUSB0");
    while ((c = getopt_long (argc, argv, optstring, long_opts, 0)) >= 0) {
        switch (c) {
            case 'd':
                free(devicename);
                devicename = strdup (optarg);
                break;
            case 'b':
                baud = atoi(optarg);
                if(baud != 9600 && baud != 19200 && baud != 57600 &&
                   baud != 115200 && baud != 200000 && baud != 250000 &&
                   baud != 400000 && baud != 500000 && baud != 1000000 ) {
                    fprintf(stderr, "Invalid baud rate\n");
                    return 1;
                }
                break;
            case 'h':
            default:
                usage();
        }
    }


	//get the remaining command line argument
    if(optind > argc - 1) {
		printf ("Error: no command found\n\n");
        usage();
        free(devicename);
		return 2;
    }
    const char *cmd_name = argv[optind];

    char **cmd_args = &argv[optind+1];
    int cmd_nargs = argc - optind - 1;

	state.serial_fd = serial_open(devicename, baud, 1);
	if (state.serial_fd < 0) {
		printf ("%s: Failed to open %s\n", __FUNCTION__, devicename);
		free(devicename);
		return -1;
	}

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
		free(devicename);
		return 1;
	}
	serial_close(state.serial_fd);
	free(devicename);

    return result;
}
