#! /usr/bin/python


import time
from pyftdi.ftdi import Ftdi
from array import array as Array


class Sycamore (object):
	
	SYNC_FIFO_INTERFACE = 0
	SYNC_FIFO_INDEX = 0

	def __init__(self, idVendor, idProduct):
		self.vendor = idVendor
		self.product = idProduct
		self.dev = Ftdi()
		self.open_dev()

	def __del__(self):
		self.dev.close()

	def ping(self):
		data = Array('B', '0000'.decode('hex'))
		print "writing"
		for a in data:
			print "Data: %02X" % (a)

		self.dev.write_data(data)
		print "reading"

		time.sleep(.1)
		response = self.dev.read_data(4)
		rsp = Array('B')
		rsp.fromstring(response)
		print "rsp: " + str(rsp)
#		for a in rsp:
#			print "Data: %02X" % (a)

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
		# Configure I/O
#		self.write_data(Array('B', [Ftdi.SET_BITS_LOW, 0x00, 0x00]))
		# Disable loopback
#		self.write_data(Array('B', [Ftdi.LOOPBACK_END]))
#		self.validate_mpsse()
		# Drain input buffer
		self.dev.purge_buffers()
	




if __name__ == '__main__':
	print "starting..."
	syc = Sycamore(0x0403, 0x8530)
	print "ping..."
	syc.ping()
	print "done..."

