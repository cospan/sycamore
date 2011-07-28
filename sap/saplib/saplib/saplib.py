
import os
import sys
import shutil
import json
import saputils

class Sap:
	"""sap library class"""


	def __init__ (self, name="project", dir="~/sycamore_projects/", 
					json_string="", bus_type="wishbone"):
		self.name = name
		self.dir = dir
		self.json_string = json_string
		self.sap_dict = {}
		self.sap_dict["master handler list"] = []
		self.sap_dict["slave list"] = []
		self.bus_type = bus_type;
		self.selected_handler = "uart";
		self.sap_dict["master handler list"].append(self.selected_handler)
		self.template = {}
		return

	def query_slaves (self, slave_name):
		"""query the list of slaves in the <bus> directory for the specified slave"""
		if (slave_name in self.sap_dict["slave list"]):
			return True
		return False
	
	def query_handlers(self, handler_name):
		"""query the available handlers for the specified type"""
		if (handler_name in self.sap_dict["master handler list"]):
			return True
		return False

	def update_json(self, json_string=""):
		"""based on the json string, update the class and generate new files"""
		#save the json_string for postarity
		self.json_string = json_string
		#if the bus_type has changed extract it and set the correct value.
		#make sure the bus type is supported.

		#Check if there is a new master_handler declared.
		#If a new handler is declared set the value, and then update the files

		#Read in all slaves
		#Check if the list of slaves have changed
		#Generate corresponding files	


	def create_json(self, filename):
		"""Generating a JSON file"""
		json_string = json.dumps([1, 2], indent = 4)
		#print "simple json list", json_string
		json_string = json.dumps({"key":"value"}, indent = 4)
		#print "simpe dictionary entry", json_string
		json_string = json.dumps(['foo', {'bar': ('baz', None, 1.0, 2)}], indent=4)
		#print "complex dictionary, and list", json_string
		return

	def load_json_string(self, json_string):
		"""Generate a structure from an input string"""
		#print "Loading JSON Structure:"
		json_structure = json.loads(json_string)
		return json_structure

	def load_project_template(self, json_file_name):
		"""Load JSON code from file"""
	
		json_file = open (json_file_name);
		#json_structure = json.load(json_file);
		#load the structure into the class variable template
		self.template = json.load(json_file);
		#print "loading JSON structure from file"
		return self.template
	
	def load_project_config(self, json_config_file_name=""):
		"""Load JSON configuration file"""
		return

	def set_base_directory(self, base_directory=""):
		if (len(base_directory) == 0):
			return False;
		self.template["base dir"] = base_directory
		return True;

	def generate_project_structure(self, project_name="test_project"):
		"""Generate a project based on the information within the project_structure"""
		#go through the structure
		#print len(project_structure)

		if (len(self.template) == 0):
			#there is no keys in the structure, return an error
			return -1
		#first generate the base directory
		result = saputils.create_dir(self.template["base dir"])

		if (result == False):
			print "couldn't create base directory"
			return -2

		#print (self.template["project dir"])
		#for key in self.template["project dir"]:
			#recursively go through each of the 'dir's and create the directories
		print "Parent dir ", self.template["base dir"]
		for key in self.template["project template"]["files"]:
			self.recursive_structure_generator(
											self.template["project template"]["files"], 
											key, 
											self.template["base dir"])
			#print (key)

		#Read in Makefile
		#Modify the Makefile to add the test project names
		#Write the Makefile to the base directory

		#Read in the README
		#Modify the README to make is specific to the users project
		#Write the README to the base directory

		#Create the scripts directory
		return 0

	def recursive_structure_generator(self, parent_dict={}, key="", 
										parent_dir="", debug=False):
		"""recursively generate all the directories"""
		if (isinstance(parent_dict[key], dict)):
			if (parent_dict[key].has_key("type")):	
				if (parent_dict[key]["type"] == "dir"):
					saputils.create_dir(parent_dir + "/" + key)
					if (parent_dict[key].has_key("files")):
						for sub_key in parent_dict[key]["files"]:
							print "sub item: " + sub_key
							self.recursive_structure_generator(parent_dict = parent_dict[key]["files"], key = sub_key, parent_dir = parent_dir + "/" + key)
				else: 
					print "need to generate the file"
		elif (isinstance(parent_dict[key], list)):
			print key, " is a List"
			for sub_key in key:
				self.recursive_structure_generator(key = sub_key)
		elif (isinstance(parent_dict[key], unicode)):
			print key, " is a String"
		else:
			print "Type: ", type(parent_dict[key])
			return False
	
			#check what type of key it is
			#if it is a directory, generate the directory, and then go to the next level down.
			
			#if it is not a directory then it is a file, and process the file
		return True
