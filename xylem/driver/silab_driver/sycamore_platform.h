//sycamore_platform.h

#ifndef __SYCAMORE_PLATFORM_H__
#define __SYCAMORE_PLATFORM_H__

#include <linux/tty.h>
#include <linux/workqueue.h>

#define SYCAMORE_BUS_NAME "sycamore"

#define BUFFER_SIZE 512

typedef struct _sycamore_t sycamore_t;


typedef int (*write_func_t) (const void * data, const unsigned char * buf, int count);

#define READ_IDLE 		0
#define READ_SIZE 		1
#define READ_COMMAND 	2
#define READ_ADDRESS 	3
#define READ_DATA 		4

#define MAX_NUM_OF_DEVICES 256

#define SYCAMORE_WQ_NAME "sycamore_wq"

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
	struct tty_struct *tty;

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


	struct platform_device * devices[MAX_NUM_OF_DEVICES];

	write_func_t write_func;
	void * write_data;

	//workqueue for ping
	struct delayed_work work;

	bool do_ping;
	u32 ping_timeout;
};



void sycamore_set_write_func(sycamore_t *sycamore, write_func_t write_func, void * data);
void sycamore_periodic(struct work_struct *work);
void sycamore_read_data(sycamore_t *sycamore, char * buffer, int lenth);
int sycamore_ioctl(sycamore_t *sycamore, unsigned int cmd, unsigned long arg);
int sycamore_attach(sycamore_t *sycamore, struct tty_struct * tty);
void sycamore_disconnect(sycamore_t *sycamore);

//int sycamore_open_tty_port(struct tty_port * port, struct tty_struct *tty);
//void sycamore_close_tty_port(struct tty_port *port, struct tty_struct *tty);

#endif //__SYCAMORE_PLATFORM_H__
