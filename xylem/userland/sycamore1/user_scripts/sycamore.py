#! /usr/bin/python


import time
import sys
from pyftdi.ftdi import Ftdi
from array import array as Array
import getopt 


class Sycamore (object):
	
	SYNC_FIFO_INTERFACE = 0
	SYNC_FIFO_INDEX = 0

	read_timeout = 3

	def __init__(self, idVendor, idProduct):
		self.vendor = idVendor
		self.product = idProduct
		self.dev = Ftdi()
		self.open_dev()

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
		self.dev.write_data(data)
		response = self.dev.read_data(11)
		rsp = Array('B')
		rsp.fromstring(response)
		if not (0xDC in rsp):
			print "Didn't receive the Identification byte"
			return False

		index = rsp.index(0xDC)
		rsp = rsp[index:]
		if len(rsp) < 8:
			print "Recived data is too short"
			return False

		rsp = rsp[0:7]
		exp_array = Array('B', 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00)

		if exp_array == rsp:
			print "Got a good resposne"

		return True
			

	def write(self, data = Array('B')):
		length = str(len(data))
		data_out = Array('B', [0x01])	
		fmt_string = "%06X" % (length) 
		data_out.fromstring(fmt_string.decode['hex'])

		data_out.extend(data)

		self.dev.write_data(data_out)

		timeout = time.time() + self.read_timeout
		while time.time() < timeout:
			response = self.dev.read_data(1)
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

	def read(self, length, device_offset, address):
		read_data = Array('B')

		write_data = Array('B', [0x02])	
		fmt_string = "%06X" % (length) 
		write_data.fromstring(fmt_string.decode('hex'))

		offset_string = "%02X" % device_offset
		write_data.fromstring(offset_string.decode('hex'))

		addr_string = "%06X" % address
		write_data.fromstring(addr_string.decode('hex'))

		self.dev.write_data(write_data)

		timeout = time.time() + self.read_timeout
		while time.time() < timeout:
			response = self.dev.read_data(1)
			rsp = Array('B')
			rsp.fromstring(response)
			if rsp[0] == 0xDC:
				print "Got a response"	
				break

		if rsp[0] != 0xDC:
			print "Response not found"	
			return read_data

		#I need to watch out for the modem status bytes
		response = self.dev.read_data(8)
		rsp = Array('B')
		rsp.fromstring(response)

		#I need to watch out for hte modem status bytes
		read_string = self.dev.read_data(length * 4)
		read_data.fromstring(read_string.decode('hex'))
		return read_data
		

	def debug(self):
		data = Array('B')
		data.extend([0XCD, 0x01, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0xFF])
		print "to device: " + str(data)

		self.dev.write_data(data)


		self.dev.set_dtr_rts(True, True)
		s1 = self.dev.modem_status()
		print "S1: " + str(s1)


		print "reading"


		time.sleep(.2)
		response = self.dev.read_data(64)

		rsp = Array('B')
		rsp.fromstring(response)
		print "rsp: " + str(rsp) 
		for a in rsp:
			print "Data: %02X" % (a)
		s1 = self.dev.modem_status()
		print "S1: " + str(s1)




		data = Array('B')
		data.extend([0XCD, 0x01, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF])

		self.dev.write_data(data)
		response = self.dev.read_data(32)

		data = Array('B')
		data.extend([0XCD, 0x02, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF])
		print "to device: " + str(data)

		self.dev.write_data(data)


		self.dev.set_dtr_rts(True, True)
		s1 = self.dev.modem_status()
		print "S1: " + str(s1)


		print "reading"


#		response = self.dev.read_data(4)

#		rsp = Array('B')
#		rsp.fromstring(response)
#		print "rsp: " + str(rsp)
#		for a in rsp:
#			print "Data: %02X" % (a)
#			print "Data: %02X" % (a)
		time.sleep(.1)
		response = self.dev.read_data(16)


		rsp = Array('B')
		rsp.fromstring(response)
		print "rsp: " + str(rsp) 
		for a in rsp:
			print "Data: %02X" % (a)
		s1 = self.dev.modem_status()
		print "S1: " + str(s1)

	


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

#		self.dev.write_data_set_chunksize(64)
#		self.dev.read_data_set_chunksize(64)
		
#		self.dev.set_line_property(8, 1, 'N')
		self.dev.set_flowctrl('hw')

		# Configure I/O
		# Drain input buffer
		self.dev.purge_buffers()
	

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
		if (len(argv) == 0):
			print "ping..."
			syc.ping()
		else:
			opts = None
			opts, args = getopt.getopt(argv, "hd", ["help", "debug"])
			for opt, arg in opts:
				if opt in ("-h", "--help"):
					usage()
					sys.exit()
				elif opt in ("-d", "--debug"):
					print "Debug mode"
					syc.debug()


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



	
