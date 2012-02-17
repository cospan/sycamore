#! /usr/bin/python


import time
import sys
import string
from pyftdi.ftdi import Ftdi
from array import array as Array
import getopt 


class Sycamore (object):
	
	SYNC_FIFO_INTERFACE = 0
	SYNC_FIFO_INDEX = 0

	read_timeout = 3
	drt_string = ""
	drt_lines = []
	interrupts = 0
	interrupt_address = 0


	def __init__(self, idVendor, idProduct, dbg = False):
		self.vendor = idVendor
		self.product = idProduct
		self.dbg = dbg
		if self.dbg:
			print "Debug enabled"
		self.dev = Ftdi()
		self.open_dev()
		self.drt = Array('B')

	def __del__(self):
		self.dev.close()


	def set_read_timeout(self, read_timeout):
		self.read_timeout = read_timeout

	def get_read_timeout(self):
		return self.read_timeout

	def ping(self):
		data = Array('B')
		data.extend([0XCD, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]);
		print "Sending ping...",
		self.dev.purge_buffers()
		self.dev.write_data(data)
		rsp = Array('B')
		temp = Array('B')

		timeout = time.time() + self.read_timeout

		while time.time() < timeout:
			response = self.dev.read_data(3)
			print ".",
			rsp = Array('B')
			rsp.fromstring(response)
			temp.extend(rsp)
			if 0xDC in rsp:
				print "Got a response"	
				break

		if not 0xDC in rsp:
			print "Response not found"	
			print "temp: " + str(temp)
			return rsp

		index  = rsp.index(0xDC) + 1

		read_data = Array('B')
		read_data.extend(rsp[index:])

		num = 3 - index
		read_data.fromstring(self.dev.read_data(num))
		return True
			

	def write(self, dev_index, offset, data = Array('B')):
		length = len(data) / 4

		# ID 01 NN NN NN OO AA AA AA DD DD DD DD
			# ID = ID BYTE (0xCD)
			# 01 = Write Command
			# NN = Size of write (3 bytes)
			# OO = Offset of device
			# AA = Address (4 bytes)
			# DD = Data (4 bytes)


		#create an array with the identification byte (0xCD)
		#and code for write (0x01)
		data_out = Array('B', [0xCD, 0x01])	
		
		
		#append the length into the frist 32 bits
		fmt_string = "%06X" % (length) 
		data_out.fromstring(fmt_string.decode('hex'))
		offset_string = "%02X" % (dev_index + 1)
		data_out.fromstring(offset_string.decode('hex'))
		addr_string = "%06X" % offset
		data_out.fromstring(addr_string.decode('hex'))
		
		data_out.extend(data)

		if (self.dbg):
			print "data write string: " + str(data_out)



		#avoid the akward stale bug
		self.dev.purge_buffers()

		self.dev.write_data(data_out)

		timeout = time.time() + self.read_timeout
		while time.time() < timeout:
			response = self.dev.read_data(1)
			if len(response) > 0:
				rsp = Array('B')
				rsp.fromstring(response)
				if rsp[0] == 0xDC:
					print "Got a response"	
					break

		if rsp[0] != 0xDC:
			print "Response not found"	
			return False


		response = self.dev.read_data(8)
		rsp = Array('B')
		rsp.fromstring(response)

