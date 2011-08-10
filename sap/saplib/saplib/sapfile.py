import os
import saputils
from gen import Gen
from inspect import isclass


class SapFile:
	"""Base SapGen Class must be overriden: Used to modify or generate files"""

	def __init__ (self):
		self.buf = ""
		self.tags = {}
		return

	def read_file(self, filename):
		"""open file with the speicifed name, and location"""
		try:
			filein = saputils.open_linux_file(filename)
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

	def apply_gen_script(self, filename="", gen_script_name="", file_dict={}):
		"""run the custom script specified on the buf"""
		#extrapolate the script location from the file_dict
		#create a local module of the generation script
		#mod = __import__(file_dict["gen_script"])

		#mod.apply_script(self.buf, self.tags)
		return

	def apply_tags(self):
		"""substitute the tags with the data specific to this project"""
		#search through the buf for any tags that match something within
		#our tag map
		try:
			self.buf = self.buf.format(self.tags)
		except KeyError as err:
			print "Key Error: " + str(err)

		return
	
	def set_tags(self, tags={}):
		"""set the tags, or the keyword: data relation mapping"""
		self.tags = tags
		return

	def process_file(self, filename = "", file_dict={}, directory="", debug=False):
		"""read in a file, modify it (if necessary), then wite it to the location specified by the director variable"""
		if (len(filename) == 0):
			return False
		if (len(directory) == 0):
			return False
		
		
		if (debug):	
			print "in process file"
		#maybe load a tags??

		#using the location value in the file_dict find the file and 
		#pull it into a buf

		self.buf = ""
		file_location = ""
		if file_dict.has_key("location"):
			file_location = os.getenv("SAPLIB_BASE") + "/" + file_dict["location"]
			if (debug): 
				print ("getting file: " + filename + " from location: " + file_location)
				
			result = self.read_file(file_location + "/" +  filename)
			if (not result):
				print "searching for file...",
				absfilename = saputils.find_rtl_file_location(filename)
				result = self.read_file(absfilename)
				if result:
					print "found file!"
				else:
					print "failed to find file"
			if (len(self.buf) == 0):
				print "File wasn't found!"
				return False

			if (debug):
				print "file content: " + self.buf

		elif (not file_dict.has_key("gen_script")):
			print "didn't find file location"
			return False


		if (debug):
			print "Project name: " + self.tags["PROJECT_NAME"]
			
		#if the generation flag is set in the dictionary
		if (file_dict.has_key("gen_script")):
			if (debug):
				print "found the generation script"
				print "run generation script: " + file_dict["gen_script"]
			#open up the new gen module
			gen_module = __import__(file_dict["gen_script"])	
			for name in dir(gen_module):
				obj = getattr(gen_module, name)
				if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
					gen = obj()
					self.buf = gen.gen_script(tags = self.tags, buf = self.buf)

			
		else:
			#perform the format function
			self.apply_tags()	

		if (debug):	
			print self.buf
		#write the file to the specified directory
		result = self.write_file(directory, filename)

		return True
