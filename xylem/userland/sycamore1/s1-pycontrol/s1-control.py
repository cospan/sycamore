#!/usr/bin/env python
from array import array as Array
import sys
import time
import getopt 
import os


from bitbang.bitbang import BitBangController
from spi_flash import serialflash
from fifo.fifo import FifoController

from spi_flash import numonyx_flash


"""
	Changelog
	02/04/2012
		added the feature to change to FIFO mode '-c'
		added the feature to change to config mode '-x'
"""

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

def usage():
	"""prints out a helpful message to the user"""
	print ""
	print "usage: s1-command.py [options] <filename>"
	print ""
	print "filename: bin file to program the FPGA"
	print ""
	print "options:"
	print "-h\t--help\t\t\t: displays this help"
	print "-v\t--verbose\t\t: print out lots of info"
	print "-d\t--debug\t\t\t: enables debug settings"
	print "-r\t--soft_reset\t\t: resets the internal state machine"
	print "-p\t--program\t\t: resets the FPGA an initiate a configuration"
	print "-c\t--comm\t\t\t: changes comm mode to highspeed fifo"
	print "-x\t--config\t\t: change the comm to configuration mdoe"
	print "-z\t--read_back\t\t: readback the .bin image to the filename given"
	print ""
	print "Examples:"
	print "\tupdload the bin file and program the FPGA"
	print "\t\ts1-command.py bitfile.bin"
	print ""
	print "\treset the FPGA and program without loading a new bin file"
	print "\t\ts1-command.py -p"
	print ""
	print "\treset the internal state machine of the FPGA"
	print "\t\ts1-command.py -r"
	print ""
	print "\tread back the .bin file, all files will be 2MB"
	print "\t\ts1-command.py -z outfile.txt"
	print ""

class Sycamore1():

	
	def __init__(self, idVendor = 0x0403, idProduct = 0x8530):
		self.vendor = idVendor 
		self.product = idProduct
		self.fifo = FifoController(idVendor, idProduct)

	def write_bin_file(self, filename):
		binf = ""
		try:
			f = open(filename, "r")	
			binf = f.read()
			f.close()
		except IOError, err:
			print "Failed to open file: ", err

		
		#open up the flash device
		manager = serialflash.SerialFlashManager(self.vendor, self.product, 2)
		flash = manager.get_flash_device()

		#print out the device that was found
#		print "Found: ", str(flash)

#		flash.erase(0x00, len(flash))
		flash.bulk_erase()
		#write data to the output
		flash.write(0x00, binf)

		#verify that the data was read
		binf_rb = flash.read(0x00, len(binf))
		binf_str = binf_rb.tostring()
#		print "in file: " + binf
#		print "out file: " + binf_str

		del flash
		del manager


		if (binf_str != binf):
			return False
		
		return True

	def read_bin_file(self, filename):
		manager = serialflash.SerialFlashManager(self.vendor, self.product, 2)
		flash = manager.get_flash_device()

		#I don't know how long the data is so I'll have to read it all
		binf_rb = flash.read(0x00, len(flash))
		try:
			f = open(filename, "w")
			binf_rb.tofile(f)
			f.close()

		except IOError, err:
			print "Error: " + str(err)
			return False

		return True


	def program_FPGA(self):
		bbc = BitBangController(self.vendor, self.product, 2)	
		bbc.set_pins_to_input()
		#I don't know if this works
		bbc.set_program_to_output()
		bbc.program_high()
		time.sleep(.5)
		bbc.program_low()
		time.sleep(.2)
		bbc.program_high()
		bbc.set_pins_to_input()


	def reset_internal_state_machine(self):
		bbc = BitBangController(self.vendor, self, product, 2)
		bbc.set_soft_reset_to_output()
		bbc.soft_reset_high()
		time.sleep(.2)
		bbc.soft_reset_low()
		time.sleep(.2)
		bbc.soft_reset_high()


	def set_sync_fifo_mode(self):
		self.fifo.set_sync_fifo()

	def set_debug_mode(self):
		self.fifo.set_async_fifo()



def main(argv):
	print ("instantiating sycamore1")
	os.environ["S1_BASE"] = sys.path[0] + "/s1-pycontrol"
	sys.path.append(sys.path[0] + "/spi_flash")
	sys.path.append(sys.path[0] + "/bitbang")
	sys.path.append(sys.path[0] + "/fifo")



	if (len(argv) == 0):
		usage()
		sys.exit(1)

	
	s1 = Sycamore1()

	opts = None
	args = None
	try:
		opts, args = getopt.getopt(argv, "hvdrpcxz:", ["help", "verbose", "debug", "soft_reset", "program", "comm", "config", "read_back"])

	except getopt.GetoptError, err:
		print err
		usage()
		sys.exit(2)


	for opt, arg in opts:
		if opt in ("-h", "--help"):
			usage()
			sys.exit()

		elif opt in ("-v", "--verbose"):
			print "Verbose flag enabled"
			global _verbose
			_verbose = True

		elif opt in ("-d", "--debug"):
			print "Debug flag enabled"
			global _debug
			_debug = True

		elif opt in ("-r", "--soft_reset"):
			print "send a soft reset signal"
			s1.reset_internal_state_machine()
			sys.exit()

		elif opt in ("-p", "--program"):
			print "send a program signal to the FPGA"
			s1.program_FPGA()
			sys.exit()

		elif opt in ("-c", "--comm"):
			print "change the comm mode to high speed FIFO"
			s1.set_sync_fifo_mode()
			sys.exit()

		elif opt in ("-x", "--config"):
			print "change the comm mode to allow configuration"
			s1.set_debug_mode()
			sys.exit()

		elif opt in ("-z", "--read_back"):
			print "read back the bin file from the flash"
			s1.read_bin_file(arg)
			sys.exit()

	if (len(args) == 0):
		print ""
		print "no bin file found"
		usage()
		sys.exit(1)


	print "uploading FPGA config file...",
	if (not s1.write_bin_file(args[0])):
		print "Failed!"
		sys.exit(3)

	print "Success!"


	print "Sending program signal"
	s1.program_FPGA()

	print "Wait for 6 seconds before setting the FIFO"
	print "just in case this is the reason why the FPGA"
	print "isn't programming"
	time.sleep(6)

	print "Change to highspeed Synchronous FIFO mode"
	s1.set_sync_fifo_mode()

if __name__ == "__main__":
	main(sys.argv[1:])

