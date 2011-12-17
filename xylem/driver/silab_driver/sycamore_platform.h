//sycamore_platform.h

#ifndef __SYCAMORE_PLATFORM_H__
#define __SYCAMORE_PLATFORM_H__

#include <linux/tty.h>
#include <linux/workqueue.h>
#define SYCAMORE_BUS_NAME "sycamore"

#define BUFFER_SIZE 512

typedef struct _sycamore_t sycamore_t;


#define READ_IDLE 		0
#define READ_SIZE 		1
#define READ_COMMAND 	2
#define READ_ADDRESS 	3
#define READ_DATA 		4

#define MAX_NUM_OF_DEVICES 256

#define SYCAMORE_WQ_NAME "sycamore work queue"

//1 second timeout
#define DEFAULT_PING_TIMEOUT 1000

//sycamore_platfrom data
struct _sycamore_t {
	//platform stuff
	struct platform_device *platform_device;
	struct attribute_group platform_attribute_group;
	u32	size_of_drt;
	char * drt;
	int	port_lock;
	struct platform_device *pdev;

	int read_pos;
//	char in_buffer[BUFFER_SIZE];

	//read state machine variables
	int read_state;
	u32 read_command;
	u32	read_data;
	u32 read_size;
	u32 read_data_count;
	u32 read_data_pos;
	u32 read_address;
	u32 read_device_address;

	struct platform_deve * devices[MAX_NUM_OF_DEVICES];


	//workqueue for ping
	struct workqueue_struct *wq;
	struct delayed_work delayed;
	struct work_struct work;

	bool do_ping;
	u32 ping_timeout;
};



void read_data(sycamore_t *sycamore, char * buffer, int lenth);
int sycamore_ioctl(sycamore_t *sycamore, struct tty_struct *tty, unsigned int cmd, unsigned long arg);
int sycamore_attach(sycamore_t *sycamore);
void sycamore_disconnect(sycamore_t *sycamore);


#endif //__SYCAMORE_PLATFORM_H__
