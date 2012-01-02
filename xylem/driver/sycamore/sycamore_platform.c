//sycamore_platform.c
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/serial.h>
#include <linux/sched.h>
#include "sycamore_commands.h"
#include "sycamore_control.h"
#include "sycamore_platform.h"
#include "sycamore_control.h"



//parse the data


//static struct platform_device sycamore_tty ={
//	.name = "sycamore_tty",
//	.id = -1,
//};
/*
static struct gpio_led gpio_leds[] = {
	{
		.name = "sycamore::led0",
		.default_trigger = "sycamore_go",
		.gpio = 150,
	},
};

static struct gpio_led_platform_data gpio_led_info = {
	.leds = gpio_leds,
	.num_leds = ARRAY_SIZE(gpio_leds),
};
static struct platform_device leds_gpio = {
	.name = "leds-gpio",
	.id = -1,
	.dev = {
		.platform_data = &gpio_led_info,
	},
};

*/
static ssize_t show_test(struct device *dev,
			  struct device_attribute *attr,
			  char *buf){

//	sycamore_t *sycamore = dev_get_drvdata(dev);
	return sprintf (buf, "hi\r\n");

}

static struct device_attribute dev_attr_test = {
	.attr = {
		.name = "test_name",
		.mode = 0444 },
	.show = show_test 
};

static struct attribute *platform_attributes[] = {
	&dev_attr_test.attr,
	NULL
};

int generate_platform_devices(sycamore_t *sycamore){
	sycamore->platform_attribute_group.attrs = platform_attributes;	
	return 0;
}


void sycamore_periodic(struct work_struct *work){
	//get a pointer to sycamore
	sycamore_t *sycamore = NULL;
	sycamore = container_of(work, sycamore_t, periodic_work);	
	sycamore_control_periodic(sycamore);
}

/*
	read data as it comes in, it's more than likely that data
	will come in one byte at a time, so this state machine can assemble the
	information a peice at a time
*/

void sycamore_read_data(sycamore_t *s, char * buffer, int length){
	sycamore_control_process_read_data(s, buffer, length);
}


void sycamore_set_write_func(sycamore_t *sycamore, hardware_write_func_t write_func, void * data){
	printk("%s: setting the write function to %p\n", __func__, write_func);
	sycamore->write_func = write_func;
	sycamore->write_data = data;
	
}
int sycamore_attach(sycamore_t *sycamore){

	//initialize the sycamore structure
	int result = 0;
	int i = 0;

	//sycamore = (sycamore_t *) kzalloc(sizeof(sycamore_t), GFP_KERNEL);
	sycamore->platform_device = NULL;
	atomic_set(&sycamore->port_lock, 0);
	sycamore->size_of_drt 	=	0;
	sycamore->drt			=	NULL;
	sycamore->drt_state		=	DRT_READ_IDLE;	
	sycamore->pdev			=	NULL;
	sycamore->read_pos		=	0;
	sycamore->read_state	=	READ_IDLE;
	sycamore->write_func	=	NULL;
	sycamore->write_data	=	NULL;
	memset (&sycamore->write_buffer[0], 0, WRITE_BUF_SIZE);

//workqueue setup

	sycamore->ping_timeout	=	DEFAULT_PING_TIMEOUT;	
	sycamore->do_ping		=	true;
	sycamore->enable_periodic	= false;
	sycamore->sycamore_found =	false;

//	sycamore->wq = create_single_thread_workqueue("sycamore workqueue");
	INIT_DELAYED_WORK(&sycamore->periodic_work, sycamore_periodic); 
	INIT_WORK(&sycamore->write_work, sycamore_write_work);
	INIT_WORK(&sycamore->control_work, sycamore_control_work);	

	init_waitqueue_head(&sycamore->write_queue);
	init_waitqueue_head(&sycamore->read_queue);
	

	for (i = 0; i < MAX_NUM_OF_DEVICES; i++){
		//a NUL here will tell the read function that there is no device
		sycamore->devices[i] = NULL;
	}


	//generate the platform bus
	sycamore->platform_device = platform_device_alloc(SYCAMORE_BUS_NAME, -1);
	if (!sycamore->platform_device){
		//dbg("%s Error, couldn't allocate space for sycamore->platform_device", __func__);
		return -ENOMEM;
	}

	//XXX: This may require a bus number afterwards to indicate multiple sycamore buses
	platform_set_drvdata(sycamore->platform_device, sycamore);

	//now we need to add the bus to system
	result = platform_device_add(sycamore->platform_device);

	if (result != 0){
		goto fail_platform_device;
	}

	//create a all the sub items sysfs bus entry

	generate_platform_devices(sycamore);
	result = sysfs_create_group(&sycamore->platform_device->dev.kobj, &sycamore->platform_attribute_group);

	if (result != 0){
		goto fail_sysfs;
	}

	//create a platform device
	//platform_device_register(&sycamore_tty);
	sycamore->pdev = platform_device_register_simple("sycamore_tty", -1, NULL, 0);

	//return 1 cause we dont want a device file in the /dev directory right now

//removed the schedule periodic function here
	schedule_work(&sycamore->control_work);	
	return 1;

fail_sysfs:
	platform_device_del(sycamore->platform_device);
fail_platform_device:
	platform_device_put(sycamore->platform_device);
	return result;
}

void sycamore_disconnect(sycamore_t *sycamore){
	
	//make sure things are not null
	if (sycamore == NULL){
		printk ("Sycmoare == NULL");
		return;
	}
	sycamore->enable_periodic = false;
	cancel_delayed_work_sync(&sycamore->periodic_work);
	cancel_work_sync(&sycamore->control_work);
	cancel_work_sync(&sycamore->write_work);
	if (sycamore->size_of_drt > 0) {
		//DRT has a string
		kfree(sycamore->drt);
		sycamore->size_of_drt = 0;
	}

	//remove the group
	platform_device_unregister(sycamore->pdev);


	//remove the platform device

//	platform_device_unregister(&sycamore_tty);
	//end remove the platform device
	platform_device_del(sycamore->platform_device);
	platform_device_put(sycamore->platform_device);


}


void sycamore_write_callback(sycamore_t *sycamore){
	printk("%s: scheduling a work response\n", __func__);
	
	schedule_work(&sycamore->write_work);
}


int sycamore_bus_write(sycamore_dev_t *dev, u32 command, u32 addr, const char *buffer, u32 count){
	sycamore_t *s = NULL;

	s = dev->sycamore;
	//check if the port is locked
	if (atomic_read(&s->port_lock) == 0){
		//if not blocking return imediately
		if (!dev->blocking){
			return -EAGAIN;
		}
		
		//blocking
		if (wait_event_interruptible_exclusive(s->write_queue, (atomic_read(&s->port_lock) == 0))){
			//interrupt happened check for siganl
//XXX: what signal should I check for?
			return -ERESTARTSYS;
		}
	}


	//alright everything is good to go right now
	return sycamore_write(s,
					command,				//either a read or write
					dev->device_address,	
					addr,
					(char *)buffer,
					count);

}

int sycamore_bus_read(sycamore_dev_t *dev){
	sycamore_t *s = NULL;

	s = dev->sycamore;
	//check if the port is locked

	//even though this is a read, we still need to write the request down to sycamore on a common bus
	if (wait_event_interruptible(s->read_queue, (atomic_read(&dev->read_data_ready) == 1))){
		//interrupt happened check for siganl
//XXX: what signal should I check for?
		return -ERESTARTSYS;
	}
	return dev->read_count;

}


