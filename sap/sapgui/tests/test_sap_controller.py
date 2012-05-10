import unittest
from gen_scripts.gen import Gen
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
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)

		home_dir = saputils.resolve_linux_path("~")
		self.sc.save_config_file(home_dir + "/test_out.json")
	
		self.sc.set_config_file_location(home_dir + "/test_out.json")
		self.sc.generate_project()
		
#XXX: How do I actually test out the project generation?
		self.assertEqual(True, True)

	def test_get_master_bind_dict(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		bind_dict = self.sc.get_master_bind_dict()

#		for key in bind_dict.keys():
#			print "key: " + key

		self.assertIn("phy_uart_in", bind_dict.keys())

		

	def test_project_location(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.set_project_location("p1_location")
		result = self.sc.get_project_location()

		self.assertEqual(result, "p1_location")

	def test_project_name(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.set_project_name("p1_name")
		result = self.sc.get_project_name()

		self.assertEqual(result, "p1_name")

	def test_vendor_tools(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)

		self.sc.set_vendor_tools("altera")
		result = self.sc.get_vendor_tools()
		self.assertEqual(result, "altera")

	def test_board_name(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)

		self.sc.set_board_name("bored of writing unit tests")
		result = self.sc.get_board_name()
		self.assertEqual(result, "bored of writing unit tests")

	def test_constraint_file_name(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)

		self.sc.set_constraint_file_name("bored of writing unit tests")
		result = self.sc.get_constraint_file_names()

		self.assertEqual(result[0], "bored of writing unit tests")

	def test_fpga_part_number(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)

		self.sc.set_fpga_part_number("bored of writing unit tests")
		result = self.sc.get_fpga_part_number()
		self.assertEqual(result, "bored of writing unit tests")

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
							file_name,
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

	def test_rename_slave(self):
		
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		filename = saputils.find_rtl_file_location("wb_console.v")

		self.sc.rename_slave(sc.Slave_Type.peripheral, 1, "name1")

		name = self.sc.get_slave_name(sc.Slave_Type.peripheral, 1)

	
		self.assertEqual(name, "name1")




	def test_add_slave(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

		self.sc.add_slave(	"mem1",
							None,
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
		filename = saputils.find_rtl_file_location("wb_console.v")

		self.sc.add_slave(	"test",
							filename,
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

		filename = saputils.find_rtl_file_location("wb_console.v")
		self.sc.add_slave(	"test1",
							filename,
							sc.Slave_Type.memory)

		self.sc.add_slave(	"test2",
							filename,
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
		filename = saputils.find_rtl_file_location("wb_console.v")

		self.sc.add_slave(	"test",
							filename,	
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
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/arb_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

#XXX: Test if the arbitrator can be removed
		p_count = self.sc.get_number_of_slaves(sc.Slave_Type.peripheral)
		m_count = self.sc.get_number_of_slaves(sc.Slave_Type.memory)

		arb_host = ""
		arb_slave = ""
		bus_name = ""

		back = self.dbg
#		self.dbg = True

		for i in range (0, p_count):
			name1 = self.sc.get_slave_name(sc.Slave_Type.peripheral, i)
			if self.dbg:
				print "testing %s for arbitration..." % (name1)
			if self.sc.is_active_arbitrator_host(sc.Slave_Type.peripheral, i):
				arb_host = name1
				a_dict = self.sc.get_arbitrator_dict(sc.Slave_Type.peripheral, i)
				for key in a_dict.keys():
					bus_name = key
					arb_slave = a_dict[key]

		for i in range (0, m_count):
			name1 = self.sc.get_slave_name(sc.Slave_Type.memory, i)
			if self.sc.is_active_arbitrator_host(sc.Slave_Type.memory, i):
				arb_host = name1
				a_dict = self.sc.get_arbitrator_dict(sc.Slave_Type.memory, i)
				for key in a_dict.keys():
					bus_name = key
					arb_slave = a_dict[key]

		arb_slave_name = self.sc.get_slave_name_by_unique(arb_slave)
		if self.dbg:
			print "%s is connected to %s through %s" % (arb_host, arb_slave_name, bus_name)


		self.dbg = False
		self.assertEqual(arb_host, "console")
		self.assertEqual(arb_slave_name, "mem1")
		self.assertEqual(bus_name, "fb")
	



	def test_get_connected_arbitration_slave(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/arb_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

#XXX: Test if the arbitrator can be removed
		p_count = self.sc.get_number_of_slaves(sc.Slave_Type.peripheral)
		m_count = self.sc.get_number_of_slaves(sc.Slave_Type.memory)

		arb_host = ""
		arb_slave = ""
		bus_name = ""
		host_name = ""

		back = self.dbg
#		self.dbg = True

		for i in range (0, p_count):

			name1 = self.sc.get_slave_name(sc.Slave_Type.peripheral, i)
			if self.dbg:
				print "testing %s for arbitration..." % (name1)
			if self.sc.is_active_arbitrator_host(sc.Slave_Type.peripheral, i):
				arb_host = name1
				host_name = self.sc.sgm.get_slave_at(sc.Slave_Type.peripheral, i).unique_name
				a_dict = self.sc.get_arbitrator_dict(sc.Slave_Type.peripheral, i)
				for key in a_dict.keys():
					bus_name = key
					arb_slave = a_dict[key]

		for i in range (0, m_count):
			name1 = self.sc.get_slave_name(sc.Slave_Type.memory, i)
			if self.sc.is_active_arbitrator_host(sc.Slave_Type.memory, i):
				host_name = self.sc.sgm.get_slave_at(sc.Slave_Type.peripheral, i).unique_name

				arb_host = name1
				a_dict = self.sc.get_arbitrator_dict(sc.Slave_Type.memory, i)
				for key in a_dict.keys():
					bus_name = key
					arb_slave = a_dict[key]

		arb_slave_name = self.sc.get_slave_name_by_unique(arb_slave)

		if self.dbg:
			print "%s is connected to %s through %s" % (arb_host, arb_slave_name, bus_name)


		slave_name = self.sc.get_connected_arbitrator_slave(host_name, bus_name)
		self.dbg = False
		self.assertEqual(slave_name, "mem1_0_0")

	def test_remove_arbitration_by_arbitrator(self):
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/arb_example.json"	
		self.sc.load_config_file(file_name)
		self.sc.initialize_graph()

#XXX: Test if the arbitrator can be removed
		p_count = self.sc.get_number_of_slaves(sc.Slave_Type.peripheral)
		m_count = self.sc.get_number_of_slaves(sc.Slave_Type.memory)

		arb_host = ""
		arb_slave = ""
		bus_name = ""
		host_name = ""

		back = self.dbg
#		self.dbg = True

		for i in range (0, p_count):

			name1 = self.sc.get_slave_name(sc.Slave_Type.peripheral, i)
			if self.dbg:
				print "testing %s for arbitration..." % (name1)
			if self.sc.is_active_arbitrator_host(sc.Slave_Type.peripheral, i):
				arb_host = name1
				host_name = self.sc.sgm.get_slave_at(sc.Slave_Type.peripheral, i).unique_name
				a_dict = self.sc.get_arbitrator_dict(sc.Slave_Type.peripheral, i)
				for key in a_dict.keys():
					bus_name = key
					arb_slave = a_dict[key]

		for i in range (0, m_count):
			name1 = self.sc.get_slave_name(sc.Slave_Type.memory, i)
			if self.sc.is_active_arbitrator_host(sc.Slave_Type.memory, i):
				host_name = self.sc.sgm.get_slave_at(sc.Slave_Type.peripheral, i).unique_name

				arb_host = name1
				a_dict = self.sc.get_arbitrator_dict(sc.Slave_Type.memory, i)
				for key in a_dict.keys():
					bus_name = key
					arb_slave = a_dict[key]

		arb_slave_name = self.sc.get_slave_name_by_unique(arb_slave)

		if self.dbg:
			print "%s is connected to %s through %s" % (arb_host, arb_slave_name, bus_name)


		slave_name = self.sc.get_connected_arbitrator_slave(host_name, bus_name)
		self.dbg = False
		self.assertEqual(slave_name, "mem1_0_0")

		self.sc.remove_arbitrator_by_arb_master(host_name, bus_name)

		slave_name = self.sc.get_connected_arbitrator_slave(host_name, bus_name)
		self.assertIsNone(slave_name)




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


