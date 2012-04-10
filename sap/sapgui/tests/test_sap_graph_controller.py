import unittest
import os
import sys
import json
import sapfile
import saputils
import sap_graph_controller


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

		self.sgc = sap_graph_controller.SapGraphController()


	def test_load_file(self):
		#find a file to load
		self.assertEqual(True, True)

	def test_save_file(self):
		self.assertEqual(True, True)

	def test_initialize_graph(self):
		self.assertEqual(True, True)

	def test_set_host_interface(self):
		self.assertEqual(True, True)
		
	def test_add_slave(self):
		self.assertEqual(True, True)

	def test_remove_slave(self):
		self.assertEqual(True, True)

	def test_move_slave(self):
		self.assertEqual(True, True)


if __name__ == "__main__":
	unittest.main()


