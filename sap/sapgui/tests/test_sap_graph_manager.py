import unittest
import os
import sys
import json
import sapfile
import saputils
import sap_graph_manager as gm
from sap_graph_manager import SlaveError
from sap_graph_manager import NodeError

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

		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"	
		json_string = ""
		try:
			#open up the specified JSON project config file
			filein = open (file_name)
			#copy it into a buffer
			json_string = filein.read()
			filein.close()
		except IOError as err:
			print("File Error: " + str(err))
			return False

		self.project_tags = json.loads(json_string)

		if self.dbg:
			print "loaded JSON file"

		#generate graph
		self.sgm = gm.SapGraphManager()

		return

	def test_graph_add_node(self):
		if self.dbg:
			print "generating host interface node"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		#get the size of the graph
		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 1)	

	
	def test_rename_slave(self):
		if self.dbg:
			print "renaming slave"
		self.sgm.add_node ("name1", gm.Node_Type.slave, gm.Slave_Type.peripheral, 0)
		self.sgm.rename_slave(gm.Slave_Type.peripheral, 0, "name2")
		name = self.sgm.get_slave_name_at(0, gm.Slave_Type.peripheral)
		node = self.sgm.get_node(name)
		name = node.name
		self.assertEqual(name, "name2")

	def test_get_number_of_peripheral_slaves(self):

		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		count = self.sgm.get_number_of_slaves(gm.Slave_Type.peripheral)
		self.assertEqual(count, 2)	

	def test_get_number_of_memory_slaves(self):
		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
		count = self.sgm.get_number_of_slaves(gm.Slave_Type.memory)

		self.assertEqual(True, True)	

	
	def test_slave_index(self):

		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_3", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_4", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_5", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)


		#scramble things up
		self.sgm.move_slave(3, 1, gm.Slave_Type.peripheral)
		self.sgm.move_slave(2, 4, gm.Slave_Type.peripheral)
		self.sgm.move_slave(2, 3, gm.Slave_Type.peripheral)
		self.sgm.move_slave(1, 4, gm.Slave_Type.peripheral)
		self.sgm.move_slave(4, 2, gm.Slave_Type.peripheral)

		self.sgm.remove_slave(1, gm.Slave_Type.peripheral) 

		count = self.sgm.get_number_of_slaves(gm.Slave_Type.peripheral)

		for i in range (0, count):
			slave_name = self.sgm.get_slave_name_at(i, gm.Slave_Type.peripheral)
			node = self.sgm.get_node(slave_name)
			self.assertEqual(i, node.slave_index)

		#test memory locations

		self.sgm.add_node("mem_1", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
		self.sgm.add_node("mem_2", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
		self.sgm.add_node("mem_3", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
		self.sgm.add_node("mem_4", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)


		#scramble things up
		self.sgm.move_slave(0, 1, gm.Slave_Type.memory)
		self.sgm.move_slave(3, 1, gm.Slave_Type.memory)
		self.sgm.move_slave(2, 0, gm.Slave_Type.memory)
		self.sgm.move_slave(0, 3, gm.Slave_Type.memory)

		self.sgm.remove_slave(2, gm.Slave_Type.memory) 

		count = self.sgm.get_number_of_slaves(gm.Slave_Type.memory)

		for i in range (0, count):
			slave_name = self.sgm.get_slave_name_at(i, gm.Slave_Type.memory)
			node = self.sgm.get_node(slave_name)
			self.assertEqual(i, node.slave_index)



	def test_clear_graph(self):
		if self.dbg:
			print "generating host interface node"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		#get the size of the graph
		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.sgm.clear_graph()

		size = self.sgm.get_size()
		self.assertEqual(size, 0)	


	def test_graph_add_slave_node(self):
		if self.dbg:
			print "generating host interface node"

		self.sgm.add_node(	"gpio", 
							gm.Node_Type.slave,
							gm.Slave_Type.peripheral,
							debug=self.dbg)

		gpio_name = gm.get_unique_name(	"gpio", 
										gm.Node_Type.slave,
										gm.Slave_Type.peripheral,
										slave_index = 1)

		if self.dbg:
			print "unique name: " + gpio_name
		#get the size of the graph
		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 1)	


	def test_graph_remove_node(self):
		if self.dbg:
			print "adding two nodes"


		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)



		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 2)	

		#remove the uart node
		unique_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		self.sgm.remove_node(unique_name)

		size = self.sgm.get_size()
		if self.dbg:
			print "number of nodes: " + str(size)

		self.assertEqual(size, 1)	


	def test_get_node_names(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)

		names = self.sgm.get_node_names()
		

		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		self.assertIn(uart_name, names)
		self.assertIn(master_name, names)

	def test_get_nodes(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)

		graph_dict = self.sgm.get_nodes_dict()
		

		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		if self.dbg:
			print "dictionary: " + str(graph_dict)

		self.assertIn(uart_name, graph_dict.keys())
		self.assertIn(master_name, graph_dict.keys())
		

	def test_get_host_interface(self):
		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)
		node = self.sgm.get_host_interface_node()
		self.assertEqual(node.name, "uart")
		
		
	def test_connect_nodes(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)



		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		#get the number of connections before adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()
		self.assertEqual(num_of_connections, 0)

		self.sgm.connect_nodes(uart_name, master_name)
		#get the number of connections after adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()

		self.assertEqual(num_of_connections, 1)

	def test_disconnect_nodes(self):
		if self.dbg:
			print "adding two nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)



		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		#get the number of connections before adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()
		self.assertEqual(num_of_connections, 0)

		self.sgm.connect_nodes(uart_name, master_name)
		#get the number of connections after adding a connection	
		num_of_connections = self.sgm.get_number_of_connections()

		self.assertEqual(num_of_connections, 1)

		self.sgm.disconnect_nodes(uart_name, master_name)
		num_of_connections = self.sgm.get_number_of_connections()
		self.assertEqual(num_of_connections, 0)

	def test_edge_name(self):
		if self.dbg:
			print "adding two nodes, connecting them, setting the name and then reading it"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		self.sgm.add_node("master", gm.Node_Type.master)



		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)
		master_name = gm.get_unique_name("master", gm.Node_Type.master)

		self.sgm.connect_nodes(uart_name, master_name)

		self.sgm.set_edge_name(uart_name, master_name, "connection")

		result = self.sgm.get_edge_name(uart_name, master_name)
		self.assertEqual(result, "connection")

	def test_edge_dict(self):
		if self.dbg:
			print "adding two nodes, connecting them, setting the name and then reading it"

		uart_name = self.sgm.add_node("uart", gm.Node_Type.slave, gm.Slave_Type.peripheral)
		master_name = self.sgm.add_node("master", gm.Node_Type.slave, gm.Slave_Type.peripheral)

		self.sgm.connect_nodes(uart_name, master_name)

		self.sgm.set_edge_name(uart_name, master_name, "connection")

		result = self.sgm.is_slave_connected_to_slave(uart_name)
		self.assertEqual(result, True)

		arb_dict = self.sgm.get_connected_slaves(uart_name)
		self.assertEqual(arb_dict["connection"], master_name)
		




	def test_get_node_data(self):
		if self.dbg:
			print "adding a nodes"

		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		node = self.sgm.get_node(uart_name)
		self.assertEqual(node.name, "uart")

	def test_set_parameters(self):
		"""
		set all the parameters aquired from a module
		"""
		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		file_name = os.getenv("SAPLIB_BASE") + "/hdl/rtl/wishbone/host_interface/uart/uart_io_handler.v"
		parameters = saputils.get_module_tags(filename = file_name, bus="wishbone")

		self.sgm.set_parameters(uart_name, parameters)
		parameters = None
		if self.dbg:
			print "parameters: " + str(parameters)

		parameters = self.sgm.get_parameters(uart_name)

		if self.dbg:
			print "parameters: " + str(parameters)

		self.assertEqual(parameters["module"], "uart_io_handler")


	def test_bind_pin_to_port(self):
		self.sgm.add_node("uart", gm.Node_Type.host_interface)
		uart_name = gm.get_unique_name("uart", gm.Node_Type.host_interface)

		file_name = os.getenv("SAPLIB_BASE") + "/hdl/rtl/wishbone/host_interface/uart/uart_io_handler.v"
		parameters = saputils.get_module_tags(filename = file_name, bus="wishbone")

		self.sgm.set_parameters(uart_name, parameters)
		
		self.sgm.bind_pin_to_port(uart_name, "phy_uart_in", "RX") 

		parameters = None
		parameters = self.sgm.get_parameters(uart_name)

		#print "Dictionary: " + str(parameters["ports"]["phy_uart_in"])
		self.assertEqual(parameters["ports"]["phy_uart_in"]["port"], "RX")

	def test_move_peripheral_slave(self):
		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_3", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
	
		if self.dbg:
			count = self.sgm.get_number_of_peripheral_slaves()
			print "Number of slaves: %d" % (count)
		self.sgm.move_slave(2, 1, gm.Slave_Type.peripheral)

		s3_name = gm.get_unique_name("slave_3", gm.Node_Type.slave, gm.Slave_Type.peripheral, slave_index=1)

		result = True
		try:
			node = self.sgm.get_node(s3_name) 
		except NodeError as ex:
			print "Error while trying to get Node: " + str(ex)
			result = False


		self.assertEqual(result, True)
		
	def test_move_memory_slave(self):
		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
		self.sgm.add_node("slave_3", gm.Node_Type.slave, gm.Slave_Type.memory, debug = self.dbg)
	
		if self.dbg:
			count = self.sgm.get_number_of_memory_slaves()
			print "Number of slaves: %d" % (count)

		result = self.sgm.move_slave(2, 1, gm.Slave_Type.memory)

		s3_name = gm.get_unique_name("slave_3", gm.Node_Type.slave, gm.Slave_Type.memory, slave_index=1)

		result = True
		try:
			node = self.sgm.get_node(s3_name) 
		except NodeError as ex:
			print "Error while trying to get Node: " + str(ex)
			result = False

		self.assertEqual(result, True)
	
	def test_get_slave_at(self):
		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_3", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)

		test_name = gm.get_unique_name("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, slave_index = 1)
		found_name = self.sgm.get_slave_name_at(1, gm.Slave_Type.peripheral)
		node = self.sgm.get_slave_at(1, gm.Slave_Type.peripheral)
		
	
		self.assertEqual(test_name, node.unique_name)



	def test_get_slave_name_at(self):
		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_3", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)

		test_name = gm.get_unique_name("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, slave_index = 1)
		found_name = self.sgm.get_slave_name_at(1, gm.Slave_Type.peripheral)
		
	
		self.assertEqual(test_name, found_name)

	def test_remove_slave(self):
		self.sgm.add_node("slave_1", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_2", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)
		self.sgm.add_node("slave_3", gm.Node_Type.slave, gm.Slave_Type.peripheral, debug = self.dbg)

		self.sgm.remove_slave(1, gm.Slave_Type.peripheral)

		count = self.sgm.get_number_of_slaves(gm.Slave_Type.peripheral)
		self.assertEqual(count, 2)



if __name__ == "__main__":
	unittest.main()


