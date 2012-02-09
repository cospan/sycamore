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

		s1 = self.dev.modem_status()
		print "S1: " + str(s1)

		response = self.dev.read_data(2)
		rsp = Array('B')
		rsp.fromstring(response)

		print "rsp: " + str(rsp)

		print "getting dtr..."
		response = self.dev.get_dsr()
		print "dsr: " + str(response)

		print "getting cts..."
		response = self.dev.get_cts()
		print "cts: " + str(response)

		print "getting cd..."
		response = self.dev.get_cd()
		print "cd: " + str(response)

		print "getting ring indicator..."
		response = self.dev.get_ri()
		print "ri: " + str(response)




		#		for a in rsp:
#			print "Data: %02X" % (a)

		response = self.dev.read_data(4)



		data = Array('B', "0000000000000000".decode('hex'))


		#print "writing"
		#for a in data:
	#		print "Data: %02X" % (a)

#		self.dev.write_data("0000000000000000")
		self.dev.write_data(data)
		self.dev.set_dtr_rts(True, True)
		s1 = self.dev.modem_status()
		print "S1: " + str(s1)


		print "reading"

		time.sleep(.1)

		response = self.dev.read_data(4)

		rsp = Array('B')
		rsp.fromstring(response)
		print "rsp: " + str(rsp)
#		for a in rsp:
#			print "Data: %02X" % (a)
		response = self.dev.read_data(4)


		rsp = Array('B')
		rsp.fromstring(response)
		print "rsp: " + str(rsp)
#		for a in rsp:
#			print "Data: %02X" % (a)
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
	




if __name__ == '__main__':
	print "starting..."
	syc = Sycamore(0x0403, 0x8530)
	print "ping..."
	syc.ping()
	print "done..."

