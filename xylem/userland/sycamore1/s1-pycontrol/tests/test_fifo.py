"""
	Test out the bitbang controller

"""

import unittest
import os
import sys
from pyftdi.misc import hexdump
from array import array as Array
from fifo import FifoController
import time


class Test (unittest.TestCase):
	"""Unit test for FIFO controller"""

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


		self.fifo = FifoController(0x0403, 0x6010)
		return

	def tearDown(self):
		del self.fifo

	def test_set_mode(self):
		print "set sync mode"
		self.fifo.set_sync_fifo()

		print "set async mode"
		self.fifo.set_async_fifo()

