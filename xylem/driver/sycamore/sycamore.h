//main sycamore include


#ifndef __SYCAMORE_H__
#define __SYCAMORE_H__

#include <linux/platform_device.h>

#define MAX_NUM_OF_DEVICES 256

#define READ_IDLE 		0
#define READ_SIZE 		1
#define READ_COMMAND 	2
#define READ_ADDRESS 	3
#define READ_DATA 		4


#define DRT_READ_INIT 		0
#define DRT_READ_START		1
#define DRT_READ_ALL		2
#define DRT_READ_SUCCESS 	3
#define DRT_READ_FAIL		4

//1 second timeout
#define DEFAULT_PING_TIMEOUT 1000

typedef struct _sycamore_t sycamore_t;
typedef struct _sycamore_dev_t sycamore_dev_t;

//callback for a device read functin
typedef int (*sycamore_dev_read_t) (sycamore_dev_t *dev, const char *buffer, int count);
//hardware callback whenever we want to perform a write to the controlling device
typedef int (*hardware_write_func_t) (const void * data, const unsigned char * buf, int count);


struct _sycamore_dev_t {
	sycamore_dev_read_t read;
	int device_address;
	
	sycamore_t *sycamore;
};


//sycamore_platfrom data
struct _sycamore_t {
	//platform stuff
	struct platform_device *platform_device;
	struct attribute_group platform_attribute_group;

	int	port_lock;
	struct platform_device *pdev;

	int read_pos;
//	char in_buffer[BUFFER_SIZE];

	hardware_write_func_t write_func;
	void * write_data;


	//workqueue for ping
	struct delayed_work work;

	//workqueue for write


//control

	//read state machine variables
	int read_state;
	u32 read_command;
	u32	read_data;
	u32 read_size;
	u32 read_data_count;
	u32 read_data_pos;
	u32 read_address;
	u32 read_device_address;


	bool do_ping;
	//if we got a ping, set this to true
	bool sycamore_found;
	u32 ping_timeout;

	u32	size_of_drt;
	u32 drt_state;
	char * drt;
	u16	drt_version;
	u32 number_of_devices;

	//sycamore_bus interface
	struct platform_device * devices[MAX_NUM_OF_DEVICES];
};


//create/destroy a sycamore device
sycamore_dev_t * sycamore_dev_create(sycamore_t *sycamore, int device_address);
void sycamore_dev_destroy(sycamore_dev_t *dev);


//write to the sycamore bus
int sycamore_bus_write(sycamore_dev_t *dev, const char *buffer, int count);

#endif
