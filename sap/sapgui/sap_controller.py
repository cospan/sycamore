#!/usr/bin/env python
import os
import sys
import json
from saplib import saplib
import sapfile
import saputils
import sap_graph_manager as gm
from sap_graph_manager import Slave_Type
from sap_graph_manager import Node_Type
from sap_graph_manager import get_unique_name
from saperror import ModuleNotFound
from saperror import SlaveError

def enum(*sequential, **named):
	enums = dict(zip(sequential, range(len(sequential))), **named)
	return type('Enum', (), enums)


class SapController:
	def __init__(self):
		self.new_design()
		self.filename = ""
		return


	def load_config_file(self, file_name, debug=False):
		"""
		Loads a sycamore configuration file into memory
		"""
		json_string = ""
		try:
			#open up the specified JSON project config file
			filein = open (file_name)
			#copy it into a buffer
			json_string = filein.read()
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)
			return False

		self.project_tags = json.loads(json_string)
		self.filename = file_name
		return True

	def set_config_file_location(self, file_name):
		self.filename = file_name

	def initialize_graph(self, debug=False):
		"""
		Initializes the graph and project tags
		"""

		#clear any previous data
		self.sgm.clear_graph()


		#set the bus type
		if self.project_tags["TEMPLATE"] == "wishbone_template.json":
			self.set_bus_type("wishbone")
		elif self.project_tags["TEMPLATE"] == "axie_template.json":
			self.set_bus_type("axie")
			
			
		#add the nodes that are always present
		self.sgm.add_node(	"Host Interface", 
							Node_Type.host_interface)
		self.sgm.add_node(	"Master", 
							Node_Type.master)
		self.sgm.add_node(	"Memory", 
							Node_Type.memory_interconnect)
		self.sgm.add_node(	"Peripherals", 
							Node_Type.peripheral_interconnect)

		self.add_slave(		"DRT",
							None,
							Slave_Type.peripheral,
							slave_index = 0)

		#get all the unique names for accessing nodes
		hi_name = get_unique_name(	"Host Interface", 
									Node_Type.host_interface) 
		m_name = get_unique_name(	"Master",
									Node_Type.master)
		mi_name = get_unique_name(	"Memory",
									Node_Type.memory_interconnect)
		pi_name = get_unique_name(	"Peripherals",
									Node_Type.peripheral_interconnect)
		drt_name = get_unique_name(	"DRT",
									Node_Type.slave,
									Slave_Type.peripheral,
									slave_index = 0)

		#attach all the appropriate nodes
		self.sgm.connect_nodes(hi_name, m_name)
		self.sgm.connect_nodes(m_name, mi_name)
		self.sgm.connect_nodes(m_name, pi_name)
		self.sgm.connect_nodes(pi_name, drt_name)


		#get module data for the DRT
		try:
			file_name = saputils.find_rtl_file_location("device_rom_table.v")
		except ModuleNotFound as ex:
			if debug:
				print "Invalid Module Name: %s" % (host_interface_name)
		
		parameters = saputils.get_module_tags(	filename = file_name, bus=self.get_bus_type())
		self.sgm.set_parameters(drt_name, parameters)


		#attempt to load data from the tags
		sp_count = self.sgm.get_number_of_peripheral_slaves()
		if debug:
			print "loading %d peripheral slaves" % sp_count

		if "SLAVES" in self.project_tags:
			for slave_name in self.project_tags["SLAVES"].keys():

				file_name = self.project_tags["SLAVES"][slave_name]["filename"]
				if "device_rom_table" in file_name:
					file_name = None

				if file_name is not None:
					file_name = saputils.find_rtl_file_location(file_name)


				
				self.add_slave(	slave_name,
								file_name,
								Slave_Type.peripheral)


		#load all the memory slaves
		sm_count = self.sgm.get_number_of_memory_slaves()
		if debug:
			print "loading %d peripheral slaves" % sm_count

		if "MEMORY" in self.project_tags:
			for slave_name in self.project_tags["MEMORY"].keys():

				file_name = self.project_tags["MEMORY"][slave_name]["filename"]
				file_name = saputils.find_rtl_file_location(file_name)
				self.add_slave(		slave_name,
									file_name,
									Slave_Type.memory,
									slave_index = -1)

		#check if there is a host insterface defined
		if "INTERFACE" in self.project_tags:
			file_name = saputils.find_rtl_file_location(self.project_tags["INTERFACE"]["filename"])
			parameters = saputils.get_module_tags(	filename = file_name, bus=self.get_bus_type())
			self.sgm.set_parameters(hi_name, parameters)



