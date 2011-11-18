/*
 * pci-sycamore.c - a pcie bridge for a sycamore implementation with a PCIE 
 * interface
 * NOTE This code was built from the pci_bridge.c code in the Opencores.org 
 * project pci-bridge
 * 
 * I wish to express my sincere appreciation for this work
 *
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD PARTY
 * RIGHTS. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES
 * OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */


/*
 * Build/use notes (you will need to be superuser to install and remove 
 * this driver
 */ 


#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/init.h>
#include <linux/cdev.h>
#include <linux/fs.h>

//#include <asm/byteorder.h>              /* PCI is little endian */
#include <asm/uaccess.h>                /* copy to/from user */

#include "kint.h"

#define PCI_SYCAMORE_DEVICE_ID 0x0001
#define PCI_SYCAMORE_VENDOR_ID 0xC594
#define PCI_DRIVER_NAME "pci-sycamore"

#define BRIDGE_MEM_MAPPED 0
#define BRIDGE_IO_MAPPED 1

/*
 * udev will match up this vendor id and this device id before it will
 * install this driver
 */
static struct pci_device_id sycamore_ids[] = {
	{ PCI_DEVICE(PCI_SYCAMORE_VENDOR_ID, PCI_SYCAMORE_DEVICE_ID), },
	{ 0, }
};

/* 
 * Tell the module loading and udev what PCI device this module supports
 */
MODULE_DEVICE_TABLE(pci, sycamore_ids);


/*
 * Hardware insert function
 */
static int sycamore_probe(struct pci_dev *, const struct pci_device_id *);
/*
 * Hardware remove function
 */
static void sycamore_remove(struct pci_dev *);

static struct pci_driver sycamore_driver = {
	.name = PCI_DRIVER_NAME,
	.id_table = sycamore_ids,
	.probe = sycamore_probe,
	.remove = sycamore_remove,
};


/*
 * File operations
 */
int sycamore_open(struct inode *, struct file *);
int sycamore_release(struct inode *, struct file *);
ssize_t sycamore_read(struct file *, char __user *, size_t, loff_t *);
ssize_t sycamore_write(struct file *, const char __user *, size_t, loff_t *);
int sycamore_ioctl(struct inode *pnode, struct file *filp, unsigned int cmd, unsigned long arg);

loff_t sycamore_lseek(struct file *filp, loff_t offset, int origin);

static struct file_operations sycamore_fops = {
	read: sycamore_read,
	write: sycamore_write,
	open: sycamore_open,
	unlocked_ioctl: sycamore_ioctl,
	llseek: sycamore_lseek
};


static int __init sycamore_init(void);
static void __exit sycamore_exit(void);


/*
 * Let the system allocate the major number dynamically by setting this to
 * zero
 */
static int sycamore_init_major = 0;
static int sycamore_major;


/*
 * Per-device structure
 */

 #define NUM_OF_BASES 6
static struct sycamore_dev {
	struct cdev cdev;
	struct pci_dev *pcidev;
	int current_resource;
	u32 page_addr;
	u8 num_of_bases;
	int base_map[NUM_OF_BASES];
	u32 bases[NUM_OF_BASES];
	u32 base_size[NUM_OF_BASES];
	u32 base_page_offset;
	u32 offset;
} *sycamore_devices;

/*
 * sycamore_probe: when the hardware device is inserted
 * enable the PCI device
 * do various hardware configurations
 */
static int sycamore_probe(struct pci_dev *pcidev, const struct pci_device_id *id){
	struct sycamore_dev *dev;
	printk("sycamore_probe called\n");
	if (pcidev == NULL){
		printk(KERN_NOTICE "sycamore_probe: PCI_DEV is NULL\n");
		return -EINVAL;
	}
	//only one device for now
	dev = sycamore_devices;
	if (dev == NULL){
		printk("sycamore_probe: device structure not allocated\n");
	}
	else {
		pci_enable_device(pcidev);
		dev->pcidev = pcidev;
	}
	return 0;
}

/*
 * sycamore_remove: pci remove device
 */
static void __devexit sycamore_remove(struct pci_dev *dev){
	printk("sycamore_remove called\n");
}
/*
 * sycamore_init: called when the module is loaded and before probe 
 */
