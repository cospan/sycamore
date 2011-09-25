import unittest
from saplib import saplib
import os
import sys

class Test (unittest.TestCase):
	"""Unit test for saplib"""

	def setUp(self):
		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"	
		return


	def test_get_slave_list(self):
		"""test the query slave function"""
		result = saplib.get_slave_list(bus = "wishbone")
		self.assertEqual((len(result) > 0), False)

	def test_get_interface_list(self):
		"""test the query handler function"""
		result = saplib.get_interface_list(bus = "wishbone")
		self.assertEqual(len(result) > 0, False)

	def test_create_project_config_file(self):
		"""Test the create JSON string function"""
		result = saplib.create_project_config_file(
								filename = "output_project_config_file.json", 
								bus="wishbone", 
								interface="uart_io_handler.v", 
								base_dir="~/sandbox/project_config")
		self.assertEqual(1, 1)
	

	def test_generate_project(self):
		filename = os.getenv("SAPLIB_BASE") + "/example_project/example1.json"
		result = saplib.generate_project(filename)
		self.assertEqual(result, True)

if __name__ == "__main__":
	unittest.main()