#XXX: Go through all the slaves and connect any arbitrators
		if "SLAVES" in self.project_tags:
			for host_name in self.project_tags["SLAVES"].keys():
				if "BUS" in self.project_tags["SLAVES"][host_name].keys():
					for arb_name in self.project_tags["SLAVES"][host_name]["BUS"].keys():
						#there is an arbitrator here
						slave_name = self.project_tags["SLAVES"][host_name]["BUS"][arb_name]
						if debug:
							print "arbitrator: %s attaches to %s through bus: %s" % (host_name, slave_name, arb_name)

						h_name = ""
						h_index = -1
						h_type = Slave_Type.peripheral
						s_name = ""
						s_index = -1
						s_type = Slave_Type.peripheral


						#now to attach the arbitrator
						p_count = self.get_number_of_slaves(Slave_Type.peripheral) 
						m_count = self.get_number_of_slaves(Slave_Type.memory)

						#find the host and slave nodes
						for i in range (0, p_count):
							self.sgm.get_slave_name_at(i, Slave_Type.peripheral)	
							sn = self.sgm.get_slave_name_at(i, Slave_Type.peripheral) 
							slave = self.sgm.get_node(sn)

							if slave.name == host_name:
								h_name = slave.unique_name
								h_index = i
								h_type = Slave_Type.peripheral

							if slave.name == slave_name:
								s_name = slave.unique_name
								s_index = i
								s_type = Slave_Type.peripheral
								

						for i in range (0, m_count):
							self.sgm.get_slave_name_at(i, Slave_Type.memory)	
							sn = self.sgm.get_slave_name_at(i, Slave_Type.memory) 
							slave = self.sgm.get_node(sn)

							if slave.name == host_name:
								h_name = slave.unique_name
								h_index = i
								h_type = Slave_Type.memory

							if slave.name == slave_name:
								s_name = slave.unique_name
								s_index = i
								s_type = Slave_Type.memory

						#now I have all the materialst to attach the arbitrator
						self.add_arbitrator(	h_type,
												h_index,
												arb_name,
												s_type,
												s_index)
	
		return True

	def get_number_of_slaves(self, slave_type):
		if slave_type is None:
			raise SlaveError("slave type was not specified")

		if slave_type == Slave_Type.peripheral:
			return self.get_number_of_peripheral_slaves()

		return self.get_number_of_memory_slaves()


	def get_number_of_memory_slaves(self):
		return self.sgm.get_number_of_memory_slaves()

	def get_number_of_peripheral_slaves(self):
		return self.sgm.get_number_of_peripheral_slaves()

	def save_config_file(self, file_name):
		"""
		Saves a module stored in memory to a file
		"""

		#if there are no slaves on the memory interconnect
		#then don't generate the structure in the JSON file for it
		json_string = json.dumps(self.project_tags, sort_keys=True, indent = 4)
		try:
			file_out = open(file_name, 'w')
			file_out.write(json_string)
			file_out.close()
		except IOError as err:
			print "File Error: " + str(err)
			return False

		return True

	def set_project_location(self, location):
		"""
		sets the location of the project to output
		"""
		self.project_tags["BASE_DIR"] = location
	
	def get_project_location(self):
		return self.project_tags["BASE_DIR"]
		

	def set_project_name(self, name):
		"""
		sets the name of the output project
		"""
		self.project_tags["PROJECT_NAME"] = name

	def get_project_name(self):
		return self.project_tags["PROJECT_NAME"]

	def set_vendor_tools(self, vendor_tool):
		"""
		sets the vendor build tool, currently only
		Xilinx is supported
		"""
		self.project_tags["BUILD_TOOL"] = vendor_tool

	def get_vendor_tools(self):
		return self.project_tags["BUILD_TOOL"]

	def set_board_name(self, board_name):
		"""
		sets the name of the board to use
		"""
		if "CONSTRAINTS" not in self.project_tags.keys():
			self.project_tags["CONSTRAINTS"] = {}

		if "board" not in self.project_tags["CONSTRAINTS"].keys():
			self.project_tags["CONSTRAINTS"]["board"] = ""
				
		self.project_tags["CONSTRAINTS"]["board"] = board_name
	
	def get_board_name(self):
		if "CONSTRAINTS" in self.project_tags.keys():
			if "board" in self.project_tags["CONSTRAINTS"].keys():
				return self.project_tags["CONSTRAINTS"]["board"]

		return "undefined"
	
	def set_constraint_file_name(self, constraint_file_name):
		"""
		sets the constraint file name
		"""
		if "CONSTRAINTS" not in self.project_tags.keys():
			self.project_tags["CONSTRAINTS"] = {}

		if "constraint_files" not in self.project_tags["CONSTRAINTS"].keys():
			self.project_tags["CONSTRAINTS"]["constraint_files"] = []

		self.project_tags["CONSTRAINTS"]["constraint_files"] = [constraint_file_name]

	def append_constraint_file_name(self, constraint_file_name):
		if "CONSTRAINTS" not in self.project_tags.keys():
			self.project_tags["CONSTRAINTS"] = {}

		if "constraint_files" not in self.project_tags["CONSTRAINTS"].keys():
			self.project_tags["CONSTRAINTS"]["constraint_files"] = []

		self.project_tags["CONSTRAINTS"]["constraints_files"].append(constraint_file_name)
	
	def get_constraint_file_names(self):
		if "CONSTRAINTS" in self.project_tags.keys():
			if "constraint_files" in self.project_tags["CONSTRAINTS"].keys():
				return self.project_tags["CONSTRAINTS"]["constraint_files"]


		return []
	
	def set_fpga_part_number(self, fpga_part_number):
		"""
		sets the part number, this is used when generating
		the project
		"""
		if "CONSTRAINTS" not in self.project_tags.keys():
			self.project_tags["CONSTRAINTS"] = {}

		if "device" not in self.project_tags["CONSTRAINTS"].keys():
			self.project_tags["CONSTRAINTS"]["device"] = ""

		self.project_tags["CONSTRAINTS"]["device"] = fpga_part_number

	def get_fpga_part_number(self):
		if "CONSTRAINTS" in self.project_tags.keys():
			if "device" in self.project_tags["CONSTRAINTS"].keys():
				return self.project_tags["CONSTRAINTS"]["device"]

		return "undefined"
	

	def new_design(self):
		"""
		Initialize an empty design
		"""
		self.sgm = gm.SapGraphManager()
		self.bus_type = "wishbone"
		self.tags = {}
		self.file_name = ""
		self.project_tags = {}
		self.project_tags["PROJECT_NAME"] = "project"
		self.project_tags["BASE_DIR"] = "~/sycamore_projects"
		self.project_tags["BUILD_TOOL"] = "xilinx"
		self.project_tags["TEMPLATE"] = "wishbone_template.json"
		self.project_tags["INTERFACE"] = {}
		self.project_tags["INTERFACE"]["filename"] = "uart_io_handler.v"
		self.project_tags["SLAVES"] = {}
		self.project_tags["MEMORY"] = {}
		self.project_tags["CONSTRAINTS"] = {}
		self.project_tags["CONSTRAINTS"]["constraint_files"] = []
		self.project_tags["CONSTRAINTS"]["board"] = ""
		self.project_tags["CONSTRAINTS"]["device"] = ""
		self.project_tags["CONSTRAINTS"]["bind"] = {}


		return

	def set_bus_type(self, bus_type):
		"""
		Set the bus type to Wishbone or Axie
		"""
		self.bus_type = bus_type
		return

	def get_bus_type(self):
		return self.bus_type

	def set_host_interface(self, host_interface_name, debug = False):
		"""
		sets the host interface type
		"""
		hi_name = get_unique_name(	"Host Interface", 
									Node_Type.host_interface) 

		node_names = self.sgm.get_node_names()
		if hi_name not in node_names:
			self.sgm.add_node(	"Host Interface", 
								Node_Type.host_interface)

		#check if the host interface is valid
		file_name = ""
		try:
			sf = sapfile.SapFile()
			file_name = sf.find_module_filename(host_interface_name)
		except ModuleNotFound as ex:
			if debug:
				print "Invalid Module Name: %s" % (host_interface_name)

