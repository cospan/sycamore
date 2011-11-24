#include <stdio.h>
#include <string.h>
#include <getopt.h>

static void usage(void);

static void usage(void){
	printf (	
		"usage: silab-daemon [options] <driver name> cmd\n"
		"\n"
		"Daemon that controls sycamore FPGA bus\n"
		);
}

int main(int argc, char** argv)
{
	usage();
    return 0;
}
