#!/usr/bin/env python
import json
import sapfile
import saputils
import sap_graph_manager
from sap_graph_manager import Slave_Type
from sap_graph_manager import Node_Type

def enum(*sequential, **named):
	enums = dict(zip(sequential, range(len(sequential))), **named)
	return type('Enum', (), enums)

Bus_Type = enum(	'wishbone', 
					'axie4', 
				)


class SapGraphController:
	def __init__(self):
		self.sgm = sap_graph_manager.SapGraphManager()
		self.tags = {}
		self.file_name = ""
		return


	def load_config_file(self, file_name, debug=False):
		"""
		Loads a sycamore configuration file into memory
		"""
		#clear any previous data
		self.sgm.clear_graph()
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



		return

	def save_config_file(self, file_name):
		"""
		Saves a module stored in memory to a file
		"""

		#if there are no slaves on the memory interconnect
		#then don't generate the structure in the JSON file for it
		return

	def set_project_location(self, location):
		"""
		sets the location of the project to output
		"""
		return
	
	def get_project_location(self):
		return
		

	def set_project_name(self, name):
		"""
		sets the name of the output project
		"""
		return

	def get_project_name(self):
		return

	def set_vendor_tools(self, vendor_tool):
		"""
		sets the vendor build tool, currently only
		Xilinx is supported
		"""
		return

	def get_vendor_tools(self):
		return

	def set_board_name(self, board_name):
		"""
		sets the name of the board to use
		"""
		return
	
	def get_board_name(self):
		return
	
	def set_constraint_file_name(self, constraint_file_name):
		"""
		sets the constraint file name
		"""
		return
	
	def get_constraint_file_name(self):
		return
	
	def set_fpga_part_number(self, fpga_part_number):
		"""
		sets the part number, this is used when generating
		the project
		"""
		return

	def get_fpga_part_number(self):
		return

	def new_design(self):
		"""
		Initialize an empty design
		"""
		return

	def initialize_graph(self):
		"""
		Initializes the graph and project tags
		"""
		#attempt to load data from the tags
		#check the type of bus
		#check if there is a host insterface defined
		
		#add the host interface
		#add the master
		#add the peripheral interconnect
		#add the memory interconnect
		#add the DRT
		return

	def generate_project(self):
		"""
		Generates the output project that can be used
		to create a bit image
		"""
		return

	def set_bus_type(self, bus_type):
		"""
		Set the bus type to Wishbone or Axie
		"""
		return

	def get_bus_type(self):
		return

	def set_host_interface(self, host_interface_name):
		"""
		sets the host interface type
		"""

		#check if the host interface is valid
		#if the host interface is valid then get all the tags
		#and set them up
		return

	def get_host_interface(self):
		return

	def add_arbitrator(self, 	host_name, 
								host_type, 
								host_index, 
								slave_name, 
								slave_type, 
								slave_index):
		"""
		adds an arbitrator and attaches it between the host and
		the slave
		"""

	def remove_arbitrator(self,	host_name,
								host_type,
								host_index):
		"""
		Finds and removes the arbitrator from the host
		"""

	def add_slave(self, slave_name, slave_type, slave_index):
		"""
		Adds a slave to the specified bus at the specified index
		"""
		#check if the slave_index makes sense
		#if slave index s -1 then add it to the next available location
		return

	def remove_slave(self, slave_name = None, slave_type = Slave_Type.peripheral, slave_index=0):
		"""
		Removes slave from specified index
		"""
		#can't remove the DRT so if the index is 0 then don't try

		#it's possible to remove the node given only the
		#Slave_Type, and the slave_index

		#check if the slave_name is 'None', if so then
		#we need to search for the slave_name
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
		return

	
	