#XXX: Need to inform the user that the Host Interface Selected was
#not valid
				return False

		file_name = saputils.find_rtl_file_location(file_name)

		#if the host interface is valid then get all the tags
		parameters = saputils.get_module_tags(	filename = file_name, bus=self.get_bus_type())
		#and set them up
		self.sgm.set_parameters(hi_name, parameters)
		return True

	def get_host_interface_name(self):
		hi_name = get_unique_name(	"Host Interface", 
									Node_Type.host_interface) 
		hi = self.sgm.get_node(hi_name)
		return hi.parameters["module"]

	def get_slave_name(self,	slave_type, slave_index):
		s_name = self.sgm.get_slave_name_at(slave_index, slave_type)
		slave = self.sgm.get_node(s_name)
		return slave.name

	def is_arb_master_connected(	self,
									slave_name,
									arb_host):

		slaves = self.sgm.get_connected_slaves(slave_name)
		for key in slaves.keys():
			edge_name = self.sgm.get_edge_name(slave_name, slaves[key])
			if (arb_host == edge_name):
				return True

		return False
		
	def add_arbitrator_by_name(	self,
								host_name,
								arbitrator_name,
								slave_name):

		tags = self.sgm.get_parameters(host_name)
		if arbitrator_name not in tags["arbitrator_masters"]:
			return False

		self.sgm.connect_nodes (host_name, slave_name)
		self.sgm.set_edge_name(host_name, slave_name, arbitrator_name)
		return True



	def add_arbitrator(self, 	host_type, 
								host_index, 
								arbitrator_name,
								slave_type, 
								slave_index):
		"""
		adds an arbitrator and attaches it between the host and
		the slave
		"""
		h_name = self.sgm.get_slave_name_at(host_index, host_type)
		#tags = self.sgm.get_parameters(h_name)
		#print "h_name: " + h_name
		#if arbitrator_name not in tags["arbitrator_masters"]:
		#	return False

		s_name = self.sgm.get_slave_name_at(slave_index, slave_type)
		#self.sgm.connect_nodes (h_name, s_name)
		#self.sgm.set_edge_name(h_name, s_name, arbitrator_name)
		#return True
		return self.add_arbitrator_by_name(h_name, arbitrator_name, s_name)

	def get_connected_arbitrator_slave(self, 
											host_name,
											arbitrator_name):
		tags = self.sgm.get_parameters(host_name)
		if arbitrator_name not in tags["arbitrator_masters"]:
			SlaveError("This slave has no arbitrator masters")	

		slaves = self.sgm.get_connected_slaves(host_name)
		for arb_name in slaves.keys():
			
			slave = slaves[arb_name]
			edge_name = self.sgm.get_edge_name(host_name, slave)
			if edge_name == arbitrator_name:
				return slave


	def get_connected_arbitrator_name(self,	host_type,
											host_index,
											slave_type,
											slave_index):

		h_name = self.sgm.get_slave_name_at(host_index, host_type)
		tags = self.sgm.get_parameters(h_name)
		if arbitrator_name not in tags["arbitrator_masters"]:
			return ""

		s_name = self.sgm.get_slave_name_at(slave_index, slave_type)
		return self.get_edge_name(h_name, s_name)

	def remove_arbitrator_by_arb_master(	self,
											host_name,
											arb_name):
		slave_name = self.get_connected_arbitrator_slave(	host_name, arb_name)

		self.remove_arbitrator_by_name(host_name, slave_name)

		

	def remove_arbitrator_by_name(	self,
									host_name,
									slave_name):

		self.sgm.disconnect_nodes(host_name, slave_name)

	def remove_arbitrator(self,	host_type,
								host_index,
								slave_type,
								slave_index):
		"""
		Finds and removes the arbitrator from the host
		"""
		h_name = gm.get_slave_name_at(host_index, host_type)
		s_name = gm.get_slave_name_at(slave_index, slave_type)
		remove_arbitrator_by_name(h_name, s_name)


	def is_active_arbitrator_host(self, host_type, host_index):

		h_name = self.sgm.get_slave_name_at(host_index, host_type)
		tags = self.sgm.get_parameters(h_name)
		h_node = self.sgm.get_node(h_name)