static int __init sycamore_init(void){
	struct sycamore_dev *dev;
	dev_t devno;
	int result;
	unsigned short num_of_bases;
	u32 base_address;
	printk("sycamore_init called\n");

	/*
	 * Allocate the per-device structure(s)
	 */
	sycamore_devices = kmalloc(sizeof(struct sycamore_dev), GFP_KERNEL);
	if (sycamore_devices == NULL){
		result = -ENOMEM;
		goto fail;
	}

	/*
	 * Get a range of minor numbers to work with, asking for a dynamic
	 * major unless directed otherwise at load time.
	 */
	
	if (sycamore_init_major != 0){
		sycamore_major = sycamore_init_major;
		devno = MKDEV(sycamore_major, 0);
		result = register_chrdev_region(devno, 1, PCI_DRIVER_NAME);
	}
	else {
		//let the system assign the major number dynamically
		result = alloc_chrdev_region(&devno, 0, 1, PCI_DRIVER_NAME);
		sycamore_major = MAJOR(devno);
	}
	if (result < 0){
		printk(KERN_NOTICE "sycamore_init: can't get major %d\n", sycamore_major);
		goto fail;
	}

	//only one device for now
	dev = sycamore_devices;
	
	/*
	 * Initialize and add this device's character device table entry
	 */
	dev->pcidev = NULL;
	//initialize a character device
	cdev_init(&dev->cdev, &sycamore_fops);
	dev->cdev.owner = THIS_MODULE;
	dev->cdev.ops = &sycamore_fops;
	dev->offset = 0;
	//register the CDEV into the system
	result = cdev_add(&dev->cdev, devno, 1);

	//configure the pci device
	if (result){
			printk(KERN_NOTICE "Error %d adding %s device", result, PCI_DRIVER_NAME);
			goto fail;
	}
	if ((result = pci_register_driver(&sycamore_driver)) != 0){
			printk(KERN_NOTICE "Error %d registering %s PCI device", result, PCI_DRIVER_NAME);
			goto fail;
	}
	if (dev->pcidev == NULL){
			printk(KERN_NOTICE "sycamore_init: PCI DEV is NULL, probe failed\n");
			goto fail;
	}

	//get the physical base addresses of the PCI
	base_address = pci_resource_start(dev->pcidev, 0);

	printk("<1> Frist base address register found at %08X \n", pci_resource_start(dev->pcidev, 0));
	num_of_bases = 0;

	//why are bases less than 6?
	while ((base_address = pci_resource_start(dev->pcidev, num_of_bases)) != 0x00000000 && (num_of_bases < NUM_OF_BASES)){

		unsigned long flags;
		flags = pci_resource_flags(dev->pcidev, num_of_bases);
		dev->bases[num_of_bases] = base_address;
		dev->base_size[num_of_bases] = pci_resource_end(dev->pcidev, num_of_bases) - base_address + 1;

		if (flags & IORESOURCE_IO){
			//resource is IO mapped
			dev->base_map[num_of_bases] = BRIDGE_IO_MAPPED;
		}
		else {
			//resource is MEM mapped
			dev->base_map[num_of_bases] = BRIDGE_MEM_MAPPED;
		}
		num_of_bases++;
	}

	if (num_of_bases < 1){
		printk("<1>No implemented base address register found!\n");
	}

	dev->current_resource = -1;

	//store number of bases in structure
	dev->num_of_bases = num_of_bases;
	printk("num_of_bases found %d\n", num_of_bases);
	//display information about all base addresses found in this procedure
	for (num_of_bases = 0; num_of_bases < dev->num_of_bases; num_of_bases++){
		printk("<1>BAR%d range from %08X to %08X \n", num_of_bases, dev->bases[num_of_bases], dev->bases[num_of_bases] + dev->base_size[num_of_bases]);
	}

	return 0;

fail:
	sycamore_exit();
	return result;
}

/*
 * sycamore_exit: module exit function, when the software module has
 * been removed
 */
static void __exit sycamore_exit(void){
	printk("sycamore_exit called\n");
	if (sycamore_devices){
		struct sycamore_dev *dev;
		dev = &sycamore_devices[0];
		cdev_del(&dev->cdev);
		kfree(sycamore_devices);
		sycamore_devices = NULL;
	}
	unregister_chrdev_region(MKDEV(sycamore_major, 0), 1);
	sycamore_major = 0;
	pci_unregister_driver(&sycamore_driver);
}


/*
 * File Operations
 */

