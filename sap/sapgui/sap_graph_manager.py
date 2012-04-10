#!/usr/bin/env python
import networkx as nx
import sapfile

def enum(*sequential, **named):
	enums = dict(zip(sequential, range(len(sequential))), **named)
	return type('Enum', (), enums)

Node_Type = enum(	'host_interface', 
					'master', 
					'memory_interconnect', 
					'peripheral_interconnect', 
					'slave')

Slave_Type = enum(	'memory', 
					'peripheral')
		

def get_unique_name(name, node_type, slave_type = Slave_Type.peripheral, slave_index = 0):
	unique_name = ""
	if node_type == Node_Type.slave:
		unique_name = name + "_" + str(slave_type) + "_" + str(slave_index)
	else:
		unique_name = name + "_" + str(node_type)

	return unique_name



class SapNode:
	name = ""
	unique_name = ""
	node_type = Node_Type.slave
	slave_type = Slave_Type.peripheral
	slave_index = 0
	parameters={}
	constraints={}
	

class SapGraphManager:
	def __init__(self):
		"""
		initialize the controller
		"""
		self.graph = nx.Graph()

	def clear_graph(self):
		"""
		resets the graph
		"""
		self.graph = nx.Graph()

#Node stuff
	def add_node(self, name, node_type, slave_type=Slave_Type.peripheral, slave_index=0, debug=False):
		
		node = SapNode()
		node.name = name
		node.node_type = node_type 
		node.slave_type = slave_type
		node.slave_index = slave_index
		node.unique_name = get_unique_name(name, node_type, slave_type, slave_index)

		if debug:
			print "unique_name: " + node.unique_name

		self.graph.add_node(node.unique_name)
		self.graph.node[node.unique_name] = node

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

		self.graph.remove_node(name)


	def get_size(self):
		return len(self.graph)

	def get_node_names(self):
		"""
		get all names usually for the purpose of iterating through the graph
		"""
		return self.graph.nodes(False)

	def get_nodes_dict(self):
		graph_list = []
		graph_dict = {}
		graph_list = self.graph.nodes(True)
		for name, item in graph_list:
			graph_dict[name] = item

		return graph_dict

	def get_node(self, name):
		"""
		gets a node by the unique name
		"""
		g = self.get_nodes_dict()
		return g[name]

	def connect_nodes(self, node1, node2):
		"""
		Connects two nodes together
		"""
		self.graph.add_edge(node1, node2)
	
	def disconnect_nodes(self, node1, node2):
		"""
		if the two nodes are connected disconnect them
		"""
		self.graph.remove_edge(node1, node2)

	def get_number_of_connections(self):
		return self.graph.number_of_edges()

#Control Stuff
	def set_parameters(self, name, parameters, debug = False):
		"""
		Sets all the parameters from the core
		"""
		g = self.get_nodes_dict()
		g[name].parameters = parameters

		#need to re-organize the way that ports are put into
		#the parameters
		pdict = parameters["ports"]
		pdict_out = dict()
		direction_names = [
			"input",
			"output",
			"inout"]

		if debug:
			print "parameters: " + str(pdict)
		for d in direction_names:
			for n in pdict[d].keys():
				pdict_out[n] = {}
				pdict_out[n]["direction"] = d
				if "size" in pdict[d][n]:
					pdict_out[n]["size"] = pdict[d][n]["size"]
				if "max_val" in pdict[d][n]:
					pdict_out[n]["max_val"] = pdict[d][n]["max_val"]
				if "min_val" in pdict[d][n]:
					pdict_out[n]["min_val"] = pdict[d][n]["min_val"]
			

		g[name].parameters["ports"] = {}
		g[name].parameters["ports"] = pdict_out

	def get_parameters(self, name):
		g = self.get_nodes_dict()
		return g[name].parameters
		
	def bind_pin_to_port(self, name, port, pin, debug = False):
		"""
		binds the specific port to a pin
		"""
		g = self.get_nodes_dict()
		if debug:
			print "Dictionary: " + str(g[name].parameters["ports"][port])
		g[name].parameters["ports"][port]["port"] = pin



