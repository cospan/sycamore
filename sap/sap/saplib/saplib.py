
import os
import sys
import shutil
import json
import saputils
import sapproject

def get_slave_list (bus="wisbone"):
	"""Return a list of the slaves associated with bus"""
	slave_list = []
	return slave_list

def get_interface_list (bus="wishbone"):
	"""Return a list of interfaces associates with bus"""
	interface_list = []
	return interface_list
	
def create_project_config_file(filename, bus = "wishbone", interface="uart_io_handler.v", base_dir = "~"):
	"""Generate a configuration file for a project with the associated bus and interface"""
	return
	
def generate_project(filename):
	"""given a project configuration file generate the project structure"""
	sap = sapproject.SapProject()	
	try:
		print "generating project"
		result = sap.generate_project(filename, debug = True)
	except:
		print "Error generating project"
		return False
	return result
