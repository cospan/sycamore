from array import array as Array
from pyftdi import spi
from pyftdi.misc import hexdump
import sys
import time


"""
	Features:
		
	-Communicates directly with the chip
	-Sets the mode of port B from Async FT245 to SPI and back
	-Programs the SPI PROM
	-Asserts/Deasserts the GPIOs to do various FPGA controls
		-Initiate a program of the FPGA
	-Changes the mode of the pins to synchronous FT245 mode to
		achieve 25MByte throughput
	-Give the kernel control of the driver or takes control away

"""


def Sycamore1():
	
	def __init__(self):
		self.manager = spi.serialflash.SerialFlashManager(0x0403, 0x6010, 2)
		self.flash = self.manager.get_flash_device()

	

	def get_flash_name(self):
		return self.flash
		


def main():
	print ("instantiating sycamore1")
	s1 = Sycamore1()

	print "flash name: " + s1.get_flash_name()


if __name__ == "__main__":
	main()

