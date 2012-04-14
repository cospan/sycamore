import unittest
import os
import sys
import json
import sapfile
import saputils
import sap_controller as sc


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
		self.sc = sc.SapController()
		return



	def test_load_config_file(self):
		#find a file to load
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		board_name = self.sc.get_board_name()

		self.assertEqual(board_name, "xilinx-s3esk")

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
		#load a file
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		slave_count = self.sc.get_number_of_peripheral_slaves()

		self.assertEqual(slave_count, 2)

	def test_get_number_of_slaves(self):
		#load a file
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		self.sc.add_slave(	"mem1",
							sc.Slave_Type.memory)

		p_count = self.sc.get_number_of_slaves(sc.Slave_Type.peripheral)
		m_count = self.sc.get_number_of_slaves(sc.Slave_Type.memory)
		self.assertEqual(p_count, 2)
		self.assertEqual(m_count, 1)

	def test_set_host_interface(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()


		self.sc.set_host_interface("ft_host_interface")
		name = self.sc.get_host_interface_name()
		
		self.assertEqual(name, "ft_host_interface")

	def test_bus_type(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		bus_name = self.sc.get_bus_type()

		self.assertEqual(bus_name, "wishbone")

	def test_new_design(self):
		self.assertEqual(True, True)
		
	def test_add_slave(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		self.sc.add_slave(	"mem1",
							sc.Slave_Type.memory)

		p_count = self.sc.get_number_of_slaves(sc.Slave_Type.peripheral)
		m_count = self.sc.get_number_of_slaves(sc.Slave_Type.memory)
		self.assertEqual(p_count, 2)
		self.assertEqual(m_count, 1)

	def test_remove_slave(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		self.sc.remove_slave(sc.Slave_Type.peripheral, 1)
		p_count = self.sc.get_number_of_slaves(sc.Slave_Type.peripheral)
		self.assertEqual(p_count, 1)

	def test_move_slave_in_peripheral_bus(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		self.sc.add_slave(	"test",
							sc.Slave_Type.peripheral)

		name1 = self.sc.get_slave_name(sc.Slave_Type.peripheral, 2)
		self.sc.move_slave(	"test",
							sc.Slave_Type.peripheral,
							2,
							sc.Slave_Type.peripheral,
							1)

		name2 = self.sc.get_slave_name(sc.Slave_Type.peripheral, 1)
		self.assertEqual(name1, name2)

	def test_move_slave_in_memory_bus(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		self.sc.add_slave(	"test1",
							sc.Slave_Type.memory)

		self.sc.add_slave(	"test2",
							sc.Slave_Type.memory)

		m_count = self.sc.get_number_of_slaves(sc.Slave_Type.memory)

		name1 = self.sc.get_slave_name(sc.Slave_Type.memory, 0)
		self.sc.move_slave(	"test1",
							sc.Slave_Type.memory,
							0,
							sc.Slave_Type.memory,
							1)

		name2 = self.sc.get_slave_name(sc.Slave_Type.memory, 1)
		self.assertEqual(name1, name2)


	def test_move_slave_between_bus(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		self.sc.add_slave(	"test",
							sc.Slave_Type.peripheral)

		name1 = self.sc.get_slave_name(sc.Slave_Type.peripheral, 2)
		self.sc.move_slave(	"test",
							sc.Slave_Type.peripheral,
							2,
							sc.Slave_Type.memory,
							0)

		name2 = self.sc.get_slave_name(sc.Slave_Type.memory, 0)
		self.assertEqual(name1, name2)



	def test_arbitration(self):
#XXX: Test if the arbitrator is loaded correctly
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/arb_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

#XXX: Test if the arbitrator can be removed


#XXX: Test if the arbitrator can be added




	def test_save_config_file(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)

		home_dir = saputils.resolve_linux_path("~")
		self.sc.save_config_file(home_dir + "/test_out.json")
		try:
			filein = open(home_dir + "/test_out.json")
			json_string = filein.read()
			filein.close()
		except IOError as err:
			print ("File Error: " + str(err))
			self.assertEqual(True, False)

		self.assertEqual(True, True)


if __name__ == "__main__":
	unittest.main()


