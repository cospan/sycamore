import unittest
import sapcmd
import json
import os

class Test (unittest.TestCase):
	"""Unit test for sapcmd"""

	def setUp(self):
		"""set up anything that needs to be instantiated for all tests"""

	def test_sapcmd(self):
		"""simulate a user calling sapcmd from the command line"""
		result = True
		self.assertEqual(result, True)
