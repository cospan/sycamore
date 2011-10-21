import os
import sys
import string
import sappreproc

"""utilites that don't really belong in any of the sap classes"""

def create_dir(filename, debug=False):
	"""Generate a directory with the specified location"""
	
	#print "os: ", os.name, "..."
	#print "split: ", os.path.split(filename)
	#print "split text: ", os.path.splitext(filename)
	#print "dirname: ", os.path.dirname(filename)
	#print "basename", os.path.basename(filename)
	#print "join: ", os.path.join(os.path.dirname(filename), 
	#							os.path.basename(filename))
	#print "cwd: ", os.getcwd()	
	#print "uname: ", os.uname()
	
	if filename.startswith("~"):
		filename = filename.strip("~")
		filename = os.getenv("HOME") + filename

	if debug:
		print "Directory to create: ", filename

	if  (not os.path.exists(filename)):
		if debug:
			print ("Directory doesn't exist attempting to create...")
		try: 
			os.makedirs(filename)
		except os.error:
			if debug:
				print "Error: failed to create the directory"
	else:
		if debug:
			print ("Found the directory")
	return True


def resolve_linux_path(filename):
	"""returns a filename, if the tilde is in the name it generates the absolute filename"""
	if (filename.startswith("~")):
		filename = os.path.expanduser("~") + filename.strip("~")
	return filename
		
def remove_comments(buf="", debug=False):
	"""remove comments from a buffer"""
	#first pass remove the '//' comments
	lines = buf.splitlines()
	if debug:
		print "buf:\n" + buf
	bufx = ""
	for line in lines:
		line = line.partition("//")[0]
		bufx = bufx + line + "\n"
	if debug:
		print "bufx:\n" + bufx

	if debug:
		print "working on /* */ comments\n\n\n"
	#get rid of /*, */ comments
	buf_part = bufx.partition("/*")
	pre_comment = ""
	post_comment = ""
	bufy = bufx
	while (len(buf_part[1]) != 0):
		pre_comment = buf_part[0]
		post_comment = buf_part[2].partition("*/")[2]
		#print "pre_comment: " + pre_comment
		#print "post comment: " + post_comment
		bufy = pre_comment + post_comment	
		buf_part = bufy.partition("/*")
		pre_comment = ""
		post_comment = ""

	if debug:
		print "bufy:\n" + bufy

	return bufy

def find_rtl_file_location(filename=""): 
	"""read in a filename, and look for the file location within the RTL, return an addres"""
	base_location = os.getenv("SAPLIB_BASE")
	base_location = base_location + "/hdl/rtl"
#	print "rtl dir: " + base_location
	for root, dirs, names in os.walk(base_location):
		if filename in names:
#			print "Filename: " + filename
			return os.path.join(root, filename)
	return ""

def get_module_tags(filename="", bus="", keywords = [], debug=False):
	tags = {}
	tags["keywords"] = {}
	tags["ports"] = {}
	tags["module"] = ""
		
	#need a more robust way of openning the slave

#	keywords = [
#		"DRT_ID",
#		"DRT_FLAGS",
#	]

	ports = [
		"input",
		"output",
		"inout"
	]

	#XXX only working with verilog at this time, need to extend to VHDL
	with open(filename) as slave_file:
		buf = slave_file.read()
	
	#find all the metadata
	for key in keywords:
		index = buf.find (key)
		if (index == -1):
			if debug:
				print "didn't find substring for " + key
			continue
		if debug:
			print "found substring for " + key

		substring = buf.__getslice__(index, len(buf)).splitlines()[0]
		if debug:
			print "substring: " + substring

		
		if debug:
			print "found " + key + " substring: " + substring

		substring = substring.strip()
		substring = substring.strip("//")
		substring = substring.strip("/*")
		tags["keywords"][key] = substring.partition(":")[2] 
			
				

	#remove all the comments from the code
	buf = remove_comments(buf)
	#print "no comments: \n\n" + buf

	for substring in buf.splitlines():
		if (len(substring.partition("module")[1]) == 0):
			continue
		module_string = substring.partition("module")[2]
		module_string = module_string.strip(" ")
		index = module_string.find(" ")

		if (index != -1):
			tags["module"] = module_string.__getslice__(0, index)
		else:
			tags["module"] = module_string

		if debug:
			print "module name: " + module_string
			print tags["module"]

		break
	
	#find all the ports
	#find the index of all the processing block
	substrings = buf.splitlines()

	input_count = buf.count("input")
	output_count = buf.count("output")
	inout_count = buf.count("inout")

	if debug:
		print "filename: " + filename
	
	filestring = ""
	try:
		f = open(filename)
		filestring = f.read()
		f.close()
	except:
		print "Failed to open test filename"
		return

	define_dict = sappreproc.generate_define_table(filestring, True)	

	for io in ports:
		tags["ports"][io] = {}
		substrings = buf.splitlines()	
		for substring in substrings:
			if debug:
				print "working on substring: " + substring
			substring = substring.strip()
			#if line doesn't start with an input/output or inout
			if (not substring.startswith(io)):
				continue
			#if the line does start with input/output or inout but is used in a name then bail
			if (not substring.partition(io)[2][0].isspace()):
				continue
			#one style will declare the port names after the ports list
			if (substring.endswith(";")):
				substring = substring.rstrip(";")
			#the other stile will include the entire port definition within the port declaration
			if (substring.endswith(",")):
				substring = substring.rstrip(",")
			if debug:
				print "substring: " + substring
			substring = substring.partition(io)[2]
			if (len(substring.partition("reg")[1]) != 0):
				substring = substring.partition("reg")[2]
			substring = substring.strip()
			max_val = -1
			min_val = -1
			if (len(substring.partition("]")[2]) != 0):
				#we have a range to work with?
				length_string = substring.partition("]")[0] + "]"
				substring = substring.partition("]")[2] 
				substring = substring.strip()
				length_string = length_string.strip()
				if debug:
					print "length string: " + length_string

				ldebug = debug

				length_string = sappreproc.resolve_defines(length_string, define_dict, debug=ldebug)
				length_string = sappreproc.evaluate_range(length_string)
				length_string = length_string.partition("]")[0]
				length_string = length_string.strip("[")
				if debug:
					print "length string: " + length_string
				max_val = string.atoi(length_string.partition(":")[0])
				min_val = string.atoi(length_string.partition(":")[2])

			tags["ports"][io][substring] = {}

			if (max_val != -1):
				tags["ports"][io][substring]["max_val"] = max_val
				tags["ports"][io][substring]["min_val"] = min_val
				tags["ports"][io][substring]["size"] = (max_val + 1) - min_val
			else:
				tags["ports"][io][substring]["size"] = 1
			
			#print io + ": " + substring


	if debug:
		print "input count: " + str(input_count)
		print "output count: " + str(output_count)
		print "inout count: " + str(inout_count)
		print "\n"
			
	if debug:
		print "module name: " + tags["module"]
		for key in tags["keywords"].keys():
			print "key: " + key + ":" + tags["keywords"][key]
		for io in ports:
			for item in tags["ports"][io].keys():
				print io + ": " + item
				for key in tags["ports"][io][item].keys():
					value = tags["ports"][io][item][key]
					if (isinstance( value, int)):
						value = str(value)
					print "\t" + key + ":" + value


	return tags


