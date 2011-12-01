//sycamore_platform.h

#ifndef __SYCAMORE_PLATFORM_H__
#define __SYCAMORE_PLATFORM_H__

#define SYCAMORE_BUS_NAME "sycamore"

typedef struct _sycamore_t sycamore_t;

//sycamore_platfrom data
struct _sycamore_t {
	//platform stuff
	struct platform_device *platform_device;
	struct attribute_group platform_attribute_group;
	u32	size_of_drt;
	char * drt;
	int	port_lock;
	struct platform_device *pdev;
};



int sycamore_ioctl(sycamore_t *sycamore, unsigned int cmd, unsigned long arg);
int sycamore_attach(sycamore_t *sycamore);
void sycamore_disconnect(sycamore_t *sycamore);


#endif //__SYCAMORE_PLATFORM_H__
