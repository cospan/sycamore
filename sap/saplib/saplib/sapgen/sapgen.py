



class SapGen:
	"""Base SapGen Class must be overriden: Used to modify or generate files"""

	def __init__ (self):
		self.buffer = ""
		self.tag_map = {}
		self.project_name = ""
		return

	def open_file(self, location="", filename=""):
		try:
			filein = open (location + "/" + filename, "r")
			with open (location + "/" + filename) as filein:
				self.buffer = filein.read()
		except IOError as err:
			print ("File Error: " + str(err));
			return False
		return True

	def write_file(self, filename="", location=""):
		return

	def generate_file(self, filename=""):
		return

	def modify_file(self):
		#search through the buffer for any tags that match something within
		#our tag map
		if self.tag_map.has_key("PROJECT_NAME"):
			print "has key!"
		self.buffer = self.buffer.format(self.tag_map)
		return
	
	def set_tag_map(self, tag_map={}):
		if tag_map.has_key("PROJECT_NAME"):
			self.project_name = tag_map["PROJECT_NAME"]
		
		self.tag_map = tag_map
		self.tag_map["PROJECT_NAME"] = self.project_name
		return

	def clear_tag_map(self):
		self.tag_map = {}
		return

	def set_project_name(self, project_name="project_name"):
		self.project_name = project_name	
		return
	
	def load_tag_file(self, tag_file = ""):
		try:
			tag_file = open (tag_file)
			set_tag_map(json_load(json_file))
		except:
			print "IO Error"
			return False

		tag_file.close()

		return True
