import os
#from gen_scripts.gen import Gen
import saputils
import glob
import sys
from inspect import isclass
from saperror import ModuleNotFound


class SapFile:
	"""Base SapGen Class must be overriden: Used to modify or generate files"""

	def __init__ (self):
#		print "SAPLIB_BASE: " + os.environ["SAPLIB_BASE"]
#		print "Path: " + str(sys.path)
		self.gen_module = None
		self.gen = None
		self.buf = ""
		self.tags = {}
		self.verilog_file_list = []
		self.verilog_dependency_list = []
		return

	def read_file(self, filename):
		"""open file with the speicifed name, and location"""
		try:
			filein = open (saputils.resolve_linux_path(filename))
			self.buf = filein.read()
		except IOError as err:
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
			if ('$' in err):
				print "Key Error: " + str(err)
			#print "buffer: " + self.buf
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
		
		if (filename.endswith(".v")):
			self.verilog_file_list.append(filename)
		
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
				if debug:
					print "searching for file...",
				absfilename = saputils.find_rtl_file_location(filename)
				result = self.read_file(absfilename)
				if result:
					if debug:
						print "found file!"
				else:
					if debug:
						print "failed to find file"
			if (len(self.buf) == 0):
				if debug:
					print "File wasn't found!"
				return False

			if debug:
				print "file content: " + self.buf

		elif (not file_dict.has_key("gen_script")):
			if debug:
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
			cl = __import__("gen")
			if debug:
				print "cl: " + str(cl)
			Gen = getattr(cl, "Gen")
			if debug:
				print "Gen: " + str(Gen)
			self.gen_module = __import__(file_dict["gen_script"])	
			gen_success_flag = False
			for name in dir(self.gen_module):
				obj = getattr(self.gen_module, name)
	#			print "object type: " + str(obj)
#debug section start
				if debug:
					print "name: " + name
				if isclass(obj):
					if debug:
						print "\tobject type: " + str(obj)
						print "\tis class"
					if issubclass(obj, cl.Gen):
						if debug:
							print "\t\tis subclass"
#debug section end
				if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
					self.gen = obj()
					if debug:
						print "obj = " + str(self.gen)
					self.buf = self.gen.gen_script(tags = self.tags, buf = self.buf)
					gen_success_flag = True

			if (not gen_success_flag):
				print "FAILED TO EXECUTE GENSCRIPT " + file_dict["gen_script"]
		else:
			#perform the format function
			self.apply_tags()	

		if debug:	
			print self.buf
		#write the file to the specified directory
		if (len(self.buf) > 0):
			result = self.write_file(directory, filename)

		if (self.has_dependencies(filename)):
			deps = self.get_list_of_dependencies(filename) 
			for d in deps:
				result = self.find_module_filename(d)
				if (len(result) == 0):
					print "Error: couldn't find dependency filename"
					continue
				f = self.find_module_filename(d)
				if (not self.verilog_dependency_list.__contains__(f) and
					not self.verilog_file_list.__contains__(f)):
					if debug:
						print "found dependency: " + f
					self.verilog_dependency_list.append(f)
				
		return True

	def resolve_dependencies(self, filename, debug = False):
		"""
		given a filename determine if there are any modules it depends on, 
		recursively search for any files found in order to extrapolate all 
		dependencies
		"""
		result = True
		ldebug = debug
		if debug:
			print "in resolve dependencies"
		local_file_list = []
		if debug: 
			print "working on filename: " + filename
		if (self.has_dependencies(filename, debug = ldebug)):
			if debug:
				print "found dependencies!"
			deps = self.get_list_of_dependencies(filename, debug = ldebug)
			for d in deps:
				try:
					dep_filename = self.find_module_filename(d, debug = ldebug)
				except ModuleNotFound as ex:
					print "Dependency Warning: %s" % (str(ex))
					print "Module Name: %s" % (d)
					print "This warning may be due to:"
					print "\tIncluding a simulation only module"
					print "\tIncluding a vendor specific module"
					print "\tA module that was not found"
					continue

