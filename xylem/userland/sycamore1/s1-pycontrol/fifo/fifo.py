"""
	sycamore1 FIFO controller
"""

from pyftdi.ftdi import Ftdi
from array import array as Array


class FifoController (object):


	SYNC_FIFO_INTERFACE		=	1
	SYNC_FIFO_INDEX			=	0

	
	def __init__(self, idVendor, idProduct):
		self.vendor = idVendor
		self.product = idProduct
		self.f = Ftdi()

	def set_sync_fifo(self, frequency=30.0E6, latency=2):
		"""Configure the interface for synchronous FIFO mode"""
		# Open an FTDI interface
#		self.f.open(self.vendor, self.product, self.SYNC_FIFO_INTERFACE, self.SYNC_FIFO_INDEX, None, None)
		self.f.open(self.vendor, self.product, 0)
	# Drain input buffer
		self.f.purge_buffers()

		# Reset

		# Enable MPSSE mode
		self.f.set_bitmode(0x00, Ftdi.BITMODE_SYNCFF)
		# Configure clock

		frequency = self.f._set_frequency(frequency)
		# Set latency timer
		self.f.set_latency_timer(latency)
		# Set chunk size
		self.f.write_data_set_chunksize(0x10000)
		self.f.read_data_set_chunksize(0x10000)
		
		self.f.set_flowctrl('hw')
		# Configure I/O
#		self.write_data(Array('B', [Ftdi.SET_BITS_LOW, 0x00, 0x00]))
		# Disable loopback
#		self.write_data(Array('B', [Ftdi.LOOPBACK_END]))
#		self.validate_mpsse()
		# Drain input buffer
		self.f.purge_buffers()
		# Return the actual frequency
		return frequency

	def set_async_fifo(self, frequency=6.0E6, latency=2):
		"""Configure the interface for synchronous FIFO mode"""
		# Open an FTDI interface
		self.f.open(self.vendor, self.product, self.SYNC_FIFO_INTERFACE, self.SYNC_FIFO_INDEX, None, None)
		# Set latency timer
		self.f.set_latency_timer(latency)
		# Set chunk size
		self.f.write_data_set_chunksize(512)
		self.f.read_data_set_chunksize(512)
		# Drain input buffer
		self.f.purge_buffers()
		# Enable MPSSE mode
		self.f.set_bitmode(0x00, Ftdi.BITMODE_BITBANG)
		# Configure clock
		frequency = self.f._set_frequency(frequency)
		# Configure I/O
#		self.write_data(Array('B', [Ftdi.SET_BITS_LOW, 0x00, 0x00]))
		# Disable loopback
#		self.write_data(Array('B', [Ftdi.LOOPBACK_END]))
#		self.validate_mpsse()
		# Drain input buffer
		self.f.purge_buffers()
		# Return the actual frequency
		return frequency



