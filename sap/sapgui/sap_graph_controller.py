#!/usr/bin/env python
import sapfile
import sap_graph_manager
from sap_graph_manager import Slave_Type
from sap_graph_manager import Node_Type

class SapGraphController:
	def __init__(self):
		self.sgm = sap_graph_manager.SapGraphManager()
		self.tags = {}
		self.file_name = ""
		return


	def load_file(self, file_name):
		"""
		Loads a sycamore configuration file into memory
		"""
		#clear any previous data
		self.sgm.clear_graph()

	def save_file(self, file_name):
		"""
		Saves a module stored in memory to a file
		"""

		#if there are no slaves on the memory interconnect
		#then don't generate the structure in the JSON file for it

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

	def set_host_interface(self, host_interface_name):
		"""
		sets the host interface type
		"""

		#check if the host interface is valid
		#if the host interface is valid then get all the tags
		#and set them up


	def add_slave(self, slave_name, slave_type, slave_index):
		"""
		Adds a slave to the specified bus at the specified index
		"""
		#check if the slave_index makes sense
		#if slave index s -1 then add it to the next available location

	def remove_slave(self, slave_name = None, slave_type = Slave_Type.peripheral, slave_index=0):
		"""
		Removes slave from specified index
		"""
		#can't remove the DRT so if the index is 0 then don't try

		#it's possible to remove the node given only the
		#Slave_Type, and the slave_index

		#check if the slave_name is 'None', if so then
		#we need to search for the slave_name

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
	



