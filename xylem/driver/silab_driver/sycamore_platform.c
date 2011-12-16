//sycamore_platform.c
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include <linux/string.h>
#include "sycamore_platform.h"
#include "sycamore_ioctl.h"
#include "sycamore_commands.h"



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

/*
	read data as it comes in, it's more than likely that data
	will come in one byte at a time, so this state machine can assemble the
	information a peice at a time
*/
void read_data(sycamore_t *s, char * buffer, int length){
	int i = 0;
	char ch = 0;
	for(i = 0; i < length; ++i){
		ch = buffer[i];
//		printk ("%c", ch);
		//process each character as it comes in
		if (ch == 'S'){

			printk("\nFound S\n");
		/*
			if the current byte is is 'S' we are starting to read a new packet

			in this case there might be a chance that data didn't get all the way
			through so I might have to tell the current virtual device I'm
			writing to (from the device's point of view reading) that the
			rest of the data transfer was cancelled
		*/
			//reset all variables
			s->read_command 		= 0;
			s->read_size 			= 0;
			s->read_data			= 0;
			s->read_data_count		= 0;
			s->read_data_pos		= 0;
			s->read_address 		= 0;
			s->read_device_address	= 0;
			s->read_pos				= 0;
			s->read_state			= READ_SIZE;
			continue;
		}
		
		switch (s->read_state){
			case (READ_IDLE):
				//nothing to see here, move along
				continue;
				break;
			case (READ_SIZE):
				
				/*
				   the next seven bytes is the number
				   of bytes to read (not including
				   the first 32 bit word
				 */
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				s->read_pos++;
				s->read_size += ch;

				//transition condition
				if (s->read_pos == 7){
					
					//setup the read data count to at least read the first
					//32 bit word
					s->read_data_count = s->read_size + 1;
					s->read_state = READ_COMMAND;
					s->read_pos = 0;
					printk ("%s: read size = %d\n", __func__, s->read_size);
				}
				else {
					//shift the data up by four
					s->read_size = s->read_size << 4;
				}
				break;
			case (READ_COMMAND):
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				s->read_command += ch;	
				s->read_pos++;
				//transition condition
				if (s->read_pos == 8){
					/*
					   the next eight bytes is the command
					   inverted from the write
					 */ 
//					 printk("%s: Received command: %8X\n", __func__, s->read_command);
					 s->read_command = ~(s->read_command);
					 switch (s->read_command){
					 	case (SYCAMORE_PING): 
							printk("%s: Received a ping response\n", __func__);
							break;
						case (SYCAMORE_WRITE):
							printk("%s: Received a write ack\n", __func__);
							break;
						case (SYCAMORE_READ):
							printk("%s: Received a read response\n", __func__);
							break;
						case (~SYCAMORE_INTERRUPTS):
							//this is the only command that isn't inverted
							printk("%s: Received an interrupt\n", __func__);
							s->read_command = ~(s->read_command);
							//respond to interrupts
							break;
						default:
							printk("%s: Received an illegal command!, resetting state machine: %8X\n", __func__, s->read_command);
							s->read_state = READ_IDLE;
							continue;
							break;
					 }
					/*
					   if the command was read we will need
					   to read all the data back
					 */

					s->read_pos	=	0;
					s->read_state = READ_ADDRESS;
				}
				else {
					s->read_command = s->read_command << 4;
				}
				break;
			case (READ_ADDRESS):
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				s->read_address += ch;	
				s->read_pos++;

				/*
				   the next eight bytes is the address
				 */
				/*
				   if the address top two bytes == 0
				   then this is a control packet
				   if the address top two bytes == FF
				   then this is a interrupt
				 */

				//transition condition
				if (s->read_pos == 8) {
					s->read_device_address = (s->read_address & 0xFF000000) >> 24;
					s->read_address = (s->read_address & 0x00FFFFFF);
					s->read_state = READ_DATA;
					s->read_pos = 0;
					s->read_data = 0;
				}
				else {
					s->read_address = s->read_address << 4;
				}
				break;
			case (READ_DATA):
				if (ch >= 'A'){
					//take care of the hex values greater than 9
					ch -= ('A' - 10); //compiler optimize this please
				}
				else {
					ch -= '0';
				}
				s->read_data += ch;	
				s->read_pos++;


				/*
				   if the command was a read then we 
				   need to possibly count the data in
				   the first 8 bytes are always there
				 */
				if (s->read_pos == 8){
					//process the data out
//XXX need to write to the associated driver
					if (s->devices[s->read_device_address] != NULL){
//XXX: call the devices read function
						/*
							send the address
							send the total data size
							send the data position
						*/
/* sycamore_device_read(
			s, 
			s->read_address, 
			s->read_size + 1, 
			s->read_data_pos, 
			s->read_data); 
*/
					}

					s->read_data_count--;
					//see if we are done
					if (s->read_data_count == 0){
						s->read_state = READ_IDLE;
						printk("%s: parsed data\n", __func__);
						printk("c:%8X\n", s->read_command);
						printk("a:%8X : %6X\n", s->read_device_address, s->read_address);
						printk("s:%8d\n", s->read_size + 1);
						printk("d:%.8X\n\n", s->read_data);
					}
					else {
						s->read_pos = 0;
						s->read_data = 0;
						s->read_data_pos++;
					}
				}
				else {
					s->read_data = s->read_data << 4;
				}
				break;
			default:
				/*
				   how did we get here?
				   something went wrong
				 */
				s->read_state = READ_IDLE;
				printk("%s: Entered Illegal state in read state machine", __func__);
				break;
		}
	}
	

}

int sycamore_ioctl(sycamore_t *sycamore, struct tty_struct *tty, unsigned int cmd, unsigned long arg){
	int count = 0;

	printk ("%s Entered function, with CMD: 0x%.4X\n", __func__, cmd);

	if (sycamore->port_lock){
		printk("%s sycamore is locked by another device\n", __func__);
	}


	switch (cmd) {
		case(PING_SYCAMORE): 
			printk ("%s Ping Function Called\n", __func__);
			tty->ops->write(tty, "L0000000000000000000000000000000", 32);
			count = tty_chars_in_buffer(tty);
			printk ("outgoing count: %d\n", count);
			tty_wait_until_sent(tty, 500);
//			tty->ops->read(tty, &buffer[0], 25);
			return 0;
		case(READ_DRT):
//printk("buffer: %s", &sycamore->in_buffer[0]);
		
			return 0;
		case(GET_DRT_SIZE):
			return 0;
	}
	//return success
	return 0;
}
int sycamore_attach(sycamore_t *sycamore){

	//initialize the sycamore structure
	int result = 0;
	int i = 0;

	//sycamore = (sycamore_t *) kzalloc(sizeof(sycamore_t), GFP_KERNEL);
	sycamore->platform_device = NULL;
	sycamore->port_lock 	=	0;
	sycamore->size_of_drt 	=	0;
	sycamore->drt			=	NULL;
	sycamore->pdev			=	NULL;
	sycamore->read_pos		=	0;
	sycamore->read_state	=	READ_IDLE;

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

	//end create platform device
	return 0;

fail_sysfs:
	platform_device_del(sycamore->platform_device);
fail_platform_device:
	platform_device_put(sycamore->platform_device);
	return result;

}
void sycamore_disconnect(sycamore_t *sycamore){
	
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