#		if rsp[0] == 0xFE:
		print "Response: " + str(rsp)
		return True

	def read(self, length, device_offset, address, drt = False):
		read_data = Array('B')

		write_data = Array('B', [0xCD, 0x02])	
		fmt_string = "%06X" % (length) 
		write_data.fromstring(fmt_string.decode('hex'))

		offset_string = ""
		if drt:
			offset_string = "%02X" % device_offset
		else:
			offset_string = "%02X" % (device_offset + 1)

		write_data.fromstring(offset_string.decode('hex'))

		addr_string = "%06X" % address
		write_data.fromstring(addr_string.decode('hex'))
		if (self.dbg):
			print "data read string: " + str(write_data)

		self.dev.purge_buffers()
		self.dev.write_data(write_data)

		timeout = time.time() + self.read_timeout
		while time.time() < timeout:
			response = self.dev.read_data(1)
			if len(response) > 0:
				rsp = Array('B')
				rsp.fromstring(response)
				if rsp[0] == 0xDC:
					print "Got a response"	
					break

		if rsp[0] != 0xDC:
			print "Response not found"	
			return read_data

		#I need to watch out for the modem status bytes
		response = self.dev.read_data(length * 4 + 8 )
		rsp = Array('B')
		rsp.fromstring(response)

		#I need to watch out for hte modem status bytes
		if self.dbg:
			print "response: " + str(rsp)
		#read_data.fromstring(read_string.decode('hex'))
		return rsp[8:]
		

	def debug(self):
		self.dev.set_dtr_rts(True, True)
		s1 = self.dev.modem_status()
		print "S1: " + str(s1)


		print "sending ping...", 
		data = Array('B')
		data.extend([0XCD, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
		self.dev.purge_buffers()
		self.dev.write_data(data)
		#time.sleep(.01)
#		response = self.dev.read_data(7)
		rsp = Array('B')
#		rsp.fromstring(response)
#		print "rsp: " + str(rsp) 
		temp = Array ('B')

		timeout = time.time() + self.read_timeout

		while time.time() < timeout:

			response = self.dev.read_data(3)
			rsp = Array('B')
			rsp.fromstring(response)
			temp.extend(rsp)
			if 0xDC in rsp:
				print "Got a response"	
				break

		if not 0xDC in rsp:
			print "Response not found"	
			print "temp: " + str(temp)
			return rsp

		index  = rsp.index(0xDC) + 1

		read_data = Array('B')
		read_data.extend(rsp[index:])

		num = 3 - index
		read_data.fromstring(self.dev.read_data(num))

		print "read data: " + str(read_data)
		
#
#		data = Array('B')
#		data.extend([0XCD, 0x02, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00])
#		print "to device: " + str(data)
#
#		self.dev.write_data(data)
#
#

#		print "reading"


#		time.sleep(.2)
#		response = self.dev.read_data(64)

#		rsp = Array('B')
#		rsp.fromstring(response)
#		print "rsp: " + str(rsp) 
#		for a in rsp:
#			print "Data: %02X" % (a)
#		s1 = self.dev.modem_status()
#		print "S1: " + str(s1)




#		data = Array('B')
#		data.extend([0XCD, 0x01, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF])
#
#		self.dev.write_data(data)
#		response = self.dev.read_data(32)
#
#		data = Array('B')
#		data.extend([0XCD, 0x02, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF])
#		print "to device: " + str(data)
#
#		self.dev.write_data(data)
#
#
#		self.dev.set_dtr_rts(True, True)
#		s1 = self.dev.modem_status()
#		print "S1: " + str(s1)


#		print "reading"


#		response = self.dev.read_data(4)

#		rsp = Array('B')
#		rsp.fromstring(response)
#		print "rsp: " + str(rsp)
#		for a in rsp:
#			print "Data: %02X" % (a)
#			print "Data: %02X" % (a)
#		time.sleep(.1)
#		response = self.dev.read_data(16)


#		rsp = Array('B')
#		rsp.fromstring(response)
#		print "rsp: " + str(rsp) 
#		for a in rsp:
#			print "Data: %02X" % (a)
#		s1 = self.dev.modem_status()
#		print "S1: " + str(s1)

	def wait_for_interrupts(self, wait_time = 1):
		timeout = time.time() + wait_time

		temp = Array ('B')
		while time.time() < timeout:

			response = self.dev.read_data(3)
			rsp = Array('B')
			rsp.fromstring(response)
			temp.extend(rsp)
			if 0xDC in rsp:
				print "Got a response"	
				break

		if not 0xDC in rsp:
			print "Response not found"	
			return False

		index  = rsp.index(0xDC) + 1

		read_data = Array('B')
		read_data.extend(rsp[index:])

		num = 3 - index
		read_data.fromstring(self.dev.read_data(num))
		self.interrupts = read_data[0] << 24 | read_data[1] << 16 | read_data[2] << 8 | read_data[3]
		
		if (self.dbg):
			print "interrupts: " + str(self.interrupts)
		return True
		
	def is_device_attached (self, device_id ):
		for dev_index in range (0, self.num_of_devices):
			dev_id = string.atoi(self.drt_lines[((dev_index + 1) * 8)], 16)
			if (self.dbg):
				print "dev_id: " + str(dev_id)
			if (dev_id == device_id):
				return True
		return False
	
	def get_device_index(self, device_id):
		for dev_index in range(0, self.num_of_devices):
			dev_id = string.atoi(self.drt_lines[((dev_index + 1) * 8)], 16)
			address_offset = string.atoi(self.drt_lines[((dev_index + 1) * 8) + 2], 16)
			if (device_id == device_id):
				return dev_index
		return -1

	def is_interrupt_for_slave(self, device_id = 0):
		device_id += 1
		if (2**device_id & self.interrupts):
			return True
		return False

	def get_address_from_dev_index(self, dev_index):	
		return string.atoi(self.drt_lines[((dev_index + 1) * 8) + 2], 16)
		
	def read_drt(self):
		data = Array('B')
		data = self.read(8, 0, 0, drt = True)
		self.drt.extend(data)
		self.drt_string = ""
		self.drt_lines = []
		print "drt: " + str(self.drt)
		self.num_of_devices = (self.drt[4] << 24 | self.drt[5] << 16 | self.drt[6] << 8 | self.drt[7])
		#print "number of devices: " + str(num_of_devices)
		len_to_read = self.num_of_devices * 8
		self.drt.extend(self.read(len_to_read, 0, 8, drt = True))
		print "drt: " + str(self.drt)
		display_len = 8 + self.num_of_devices * 8

		for i in range (0, display_len):
			self.drt_string += "%02X%02X%02X%02X\n"% (self.drt[i * 4], self.drt[(i * 4) + 1], self.drt[i * 4 + 2], self.drt[i * 4 + 3])

		print self.drt_string
		self.drt_lines = self.drt_string.splitlines()


	def open_dev(self):
		frequency = 30.0E6
		latency = 2
		self.dev.open(self.vendor, self.product, 0)
		# Drain input buffer
		self.dev.purge_buffers()

		# Reset

		# Enable MPSSE mode
		self.dev.set_bitmode(0x00, Ftdi.BITMODE_SYNCFF)
		# Configure clock

		frequency = self.dev._set_frequency(frequency)
		# Set latency timer
		self.dev.set_latency_timer(latency)
		# Set chunk size
		self.dev.write_data_set_chunksize(0x10000)
		self.dev.read_data_set_chunksize(0x10000)

		self.dev.set_flowctrl('hw')
		self.dev.purge_buffers()
	


def sycamore_unit_test(syc = None):
	print "unit test"
	print "Found " + str(syc.num_of_devices) + " slave(s)"
	print "Searching for standard devices..."
	for dev_index in range (0, (syc.num_of_devices)):
		device_id = string.atoi(syc.drt_lines[((dev_index + 1) * 8)], 16)
		flags = string.atoi(syc.drt_lines[((dev_index + 1) * 8) + 1], 16)
		address_offset = string.atoi(syc.drt_lines[((dev_index + 1) * 8) + 2], 16)
		num_of_registers = string.atoi(syc.drt_lines[((dev_index + 1) * 8) + 3], 16)
		data_list = list()
		if (device_id == 1):
			print "found gpio"
			print "enable all GPIO's"
			syc.write(dev_index, 1, Array('B', [0xFF, 0xFF, 0xFF, 0xFF]))
			print "flash all LED's once"
			#clear
			syc.write(dev_index, 0, Array('B', [0x00, 0x00, 0x00, 0x00]))
			syc.write(dev_index, 0, Array('B', [0xFF, 0xFF, 0xFF, 0xFF]))
			time.sleep(1)
			syc.write(dev_index, 0, Array('B', [0x00, 0x00, 0x00, 0x00]))
			time.sleep(.1)
	
			print "read buttons in 1 second..."
			time.sleep(1)
			grd = syc.read(1, dev_index, 0)
			print "gpios: " + str(grd)
			print "low bits: " + str(grd[3])
			gpio_read = grd[0] << 24 | grd[1] << 16 | grd[2] << 8 | grd[3] 
			print "gpio read: " + hex(gpio_read)

			print "testing interrupts, setting interrupts up for postivie edge detect"
			#positive edge detect
			syc.write(dev_index, 4, Array('B', [0xFF, 0xFF, 0xFF, 0xFF]))
			#enable all interrupts
			syc.write(dev_index, 3, Array('B', [0xFF, 0xFF, 0xFF, 0xFF]))

#				print "testing burst write: "
#				syc.write(dev_index, 0, [1, 2, 3, 4, 5])

				
#				print "testing burst read, results should be 1, 2: "
#				gpio_read = syc.read(dev_index, 0, 5)
#				for v in gpio_read:
#					print "gpio: " + str(v)

			print "testing interrupts, waiting for 5 seconds..."
				
			if (syc.wait_for_interrupts(wait_time = 5)):
				#print "detected interrupts!"
				#print "interrupts: " + str(syc.interrupts)
				#print "device index: " + str(dev_index)
				#print "blah: " + str(2**(dev_index + 1))
				if (syc.is_interrupt_for_slave(dev_index)):
					print "interrupt for GPIO!"
					grd = syc.read(1, dev_index, 0)
					gpio_read = grd[0] << 24 | grd[1] << 16 | grd[2] << 8 | grd[3] 
					print "gpio read: " + hex(gpio_read)


def usage():
	"""prints out a helpful message to the user"""
	print ""
	print "usage: sycamore.py [options]"
	print ""
	print "-h\t--help\t\t\t: displays this help"
	print "-d\t--debug\t\t\t: runs the debug analysis"
	print ""
	

if __name__ == '__main__':
	print "starting..."
	argv = sys.argv[1:]

	try:
		syc = Sycamore(0x0403, 0x8530)
		if (len(argv) > 0):
			opts = None
			opts, args = getopt.getopt(argv, "hd", ["help", "debug"])
			for opt, arg in opts:
				if opt in ("-h", "--help"):
					usage()
					sys.exit()
				elif opt in ("-d", "--debug"):
					print "Debug mode"
					syc = Sycamore(0x0403, 0x8530, dbg=True)
					syc.debug()

		if (syc.ping()):
			print "Ping responded successfully"
			print "Retrieving DRT"
			syc.read_drt()
			if (syc.dbg):
				print "testing if device is attached..." + str(syc.is_device_attached(1))
				print "testing get_device_index..." + str(syc.get_device_index(1) == 0)
				print "testing get_address_from_index..." + str(syc.get_address_from_dev_index(0) == 0x01000000)

			sycamore_unit_test(syc)

			


	except IOError, ex:
		print "PyFtdi IOError: " + str(ex)
	except AttributeError, ex:
		print "PyFtdi AttributeError: " + str(ex)
	except getopt.GetoptError, err:
		print (err)
		usage()
"""
	except ex:
		print "PyFtdi Unknown Error: " + str(ex)

"""

