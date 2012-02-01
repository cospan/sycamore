"""
	Test out the bitbang controller

"""

import unittest
import os
import sys
from pyftdi.misc import hexdump
from array import array as Array
from bitbang.bitbang import BitBangController
import time


class Test (unittest.TestCase):
	"""Unit test for Bitbang controller"""

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


		self.bbc = BitBangController(0x0403, 0x8530, 2)
		return

	def tearDown(self):
		del self.bbc

	def test_individual_direction(self):
		print ""
		print "reading inputs"
		#self.bbc.set_pins_to_output()
		prg = self.bbc.read_program_pin()
		srs = self.bbc.read_soft_reset_pin()

		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""

		print "setting reset pin only to output"
		self.bbc.set_soft_reset_to_output()

		print "setting program pin low (shouldn't go low), reset high"
		self.bbc.program_low()
		prg = self.bbc.read_program_pin()
		self.bbc.soft_reset_high()
		srs = self.bbc.read_soft_reset_pin()
		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""
		#self.assertEqual(prg, True)
		#self.assertEqual(srs, True)

		print "setting program pin high, reset low"
		self.bbc.program_high()
		prg = self.bbc.read_program_pin()
		self.bbc.soft_reset_low()
		srs = self.bbc.read_soft_reset_pin()
		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""
		self.assertEqual(prg, True)
		self.assertEqual(srs, False)

		print "setting program pin only to ouput"
		self.bbc.set_program_to_output()

		self.bbc.program_low()
		prg = self.bbc.read_program_pin()
		self.bbc.soft_reset_high()
		srs = self.bbc.read_soft_reset_pin()
		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""
		self.assertEqual(prg, False)
		self.assertEqual(srs, True)

		print "setting program pin high, reset low"
		self.bbc.program_high()
		prg = self.bbc.read_program_pin()
		self.bbc.soft_reset_low()
		srs = self.bbc.read_soft_reset_pin()
		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""
#		self.assertEqual(prg, True)
#		self.assertEqual(srs, True)





	def test_individual_pins(self):
		print ""
		print "reading input"
		prg = self.bbc.read_program_pin()
		srs = self.bbc.read_soft_reset_pin()

		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""


		print "setting pins to output"
		self.bbc.set_pins_to_output()

		print "setting program pin low, reset high"
		self.bbc.program_low()
		prg = self.bbc.read_program_pin()
		self.bbc.soft_reset_high()
		srs = self.bbc.read_soft_reset_pin()
		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""
		#self.assertEqual(prg, False)
		#self.assertEqual(srs, True)

		print "setting program pin high, reset low"
		self.bbc.program_high()
		prg = self.bbc.read_program_pin()
		self.bbc.soft_reset_low()
		srs = self.bbc.read_soft_reset_pin()
		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""
		#self.assertEqual(prg, True)
		#self.assertEqual(srs, False)

#		self.bbc.set_program_pin_to_input()
		print "Setting pins to input:"
		self.bbc.set_pins_to_input()
		prg = self.bbc.read_program_pin()
		srs = self.bbc.read_soft_reset_pin()

		print "Program Pin: " + str(prg)
		print "Reset Pin: " + str(srs)
		print "Program pins: " + hex(self.bbc.read_pins())
		print ""



#
#	def test_set_soft_reset_to_output(self):
#
#		self.bbc.set_soft_reset_to_output()
#		time.sleep(.01)
#		srs = self.bbc.read_soft_reset_pin()
#
#		print "Soft Reset Pin: " + str(srs)
#	
#		self.bbc.set_soft_reset_to_input()
#		srs = self.bbc.read_soft_reset_pin()
#
#		print "Soft Reset Pin: " + str(srs)
	
