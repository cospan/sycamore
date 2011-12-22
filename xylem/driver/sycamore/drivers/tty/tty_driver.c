
#include <linux/kernel.h>
#include <linux/tty.h>
#include <linux/tty_driver.h>
#include <linux/platform_device.h>

#define DRIVER_DESC "sycamore tty device"
#define DRIVER_VERSION "v0.01"

#define SYCAMORE_TTY_MAJOR 240


typedef struct _sycamore_tty_driver_t sycamore_tty_driver_t;

static int sycamore_platform_probe(struct platform_device *pdev);
static int __devexit sycamore_platform_remove(struct platform_device *pdev);

static int sycamore_tty_open(struct tty_driver * driver, struct file * filep);
static void sycamore_tty_close(struct tty_driver * driver, struct file * filep);
static int sycamore_tty_write(struct tty_struct * tty, 
								const unsigned char *buf, int count);
static int sycamore_tty_write_room(struct tty_struct * tty);
static int sycamore_tty_set_termios(struct tty_struct *tty, struct ktermios * old);

static struct platform_driver sycamore_platform_driver = {
	.probe	= sycamore_platform_probe,
	.remove = __devexit_p(sycamore_platform_remove),

	.driver = {
		.name = "sycamore_tty",
		.owner = THIS_MODULE,
	},
};

struct _sycamore_tty_driver_t {
	struct tty_driver *tty_driver;
	int lock;
};

static sycamore_tty_driver_t sycamore_tty_driver;

static struct tty_operations sycamore_tty_ops = {
	.open = sycamore_tty_open,
	.close = sycamore_tty_close,
	.write = sycamore_tty_write,
	.write_room = sycamore_tty_write_room,
	.set_termios = sycamore_tty_set_termios,
};


//insertion and removal of the module
static int __init sycamore_tty_init(void){
	int result = 0;
	result = platform_driver_register(&sycamore_platform_driver);	
	printk (KERN_INFO "%s: registering platform", __func__);
	if (result != 0){
		printk (KERN_INFO "%s: Failed to register platform device", __func__);
		return result;
	}
	sycamore_tty_driver.lock = 0;
	return 0;
}
static void __exit sycamore_tty_exit(void){
	printk (KERN_INFO "%s: unregistering platform", __func__);
	platform_driver_unregister(&sycamore_platform_driver);
}


//insertion and removal of a device
static int sycamore_platform_probe(struct platform_device *pdev){
	int result = 0;
	
	//allocate space for the sycamore_tty_device
	sycamore_tty_driver.tty_driver = alloc_tty_driver(1); //1 tty device
	
	if (sycamore_tty_driver.tty_driver == NULL) {
		return -ENOMEM;
	}
	

	//initialize the driver
	sycamore_tty_driver.tty_driver->owner = THIS_MODULE;
	sycamore_tty_driver.tty_driver->driver_name = "syc_tty";
	sycamore_tty_driver.tty_driver->name = "syc_tty";
	sycamore_tty_driver.tty_driver->major = SYCAMORE_TTY_MAJOR;

	sycamore_tty_driver.tty_driver->type = TTY_DRIVER_TYPE_SERIAL;
	sycamore_tty_driver.tty_driver->subtype = SERIAL_TYPE_NORMAL;
	sycamore_tty_driver.tty_driver->flags = TTY_DRIVER_REAL_RAW;
	sycamore_tty_driver.tty_driver->ops = &sycamore_tty_ops;

	sycamore_tty_driver.tty_driver->init_termios = tty_std_termios;
	sycamore_tty_driver.tty_driver->init_termios.c_cflag = B9600 | CS8 | CREAD | HUPCL | CLOCAL;
	//tty_set_operations(&sycamore_tty_driver.tty_driver, &sycamore_tty_ops);
	

	//register this tty_device
	//this line registers the first minor number too!, so if you only want one
	//then only register this one
	result = tty_register_driver(sycamore_tty_driver.tty_driver);
	if (result){
		printk(KERN_ERR "failed to register sycamore_tty_driver.tty_driver");
		//put_tty_driver(sycamore_tty_driver.tty_driver);
		return result;
	}

	//tty_register_device(sycamore_tty_driver.tty_driver, 0, NULL);

	printk(KERN_INFO DRIVER_DESC " " DRIVER_VERSION);
	return result;
}
static int __devexit sycamore_platform_remove(struct platform_device *pdev){

	tty_unregister_driver(sycamore_tty_driver.tty_driver);
	put_tty_driver(sycamore_tty_driver.tty_driver);
	return 0;
}


//tty specific operations
static int sycamore_tty_open(struct tty_driver * driver, struct file * filep){
	return 0;
}
static void sycamore_tty_close(struct tty_driver * driver, struct file * filep){
}
static int sycamore_tty_write(struct tty_struct * tty, 
								const unsigned char *buf, int count){
	printk (KERN_INFO "%s: user entered: %s", __func__, buf);
	return count;
}
static int sycamore_tty_write_room(struct tty_struct * tty){
	return 10;
}
static int sycamore_tty_set_termios(struct tty_struct *tty, struct ktermios * old){
	return 0;
}

module_init(sycamore_tty_init);
module_exit(sycamore_tty_exit);

MODULE_DESCRIPTION(DRIVER_DESC);
MODULE_VERSION(DRIVER_VERSION);
MODULE_LICENSE("GPL");
