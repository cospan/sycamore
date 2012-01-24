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
	print "filename: mcs file to program the FPGA"
	print ""
	print "options:"
	print "-h\t--help\t\t\t: displays this help"
	print "-v\t--verbose\t\t: print out lots of info"
	print "-d\t--debug\t\t\t: enables debug settings"
	print "-r\t--soft_reset\t\t: resets the internal state machine"
	print "-p\t--program\t\t: resets the FPGA an initiate a configuration"
	print "-z\t--read_back\t\t: readback the .mcs image to the filename given"
	print ""
	print "Examples:"
	print "\tupdload the mcs file and program the FPGA"
	print "\t\ts1-command.py bitfile.mcs"
	print ""
	print "\treset the FPGA and program without loading a new mcs file"
	print "\t\ts1-command.py -p"
	print ""
	print "\treset the internal state machine of the FPGA"
	print "\t\ts1-command.py -r"
	print ""
	print "\tread back the .mcs file, all files will be 512KB"
	print "\t\ts1-command.py -z outfile.txt"
	print ""

class Sycamore1():

	
	def __init__(self, idVendor = 0x0403, idProduct = 0x8530):
		self.vendor = idVendor 
		self.product = idProduct
		self.fifo = FifoController(idVendor, idProduct)

	def write_mcs_file(self, filename):
		mcs = ""
		try:
			f = open(filename, "r")	
			mcs = f.read()
			f.close()
		except IOError, err:
			print "Failed to open file: ", err

		
		#open up the flash device
		manager = serialflash.SerialFlashManager(self.vendor, self.product, 2)
		flash = manager.get_flash_device()

		#print out the device that was found
#		print "Found: ", str(flash)

		flash.erase(0x00, len(flash))
		#write data to the output
		flash.write(0x00, mcs)

		#verify that the data was read
		mcs_rb = flash.read(0x00, len(mcs))
		mcs_str = mcs_rb.tostring()
#		print "in file: " + mcs
#		print "out file: " + mcs_str

		del flash
		del manager


		if (mcs_str != mcs):
			return False
		
		return True

	def read_mcs_file(self, filename):
		manager = serialflash.SerialFlashManager(self.vendor, self.product, 2)
		flash = manager.get_flash_device()

		#I don't know how long the data is so I'll have to read it all
		mcs_rb = flash.read(0x00, len(flash))
		try:
			f = open(filename, "w")
			mcs_rb.tofile(f)
			f.close()

		except IOError, err:
			print "Error: " + str(err)
			return False

		return True


	def program_FPGA(self):
		bbc = BitBangController(self.vendor, self.product, 2)	
		bbc.set_pins_to_output()
		bbc.program_high()
		time.sleep(.2)
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
		opts, args = getopt.getopt(argv, "hvdrpz:", ["help", "verbose", "debug", "soft_reset", "program", "read_back"])

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

		elif opt in ("-z", "--read_back"):
			print "read back the mcs file from the flash"
			s1.read_mcs_file(arg)
			sys.exit()

	if (len(args) == 0):
		print ""
		print "no mcs file found"
		usage()
		sys.exit(1)


	print "uploading FPGA config file...",
	if (not s1.write_mcs_file(args[0])):
		print "Failed!"
		sys.exit(3)

	print "Success!"


	print "Sending program signal"
	s1.program_FPGA()


	print "Change to highspeed Synchronous FIFO mode"
	s1.set_sync_fifo_mode()

if __name__ == "__main__":
	main(sys.argv[1:])

