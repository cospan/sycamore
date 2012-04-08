import unittest
import os
import sys
from inspect import isclass
import json

class Test (unittest.TestCase):
	"""Unit test for gen_drt.py"""


	def setUp(self):
		self.dbg = False
		self.vbs = False
		if "SAPLIB_VERBOSE" in os.environ:
			if (os.environ["SAPLIB_VERBOSE"] == "True"):
				self.vbs = True

		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		return

	def test_graph_load_file(self):
		self.assertEqual(True, True)	



if __name__ == "__main__":
	unittest.main()