/*
 * sycamore_open: open a file
 */
int sycamore_open(struct inode *inode, struct file *filep){
	struct sycamore_dev *dev;
	dev = container_of(inode->i_cdev, struct sycamore_dev, cdev);
	//use private_data to identify the device to access
	filep->private_data = dev;
	dev->current_resource = -1;
	//Success	
	return 0;
}

int sycamore_release(struct inode *inode, struct file *filep){
	//don't really release anything
	return 0;
}


loff_t sycamore_lseek(struct file *filp, loff_t offset, int origin){
	struct sycamore_dev *dev;
	loff_t requested_offset = 0;
	int resource_num;

	//get the device pointer from file pointer's private data
	dev = filp->private_data;
	resource_num = dev->current_resource;

	//depending on where we are in the file effects how we handle a seek
	switch (origin){
		case SEEK_CUR: 
			requested_offset = dev->offset + offset;
			break;
		case SEEK_END:
			requested_offset = dev->base_size[resource_num] + offset;
			break;
		default:
			//begining
			requested_offset = offset;
			break;
	}

	//check if the position if legal
	if ((requested_offset < 0) || (requested_offset > dev->base_size[resource_num])){
		return -EFAULT;
	}

	dev->offset = requested_offset;
	return requested_offset;
}

/*
 * sycamore_read: read processing
 */
ssize_t sycamore_read(struct file *filp, char *buf, size_t count, loff_t *offset_out){
	struct sycamore_dev *dev;
	unsigned long current_address;
	unsigned long actual_count;
	unsigned long offset;
	int resource_num;
	int i;
	unsigned int value;
	unsigned int *kern_buf;
	unsigned int *kern_buf_tmp;
	unsigned long size;
	int result;

	//the pointer to the device is the private data
	dev = filp->private_data;
	offset = dev->offset;
	resource_num = dev->current_resource;
	size = dev->base_size[resource_num];
	current_address = dev->page_addr + dev->base_page_offset + dev->offset;

	//check if this is a valid resource
	if (dev->current_resource < 0){
		return -ENODEV;
	}
	//if the offset is out of range return nothing
	if (offset == size){
		return 0;
	}
	/*	if the offset + count is greater than the size then change the actual
	 * count
	 */
	if ((offset + count) > size){
		actual_count = size - offset;
	}
	else {
		actual_count = count;
	}

	//verify if it is okay to copy from an area
	if ((result = access_ok(VERIFY_WRITE, buf, actual_count)) == 0){
		return result;
	}

	kern_buf = kmalloc(actual_count, GFP_KERNEL | GFP_DMA);
	kern_buf_tmp = kern_buf;
	if (kern_buf <= 0){
		//failed to allocate space
		return 0;
	}


	//copy the data from the IO to a buffer in the kernel
	memcpy_fromio (kern_buf, current_address, actual_count);
	i = actual_count / 4;
	//copy data from the kernel to user space
	while (i--){
		value = *(kern_buf);
		put_user(value, ((unsigned int *) buf));
		buf += 4;
		++kern_buf;
	}

	kfree(kern_buf_tmp);
	dev->offset = dev->offset + actual_count;
	*(offset_out) = dev->offset;

	return actual_count;
}
ssize_t sycamore_write(struct file *filp, const char *buf, size_t count, loff_t *offset_out){
	struct sycamore_dev *dev;
	unsigned long current_address;
	unsigned long actual_count;
	unsigned long offset;
	int resource_num;
	int i;
	int value;
	unsigned long size;
	int result;
	int *kern_buf;
	int *kern_buf_tmp;

	dev = filp->private_data;
	current_address = dev->page_addr + dev->base_page_offset + dev->offset;
	resource_num = dev->current_resource;
	size = dev->base_size[resource_num];
	offset = dev->offset;

	if (dev->current_resource < 0){
		//resource number is too big
		return -ENODEV;
	}
	if (offset == size){
		//attempted to write to a location further than the size
		return 0;
	}
	if ((offset + count) > size){
		//trip the count to be within the size
		actual_count = size - offset;
	}
	else {
		actual_count = count;
	}

	//verify if we can copy from that range
	if ((result = access_ok(VERIFY_READ, buf, actual_count)) == 0){
		return 0;
	}
	//allocation some space for the buffer in kernel land
	kern_buf = kmalloc(actual_count, GFP_KERNEL | GFP_DMA);
	kern_buf_tmp = kern_buf;

	if (kern_buf <= 0){
		return 0;
	}
	i = actual_count / 4;
	while (i--){
		//copy 32bits at a time	
		get_user(value, ((int *) buf));
		*kern_buf = value;
		buf += 4;
		++kern_buf;
	}

	//copy it out to the IO
	memcpy_toio(current_address, kern_buf_tmp, actual_count);
	kfree(kern_buf_tmp);
	dev->offset = dev->offset + actual_count;
	*(offset_out) = dev->offset;

	return actual_count;
}

