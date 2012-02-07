"""ft245_fifo - A synchronous fifo controller on top of pyftdi


"""

import os
from pyftdi.ftdi import Ftdi
import array import array as Array

class FT245SyncFIFOError(Exception):
	"""FT245 Sync FIFO Error"""

class FT245SyncFIFO (object):
	"""ft245 synchronous FIFO"""

	"""
		this requires that the EEPROM already set the two channels
		to an asynchronous FT245 FIFOs
	"""

    def __init__(self, vendor, product, interface = 0, index = 0):
		self.fifo = Ftdi()
		self.vendor = vendor
		self.product = product
		self.interface = interface
		self.index = index
		self.latency = 2
		self.chunksize = 0x10000 #largest size is 64KiB
		self.frequency = 30.0E6
		self.fifo = None

	def open(self):
		self.fifo.open(self.vendor, self.product, self.interface, self.index)
		#enable synchronous FIFO mode
		self.fifo.set_bitmode(0x00, Ftdi.BITMODE_SYNCFF)
#XXX: do I need to set the frequency?
		#set the frequency
		self.fifo.set_frequency(self.frequency)
		#set the latency timeout to be as low as possible
		self.fifo.set_latency_timer(self.latency)

		#set the in/out chunksize
		self.fifo.write_data_set_chunksize(self.chunksize)
		self.fifo.read_data_set_chunksize(self.chunksize)

		#set hardware flow
#XXX: this doesn't sound necessary but was in the sample code
		self.fifo.set_flowctrl('hw')
		#clear out the buffers
		self.fifo.purge_buffers()

	def read(self, size):
		return 0

	def write (self, data):
#XXX: I think this works correctly
		self.fifo.write_data(data)
		return 0

	def status (self):
		#get the queue status
		return 0

	def available (self):
		return 0
