import os



class SapGen:
	"""Base SapGen Class must be overriden: Used to modify or generate files"""

	def __init__ (self):
		self.buf = ""
		self.tag_map = {}
		self.project_name = ""
		return

	def open_file(self, location="", filename=""):
		"""open file with the speicifed name, and location"""
		try:
			filein = open (location + "/" + filename, "r")
			with open (location + "/" + filename) as filein:
				self.buf = filein.read()
		except IOError as err:
			print ("File Error: " + str(err));
			return False
		return True

	def write_file(self, location = "", filename="", home=False):
		"""write the self.buf to the file/location specified"""
		if location.startswith("~"):
			home = True
			location = location.strip("~//")

		try:
			fileout = None
			if (home):
				fileout = open(os.getenv("HOME") + "/" +  location + "/" + filename, "w")
			else:
				fileout = open (location + "/" + filename, "w")
			fileout.write(self.buf)
			fileout.close()
		except IOError as err:
			print ("Write File: File Error: " + str(err))
			return False

		return True

	def generate_file(self, filename="", gen_script_name=""):
		"""run the custom script specified on the buf"""
		return

	def modify_file(self):
		"""substitute the tags with the data specific to this project"""
		#search through the buf for any tags that match something within
		#our tag map
		if self.tag_map.has_key("PROJECT_NAME"):
			print "has key!"
		self.buf = self.buf.format(self.tag_map)
		return
	
	def set_tag_map(self, tag_map={}):
		"""set the tag_map, or the keyword: data relation mapping"""
		if tag_map.has_key("PROJECT_NAME"):
			self.project_name = tag_map["PROJECT_NAME"]
		
		self.tag_map = tag_map
		self.tag_map["PROJECT_NAME"] = self.project_name
		return

	def clear_tag_map(self):
		"""clear the current tag"""
		self.tag_map = {}
		return

	def set_project_name(self, project_name="project_name"):
		"""set the project name, this will be loaded with all new tag maps"""
		self.project_name = project_name	
		return
	
	def load_tag_file(self, tag_file = ""):
		"""load a tag file, tags can be opened through a file, or as an actual dictionary""" 
		try:
			json_file = open (tag_file)
			print ("loaded the file")
			#set_tag_map(json_load(json_file))
		except IOError as err:
			print "IO Error" + str(err)
			return False

		json_file.close()

		return True

	def process_file(self, filename = "", file_dict={}, directory="", tag_map={}):
		"""read in a file, modify it (if necessary), then wite it to the location specified by the director variable"""
		if (len(filename) == 0):
			return False
		if (len(directory) == 0):
			return False
		
		
		print "in process file"
		#maybe load a tag_map??

		#using the location value in the file_dict find the file and 
		#pull it into a buf
		if (not file_dict.has_key("location")):
			print "didn't found location"
			return False;
	
		result = self.open_file(file_dict["location"], filename)

		#if the generation flag is set in the dictionary
		if file_dict.has_key("gen_script"):
			print "found the generation script"
			print "run generation script: " + file_dict["gen_script"]
		#call the specific generation script

		#perform the format function
		self.modify_file()	
		print self.buf
		#write the file to the specified directory
		result = self.write_file(directory, filename)
		return True
