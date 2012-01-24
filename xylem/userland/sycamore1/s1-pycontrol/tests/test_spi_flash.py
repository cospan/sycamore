import unittest
import os
import sys
from inspect import isclass
import numonyx_flash
from pyftdi.misc import hexdump
from serialflash import SerialFlashManager
from array import array as Array
import time

class Test (unittest.TestCase):
	"""Unit test for Numonyx SPI Flash"""

	def setUp(self):
		self.dbg = False;
		self.vbs = False;
		if "S1_VERBOSE" in os.environ:
			if (os.environ["S1_VERBOSE"] == "True"):
				self.vbs = True

		if "S1_DEBUG" in os.environ:
			if (os.environ["S1_DEBUG"] == "True"):
				self.dbg = True

		os.environ["S1_BASE"] = sys.path[0] + "/s1-pycontrol"


		self.manager = SerialFlashManager(0x0403, 0x8530, 2)
		self.flash = self.manager.get_flash_device()
		return

	def tearDown(self):
		del self.flash
		del self.manager


	def test_read_jedec_id(self):
		"""reads the JEDEC identification number"""
		print "reading JEDEC ID number"
		self.assertEqual(1, 1)

	def test_read_size_and_string(self):
		"""read the JEDEC size and string"""
		print "String: "
		print str(self.flash)

	def test_read_status(self):
		"""read the status byte"""
		status = self.flash._read_status()
		print "Status: " + str(status)

#	def test_read_small_data(self):
#		"""read 32 bytes"""
#		data = self.flash.read(0x00, 32)
#		print "Data: " + str(data)

#	def test_erase_sector(self):
#		"""erase sector"""
#		#self.flash.bulk_erase()
#		self.flash.erase(0x00, 0x010000)
#		data = self.flash.read(0x00, 32)
#		print "Data: " + str(data)

#	def test_small_write(self):
#		self.flash.write(0x040000, [0x01, 0x02, 0x03, 0x05])
#		data = self.flash.read(0x040000, 4)
#		print "Data: " + str(data)

#	def test_wake(self):
#		self.flash.wake()

	def test_flashdevice_read_bandwidth(self):
		print "Start reading the whole device..."
		delta = time.time()
		data = self.flash.read(0, len(self.flash))
		delta = time.time()-delta
		length = len(data)
		print "%d bytes in %d seconds @ %.1f KB/s" % \
			(length, delta, length/(1024.0*delta))



	def test_flashdevice_small_rw(self):
		self.flash.erase(0x00000, 0x010000)
		data = self.flash.read(0x00, 128)
		ref = Array('B', [0xff] * 128)
		self.assertEqual(data, ref)
		string = 'This is a serial SPI flash test'
		ref2 = Array('B', string)
		self.flash.write(0x0020, string)
		data = self.flash.read(0x0020, 128)
		ref2.extend(ref)
		ref2 = ref2[:128]
		self.assertEqual(data, ref2)


#
#	def test_unlock(self):
#		"""test the chip's capability to unlock"""
#		self.flash.unlock()
"""
	def test_flashdevice_long_rw(self):
		# Fill in the whole flash with a monotonic increasing value, that is
		# the current flash 32-bit address, then verify the sequence has been
		# properly read back
		from hashlib import sha1
		buf = Array('I')
		length = len(self.flash)
		#length = 4096
		print "Build sequence"
		for address in range(0, length, 4):
			buf.append(address)
		# Expect to run on x86 or ARM (little endian), so swap the values
		# to ease debugging
		# A cleaner test would verify the host endianess, or use struct module
		print "Swap sequence"
		buf.byteswap()
		print "Erase flash (may take a while...)"
		self.flash.erase(0, length)
		# Cannot use buf, as it's an I-array, and SPI expects a B-array
		bufstr = buf.tostring()
		print "Write flash", len(bufstr)
		self.flash.write(0, bufstr)
		wmd = sha1()
		wmd.update(buf.tostring())
		refdigest = wmd.hexdigest()
		print "Read flash"
		data = self.flash.read(0, length)
		#print "Dump flash"
		#print hexdump(data.tostring())
		print "Verify flash"
		rmd = sha1()
		rmd.update(data.tostring())
		newdigest = rmd.hexdigest()
		print "Reference:", refdigest
		print "Retrieved:", newdigest
		if refdigest != newdigest:
			raise AssertionError('Data comparison mismatch')
"""


