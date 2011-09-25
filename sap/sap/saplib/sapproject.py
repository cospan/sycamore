import sapfile
import saputils
import json
import os
from os.path import exists
import shutil

class SapProject:
	"""Generates SAP Projects"""

	def __init__(self):
		self.filegen = sapfile.SapFile()
		self.project_tags = {}
		self.template_tags = {}
		return

	def read_config_string(self, json_string=""):
		"""read the JSON string and change it to a structure"""
		self.project_tags = json.loads(json_string)
		return True

	def read_config_file(self, file_name="", debug=False):
		"""Read the project configuration file"""
		if (debug):
			print "File to read: " + file_name
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

		#now we have a buffer call the read config string
		result = self.read_config_string(json_string)
		return result 

	def read_template(self, template_file_name="", debug=False):
		"""Read the template file associatd with this bus"""
		if (debug):
			print "Debug enabled"
		try: 
			if (debug):
				print "attempting local"
			filein = open(template_file_name, "r")
			json_string = filein.read()
			self.template_tags = json.loads(json_string)
			filein.close()
			return True
		except IOError as err:
			filein = None

		#if the project doesn't have a .json file association
		if (not template_file_name.endswith(".json")):
			template_file_name = template_file_name + ".json"
		
			try:
				if (debug):
					print "attempting local + .json"
				filein = open(template_file_name, "r")
				json_string = filein.read()
				self.template_tags = json.loads(json_string)
				filein.close()
				return True
			except IOError as err:
				filein = None

		#see if there is a environmental setting for SAPLIB_BASE
		if (len(os.getenv("SAPLIB_BASE")) > 0):
			file_name = os.getenv("SAPLIB_BASE") + "/templates/" + template_file_name	
			try:
				if (debug):
					print "attempting environmental variable SAPLIB_BASE"
					print file_name
				filein = open(file_name, "r")
				json_string = filein.read()
				self.template_tags = json.loads(json_string)
				filein.close()
				return True
			except IOError as err:
				filein = None

		#see if the sap_location was specified
		if (self.project_tags.has_key("sap_location")):
			file_name = self.project_tags["sap_location"] + "/templates/" + template_file_name
			try:
				if (debug):
					print "attempting to read from project tags"
				filein = open (file_name, "r")
				json_string = filein.read()
				self.template_tags = json.loads(json_string)
				filein.close()
				return True
			except IOError as err:
				filein = None

		#try the default location	
		file_name = "../templates/" + template_file_name
		try:
			if (debug):
				print "attemping to read from hard string"
			filein = open(file_name, "r")
			json_string = filein.read()
			self.template_tags = json.loads(json_string)
			filein.close()
			return True
		except IOError as err:
			filein = None
		
		return False

	def generate_project(self, config_file_name, debug=False):
		"""Recursively go through template structure and generate the folders and files"""
		#reading the project config data into the the project tags
		result = self.read_config_file(config_file_name)
		if (not result):
			if (debug):
				print "failed to read in project config file"
			return False
		
		#extrapolate the bus template
		result = self.read_template(self.project_tags["TEMPLATE"])
		if (not result):
			if (debug):
				print "failed to read in template file"
			return False

		#set all the tags within the filegen structure
		self.filegen.set_tags(self.project_tags)

		#generate the project directories and files
		saputils.create_dir(self.project_tags["BASE_DIR"])		
		#print "Parent dir: " + self.project_tags["BASE_DIR"]
		for key in self.template_tags["PROJECT_TEMPLATE"]["files"]:
			self.recursive_structure_generator(
							self.template_tags["PROJECT_TEMPLATE"]["files"],
							key,
							self.project_tags["BASE_DIR"])

		#Generate all the slaves
		for slave in self.project_tags["SLAVES"]:
			fdict = {"location":""}
			file_dest = self.project_tags["BASE_DIR"] + "/rtl/bus/slave"
			result = self.filegen.process_file(filename = slave, file_dict = fdict, directory=file_dest)
			#each slave

		#Copy the user specified constraint files to the constraints directory
		for constraint_fname in self.project_tags["CONSTRAINTS"]["constraint_files"]:
			sap_abs_base = os.getenv("SAPLIB_BASE")
			abs_proj_base = saputils.resolve_linux_path(self.project_tags["BASE_DIR"])
			constraint_path = self.get_constraint_path(constraint_fname)
			if (len(constraint_path) == 0):
				print "Couldn't find constraint: " + constraint_fname + ", searched in current directory and " + sap_abs_base + " /hdl/" + self.project_tags["CONSTRAINTS"]["board"]
				continue
			shutil.copy (constraint_path, abs_proj_base + "/constraints/" + constraint_fname)

		#Generate the IO handler
		interface_filename = self.project_tags["INTERFACE"]
		fdict = {"location":""}
		file_dest = self.project_tags["BASE_DIR"] + "/rtl/bus/interface"
		result = self.filegen.process_file(filename = interface_filename, file_dict=fdict , directory=file_dest)

		if debug:
			print "copy over the dependencies..."
		print "verilog files: "
		for f in self.filegen.verilog_file_list:
			print f
		print "dependent files: "
		for d in self.filegen.verilog_dependency_list:
			fdict = {"location":""}
			file_dest = self.project_tags["BASE_DIR"] + "/dependencies"
			result = self.filegen.process_file(filename = d, file_dict = fdict, directory = file_dest)
			print d
		return True

	def get_constraint_path (self, constraint_fname):
		sap_abs_base = os.getenv("SAPLIB_BASE")
		board_name	= self.project_tags["CONSTRAINTS"]["board"]
		sap_abs_base = saputils.resolve_linux_path(sap_abs_base)
		if (exists(os.getcwd() + "/" + constraint_fname)):
			return os.getcwd() + "/" + constraint_fname
		#search through the board directory
		if (exists(sap_abs_base + "/hdl/boards/" + board_name + "/" + constraint_fname)): 
			return sap_abs_base + "/hdl/boards/" + board_name + "/" + constraint_fname
		return ""
		
	def recursive_structure_generator(self, 
								parent_dict = {}, 
								key="", 
								parent_dir = "",  
								debug=False):
		"""recursively generate all directories and files"""
		if (parent_dict[key].has_key("dir") and parent_dict[key]["dir"]):
			#print "found dir"
			saputils.create_dir(parent_dir + "/" + key)
			if (parent_dict[key].has_key("files")):
				for sub_key in parent_dict[key]["files"]:
					#print "sub item :" + sub_key
					self.recursive_structure_generator(
							parent_dict = parent_dict[key]["files"],
							key = sub_key,
							parent_dir = parent_dir + "/" + key)
		else:
			#print "generate the file: " + key + " at: " + parent_dir
			self.filegen.process_file(key, parent_dict[key], parent_dir)

		return True

	def query_slave(self, slave_name=""):
		"""Using the template structure determing if the slave exists"""
		#using the bus template find the location of the slave folders

		#see if the name matches up to any of the files
		#"name".v or "name".vhd
		return False

	def get_slave_meta_data(self, slave_name=""):
		"""get the data that will be used for the DRT"""
		#look for data within the verilog or VHDL file (verilog only right now)
		return None
	
	def query_handler(self, handler_name=""):
		"""see if a handler exists"""
		return False


	
