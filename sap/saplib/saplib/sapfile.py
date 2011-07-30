import os



class SapFile:
	"""Base SapGen Class must be overriden: Used to modify or generate files"""

	def __init__ (self):
		self.buf = ""
		self.tags = {}
		return

	def read_file(self, location="", filename=""):
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
		self.buf = self.buf.format(self.tags)
		return
	
	def set_tags(self, tags={}):
		"""set the tags, or the keyword: data relation mapping"""
		self.tags = tags
		return

	def process_file(self, filename = "", file_dict={}, directory=""):
		"""read in a file, modify it (if necessary), then wite it to the location specified by the director variable"""
		if (len(filename) == 0):
			return False
		if (len(directory) == 0):
			return False
		
		
		print "in process file"
		#maybe load a tags??

		#using the location value in the file_dict find the file and 
		#pull it into a buf
		if (not file_dict.has_key("location")):
			print "didn't found location"
			return False;
	
		result = self.read_file(file_dict["location"], filename)

		#if the generation flag is set in the dictionary
		if file_dict.has_key("gen_script"):
			print "found the generation script"
			print "run generation script: " + file_dict["gen_script"]
		#call the specific generation script

		#perform the format function
		self.apply_tags()	
		print self.buf
		#write the file to the specified directory
		result = self.write_file(directory, filename)
		return True
