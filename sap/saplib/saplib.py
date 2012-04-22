
import os
import sys
import shutil
import json
import saputils
import sapproject
import glob

def get_interface_list (bus="wishbone"):
	"""Return a list of interfaces associates with bus"""
	interface_list = []
	return interface_list
	
def create_project_config_file(filename, bus = "wishbone", interface="uart_io_handler.v", base_dir = "~"):
	"""Generate a configuration file for a project with the associated bus and interface"""
	return
	
def generate_project(filename, dbg=False):
	"""given a project configuration file generate the project structure"""
	sap = sapproject.SapProject()	
#	try:
#		print "generating project"
	result = sap.generate_project(filename, debug = dbg)
#	except:
#		print "Error generating project: " + str(sys.exc_info()[0])
#		return False
	return result