#		print "node: " + str(h_node)
#		print "parameters: " + str(tags)

		if h_name not in tags["arbitrator_masters"]:
			if len(tags["arbitrator_masters"]) == 0:
				return False

		if not self.sgm.is_slave_connected_to_slave(h_name):
			return False

		return True

	def get_slave_name_by_unique(self, slave_name):
		node = self.sgm.get_node(slave_name)
		return node.name
		
		

	def get_arbitrator_dict(self, host_type, host_index):
		if not self.is_active_arbitrator_host(host_type, host_index):
			return {}

		h_name = self.sgm.get_slave_name_at(host_index, host_type)

		return self.sgm.get_connected_slaves(h_name)

	def rename_slave(self, slave_type, index, new_name):
		"""
		finds a slave by type and index and renames it
		"""

		#get the slave_node
		self.sgm.rename_slave(slave_type, index, new_name)

	def add_slave(self, name, filename, slave_type, slave_index=-1):
		"""
		Adds a slave to the specified bus at the specified index
		"""
		#check if the slave_index makes sense
		#if slave index s -1 then add it to the next available location
		s_count = self.sgm.get_number_of_slaves(slave_type)
		self.sgm.add_node(	name,
							Node_Type.slave,
							slave_type)

		slave = None

		if slave_index == -1:
			slave_index = s_count
		else:
			#add the slave wherever

			if slave_type == Slave_Type.peripheral:
				if slave_index == 0 and name != "DRT":
					raise gm.SlaveError("Only the DRT can be at position 0")
				s_count = self.sgm.get_number_of_peripheral_slaves()
				uname = get_unique_name(	name, \
											Node_Type.slave, \
											slave_type, \
											s_count - 1)		

				slave = self.sgm.get_node(uname)
				if slave_index < s_count - 1:	
					self.sgm.move_peripheral_slave(	slave.slave_index,\
													slave_index)
			elif slave_type == Slave_Type.memory:
				s_count = self.sgm.get_number_of_memory_slaves()
				uname = get_unique_name(	name, \
											Node_Type.slave, \
											slave_type, \
											s_count - 1)

				slave = self.sgm.get_node(uname)
				if slave_index < s_count - 1:
					self.sgm.move_slave(	slave.slave_index, \
											slave_index, \
											Slave_Type.memory)

	
		#print "slave index: " + str(slave_index)

		uname = get_unique_name(	name, \
									Node_Type.slave, \
									slave_type, \
									slave_index)		

		slave = self.sgm.get_node(uname)
		#print "slave unique name: " + uname

		if filename is not None:
			#print "filename: " + filename
			if len(filename) > 0:
				parameters = saputils.get_module_tags(filename, self.bus_type)
				self.sgm.set_parameters(uname, parameters)
		

				#check if there are already some parameter declarations within the project tags
				slaves = {}

				if slave_type == Slave_Type.peripheral:
					if "SLAVES" in self.project_tags.keys():
						slaves = self.project_tags["SLAVES"]

				else:
					if "MEMORY" in self.project_tags.keys():
						slaves = self.project_tags["MEMORY"]
					

				if name in slaves.keys():
					sd = slaves[name]
					if "PARAMETERS" in sd.keys():
						pd = sd["PARAMETERS"]
						for key in pd.keys():
							if key in parameters["parameters"].keys():
								parameters["parameters"][key] = pd[key]



		return

	def remove_slave(self, slave_type = Slave_Type.peripheral, slave_index=0):
		"""
		Removes slave from specified index
		"""
		self.sgm.remove_slave(slave_index, slave_type)
		return

	def move_slave(self, 	slave_name = None, 
							from_slave_type = Slave_Type.peripheral, 
							from_slave_index = 0,
							to_slave_type = Slave_Type.peripheral,
							to_slave_index = 0):
		"""
		move slave from one place to another,
		the slave can be moved from one bus to another
		and the index position can be moved
		"""
		if to_slave_type == Slave_Type.peripheral and to_slave_index == 0:
			return
		if slave_name is None:
			gm.SlaveError("a slave name must be specified")


		if from_slave_type == to_slave_type:
			#simple move call
			self.sgm.move_slave(from_slave_index, to_slave_index, from_slave_type)
			return


		sname = self.sgm.get_slave_name_at(from_slave_index, from_slave_type)

		node = self.sgm.get_node(sname)
		tags = self.sgm.get_parameters(sname)
		#moving to the other bus, need to sever connetions
		self.remove_slave(from_slave_type, from_slave_index)
		sf = sapfile.SapFile()
		filename = sf.find_module_filename(tags["module"]) 
		filename = saputils.find_rtl_file_location(filename)
		self.add_slave(slave_name, filename, to_slave_type, to_slave_index)

		return

	def generate_project(self):
		"""
		Generates the output project that can be used
		to create a bit image
		"""
		self.save_config_file(self.filename)
		try:
			saplib.generate_project(self.filename)
		except IOError as err:
			print "File Error: " + str(err)
		return

	def get_graph_manager(self):
		return self.sgm