#				if (len(dep_filename) == 0):
#					if debug:
#						print "Couldn't find dependency filename for module " + d
#					continue
#				else :
				if debug:
					print "found the filename: " + dep_filename
				#check this file out for dependecies, then append that on to the local list
				result = self.resolve_dependencies(dep_filename, debug = ldebug)
				if debug:
					if result == True:
						if debug:
							print "found all sub dependencies for: " + dep_filename
				local_file_list.append(dep_filename)

		#go through the local file list and add anything found to the list of dependencies or verilog files
		for f in local_file_list:
			if (not self.verilog_dependency_list.__contains__(f) and
				not self.verilog_file_list.__contains__(f)):
	
				if debug:
					print "found dependency: " + f
				self.verilog_dependency_list.append(f)

		return result

	def has_dependencies(self, filename, debug = False):
		"""look in a verilog module, and search for anything that requires a depency, return true if found"""

		if debug:
			print "input file: " + filename
		#filename needs to be a verilog file
		if (filename.partition(".")[2] != "v"):
			if debug:
				print "File is not a recognized verilog source"
			return False

		fbuf = ""
		#the name is a verilog file, try and open is
		try:
			filein = open(filename)
			fbuf = filein.read()
			filein.close()
		except IOError as err:
			if debug:
				print "the file is not a full path, searching RTL... ", 
			#didn't find with full path, search for it
			try: 
				filepath = saputils.find_rtl_file_location(filename)
				filein = open(filepath)	
				fbuf = filein.read()
				filein.close()
			except IOError as err_int:
				if debug:
					print "couldn't find file in the RTL directory"
				return False


		#we have an open file!
		if debug:
			print "found file!"

		#strip out everything we can't use
		fbuf = saputils.remove_comments(fbuf)

		#modules have lines that start with a '.'
		str_list = fbuf.splitlines()

		for item in str_list:
			item = item.strip()
			if (item.startswith(".")):
				if debug:
					print "found a module!"
				return True

		return False

	def get_list_of_dependencies(self, filename, debug=False):
		deps = []
		if debug:
			print "input file: " + filename
		#filename needs to be a verilog file
		if (filename.partition(".")[2] != "v"):
			if debug:
				print "File is not a recognized verilog source"
			return False

		fbuf = ""
		#the name is a verilog file, try and open is
		try:
			filein = open(filename)
			fbuf = filein.read()
			filein.close()
		except IOError as err:
			#if debug:
			#	print "the file is not a full path... searching RTL"
			#didn't find with full path, search for it
			try: 
				filepath = saputils.find_rtl_file_location(filename)
				filein = open(filepath)	
				fbuf = filein.read()
				filein.close()
			except IOError as err_int:
				#if debug:
				#	print "couldn't find file in the RTL directory"
				return False


		#we have an open file!
		if debug:
			print "found file!"

		#strip out everything we can't use
		fbuf = saputils.remove_comments(fbuf)

		include_fbuf = fbuf
		#search for `include
		while (not len(include_fbuf.partition("`include")[2]) == 0):
			ifile_name = include_fbuf.partition("`include")[2]
			ifile_name = ifile_name.splitlines()[0]
			ifile_name = ifile_name.strip()
			ifile_name = ifile_name.strip("\"")
			if debug:
				print "found an include " + ifile_name + " ",
			if (not self.verilog_dependency_list.__contains__(ifile_name) and
				not self.verilog_file_list.__contains__(ifile_name)):
				self.verilog_dependency_list.append(ifile_name)
				if debug:
					print "adding " + ifile_name + " to the dependency list"
			else:
				if debug:
					print "... already in have it"
			include_fbuf = include_fbuf.partition("`include")[2]

		#remove the ports list and the module name
		fbuf = fbuf.partition(")")[2]

		#modules have lines that start with a '.'
		str_list = fbuf.splitlines()
	
		module_token = ""
		done = False
		while (not done): 
			for i in range (0, len(str_list)):
				line = str_list[i]
				#remove white spaces
				line = line.strip()
				if (line.startswith(".") and line.endswith(",")):
					#if debug:
					#	print "found a possible module... with token: " + line
					module_token = line
					break
				#check if we reached the last line
				if (i >= len(str_list) - 1):
					done = True

			if (not done):
				#found a possible module
				#partitoin the fbuf
				#if debug:
				#	print "module token " + module_token
				module_string = fbuf.partition(module_token)[0]
				fbuf = fbuf.partition(module_token)[2]
				fbuf = fbuf.partition(";")[2]
				str_list = fbuf.splitlines()

				#get rid of everything before the possible module
				while (len(module_string.partition(";")[2]) > 0):
					module_string = module_string.partition(";")[2]
							
				module_string = module_string.partition("(")[0]	
				module_string = module_string.strip("#")
				module_string = module_string.strip()

				m_name = module_string.partition(" ")[0]
				if debug:
					print "module name: " + m_name

				if (not deps.__contains__(m_name)):
					if debug:
						print "adding it to the deps list"
					deps.append(module_string.partition(" ")[0])
				

				#mlist = module_string.splitlines()
				#work backwords
				#look for the last line that has a '('
				#for i in range (0, len(mlist)):
				#	mstr = mlist[i]
				#	print "item: " + mlist[i]
				#	#mstr = mlist[len(mlist) - 1 - i]
				#	#mstr = mstr.strip()
				#	if (mstr.__contains__(" ")):
				#		if debug:
				#			print "found: " + mstr.partition(" ")[0]
				#		deps.append(mstr.partition(" ")[0])
				#		break
				

		return deps
		
	
	def find_module_filename (self, module_name, debug = False):
		filename = ""
		"""Returns the filename that contains the module"""
		base = os.getenv("SAPLIB_BASE") + "/hdl/rtl"
		cwd = os.getcwd()

		os.chdir(base)
		#if (debug):
		#	print "changed dir to " + base

		verilog_files = []
		for root, dir, files in os.walk(base):
			filelist = [os.path.join(root, fi) for fi in files if fi.endswith(".v")]

			for f in filelist:
				verilog_files.append(f)

		for f in verilog_files:
			#if debug:
				#print "checking: " + f
			if (self.is_module_in_file(f, module_name)):
				while (len(f.partition("/")[2])):
					f = f.partition("/")[2]
				if debug:
					print "Found a file with the name: " + f
				os.chdir(cwd)
				return f

		#put everything back to where its supposed to be	
		os.chdir(cwd)
		#if debug:
		#	print "didn't find module name"