/*
 * helper function for memory remapping
 */
int open_mem_mapped(struct sycamore_dev *dev){
	int resource_num = dev->current_resource;
	unsigned long num_of_pages = 0;
	unsigned long base = dev->bases[resource_num];
	unsigned long size = dev->base_size[resource_num];

	//WHERE IS PAGE_SIZE and PAGE_MASK comming from?
	if (!(num_of_pages = (unsigned long) (size/PAGE_SIZE))){
		//cut the sizes into PAGE_SIZE to work with the CPU's memory
		num_of_pages++;
	}

	dev->base_page_offset = base & ~PAGE_MASK;

	if ((dev->base_page_offset + size) < (num_of_pages * PAGE_SIZE)){
		num_of_pages++;
	}

	//remap memory mapped space
	dev->page_addr = (unsigned long) ioremap(base & PAGE_MASK, num_of_pages * PAGE_SIZE);

	if (dev->page_addr == 0x00000000){
		return -ENOMEM;
	}

	return 0;

}


/*
 * ioctl: see kint.h for the meaning of the args
 */
int sycamore_ioctl(struct inode *pnode, struct file *filp, unsigned int cmd, unsigned long arg){
	int error = 0;
	unsigned long base;
	unsigned long base_size;
	struct sycamore_dev *dev = filp->private_data;

	if (_IOC_TYPE(cmd) != BRIDGE_IOC_NUM){
		return -EINVAL;
	}
	if (_IOC_NR(cmd) > BRIDGE_IOC_MAX_NUM){
		return -EINVAL;
	}

	switch (cmd){
		case BRIDGE_IOC_CURRESGET:
			//current resoruce - they start at 1
			return (dev->current_resource + 1);
		case BRIDGE_IOC_CURRESSET:
			//check if resource is in a range of implementation
			if (arg < 0){
				return -EINVAL;
			}
			//unmap previous reousre if it was mapped
			if (dev->current_resource >= 0){
				iounmap((void *)dev->page_addr);
			}
			if (arg == 0){
				//previous resource unmapped
				dev->current_resource = -1;
				return 0;
			}
			if (dev->num_of_bases < arg){
				return -ENODEV;
			}
			//IO mapped not supported yet
			if (dev->base_map[arg - 1] == BRIDGE_IO_MAPPED){
				//set current resource to none, since it was unmapped
				dev->current_resource = -1;
				return -ENODEV;
			}

			dev->current_resource = (int) (arg - 1);

			//remap new resource
			error = open_mem_mapped(dev);
			if (error != 0){
				dev->current_resource = -1;
				return error;
			}
			return 0;
		case BRIDGE_IOC_CURBASE:
			//check if any resourcei s currently activated
			if (dev->current_resource >= 0){
				base = dev->bases[dev->current_resource];
				printk("\n CURR_RES = %d", dev->current_resource);
			}
			else {
				base = 0x00000000;
			}
			*(unsigned long *) arg = base;
			return 0;

		case BRIDGE_IOC_CURBASEMAP:
			//check if any reosuce is currently activated
			if(dev->current_resource >= 0){
				base = dev->page_addr;
			}
			else {
				base = 0x00000000;
			}

			*(unsigned long *) arg = base;
			return 0;

		case BRIDGE_IOC_CURBASESIZE:
			//check if any resource is currently activated
			if (dev->current_resource >= 0){
				base_size = dev->base_size[dev->current_resource];
			}
			else {
				base_size = 0x00000000;
			}

			*(unsigned long *)arg = base_size;
			return 0;

		case BRIDGE_IOC_NUMOFRES:
			return (dev->num_of_bases);

		default:
			return -EINVAL;
	}
}


MODULE_LICENSE("GPL");

module_init(sycamore_init);
module_exit(sycamore_exit);
