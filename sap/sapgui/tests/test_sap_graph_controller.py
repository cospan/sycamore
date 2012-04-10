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

		#every test needs the SGC 
		self.sgc = sap_graph_controller.SapGraphController()
		return



	def test_load_config_file(self):
		#find a file to load
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sgc.load_config_file(file_name)
		self.assertEqual(True, True)

	def test_save_config_file(self):
		self.assertEqual(True, True)

	def test_generate_project(self):
		self.assertEqual(True, True)

	def test_project_location(self):
		self.assertEqual(True, True)

	def test_project_name(self):
		self.assertEqual(True, True)

	def test_vendor_tools(self):
		self.assertEqual(True, True)

	def test_board_name(self):
		self.assertEqual(True, True)

	def test_constraint_file_name(self):
		self.assertEqual(True, True)

	def test_fpga_part_number(self):
		self.assertEqual(True, True)

	def test_initialize_graph(self):
		self.assertEqual(True, True)

	def test_set_host_interface(self):
		self.assertEqual(True, True)

	def test_bus_type(self):
		self.assertEqual(True, True)

	def test_new_design(self):
		self.assertEqual(True, True)
		
	def test_add_slave(self):
		self.assertEqual(True, True)

	def test_remove_slave(self):
		self.assertEqual(True, True)

	def test_move_slave(self):
		self.assertEqual(True, True)

	def test_arbitration(self):
		self.assertEqual(True, True)


if __name__ == "__main__":
	unittest.main()