#sometimes modules cannot be found, but this is okay
		raise ModuleNotFound("Module was not found")
#		return ""

	def is_module_in_file(self, filename, module_name, debug = False):
		"""check the file for the module"""
		
		fbuf = ""
		#the name is a verilog file, try and open is
		try:
			filein = open(filename)
			fbuf = filein.read()
			filein.close()
		except IOError as err:
			if debug:
				print "the file is not a full path... searching RTL"
			#didn't find with full path, search for it
			try: 
				filepath = saputils.find_rtl_file_location(filename)
				filein = open(filepath)	
				fbuf = filein.read()
				filein.close()
			except IOError as err_int:
				if debug:
					print "couldn't find file in the RTL directory"
				return False
		if debug:
			print "opened file: " + filename
		fbuf = saputils.remove_comments(fbuf)
		done = False
		module_string = fbuf.partition("module")[2]
		while (not done):
#			if debug:
			module_string = module_string.partition("(")[0]
			module_string = module_string.strip("#")
			module_string = module_string.strip()
			if debug:
				print "searching through: " + module_string
#			module_string = module_string.strip()
#			module_string = module_string.partition(" ")[0]
			if (len(module_string) == 0):
				done = True
			if (module_string.endswith("(")):
				module_string = module_string.strip("(")
			if debug:
				print "looking at: " + module_string

			if (module_string == module_name):
				if debug:
					print "found " + module_string + " in " + filename
				return True
				
			elif(len(module_string.partition("module")[2]) > 0):
				if debug:
					print "found another module in the file"
				module_string = module_string.partition("module")[2]
			else:
				done = True

		return False


