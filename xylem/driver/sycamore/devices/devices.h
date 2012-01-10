//devices.h


/**
 * devices
 * Description: Listing of all the virtual devices that sycamore has
 *	in the future I would like to make this a less monolithic structure
 *
 **/

#ifndef __SYC_DEVICES_H__
#define __SYC_DEVICES_H__

#include "drt/drt.h"
#include "gpio/gpio_device.h"


#define DEVICE_DRT_NAME				"drt"
#define DEVICE_GPIO_NAME			"syc-gpio"
#define DEVICE_UART_NAME			"syc-uart"
#define DEVICE_I2C_NAME				"syc-i2c"
#define DEVICE_SPI_NAME				"syc-spi"
#define DEVICE_MEMORY_NAME			"syc-mem"
#define DEVICE_CONSOLE_NAME			"syc-console"
#define DEVICE_FSMC_NAME			"syc-fsmc"
#define DEVICE_FRAME_BUFFER_NAME 	"syc-fb"

//devices
#define DEVICE_DRT 					0
#define DEVICE_GPIO					1
#define DEVICE_UART					2
#define DEVICE_I2C					3
#define DEVICE_SPI					4
#define DEVICE_MEMORY				5
#define DEVICE_CONSOLE				6
#define DEVICE_FSMC					7
#define DEVICE_FRAME_BUFFER			10

#endif
