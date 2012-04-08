#!/usr/bin/env python
import networkx as nx


class SapGraphManager:
	def __init__(self):
		"""
		initialize the controller
		"""
		self.graph = nx.Graph()
		self.graph_dict = {}


#Node stuff
	def add_node(self, name, node_type):
		print "add node"

	def get_node_names(self):
		"""
		get all names usually for the purpose of iterating through the graph
		"""
		return self.graph_dict.keys()

	def get_node(self, name):
		"""
		gets a node by the unique name
		"""

	def remove_node(self, name):
		"""
		removes a node using the unique name to find it
		"""

		#because the master an slave is always constant
		#then the only nodes that can be removed are the slaves

		#search for the connections between the interconnect and the slave
		#sever the connection
		#does the slave have a master for arbitration purposes?
			#if so sever that connection


	def set_node_location(self, name, x, y):
		print "sets node location"

	def set_node_color(self, name, r, g, b):
		print "sets node color"

	def set_node_size(self, name, size):
		"""
		GUI controller will set this size based on the size of the actual GUI
		"""
		print "sets node size"

	def connect_nodes(self, node1, node2):
		"""
		Connects two nodes together
		"""
	
	def disconnect_nodes(self, node1, node2):
		"""
		if the two nodes are connected disconnect them
		"""

#Control Stuff
	def set_parameters_from_core(self, parameters):
		"""
		Sets all the parameters from the core
		"""
	
	def initialize_ports_from_core(self, ports):
		"""
		Reads all the ports from the core
		"""

	def bind_port_to_pin(self, port, pin):
		"""
		binds the specific port to a pin
		"""

