import os
import sys
import string
import glob
import sappreproc
import saparbitrator

"""utilites that don't really belong in any of the sap classes"""

"""
Changes:
12/06/2011
	-Modified the clock_read function so that the ucf file can have
	quotation marks
04/22/2012
	-Added the get_slave_list function that returns a list of the
	available slave filenames
"""


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
		print "buf:\n" + bufy

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
	tags["parameters"] = {}
	tags["arbitrator_masters"] = []
	raw_buf = ""
		
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
		raw_buf = buf

	
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

	ldebug = debug
	define_dict = sappreproc.generate_define_table(filestring, ldebug)	

	#find all the IO's
	for io in ports:
		tags["ports"][io] = {}
		substrings = buf.splitlines()	
		for substring in substrings:
#			if debug:
#				print "working on substring: " + substring
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


	#find all the USER_PARAMETER declarations
	user_parameters = []
	substrings = raw_buf.splitlines()
	for substring in substrings:
		substring = substring.strip()
		if "USER_PARAMETER" in substring:
			name = substring.partition(":")[2].strip()
			user_parameters.append(name)


	#find all the parameters
	substrings = buf.splitlines()
	for substring in substrings:
		substring = substring.strip()	
		if ("parameter" in substring):
			if debug:
				print "found parameter!"
			substring = substring.partition("parameter")[2].strip()
			parameter_name = substring.partition("=")[0].strip()
			parameter_value = substring.partition("=")[2].strip()
			parameter_value = parameter_value.partition(";")[0].strip()
			if debug:
				print "parameter name: " + parameter_name
				print "parameter value: " + parameter_value
			if parameter_name in user_parameters:
				tags["parameters"][parameter_name] = parameter_value


	tags["arbitrator_masters"] = saparbitrator.get_number_of_arbitrator_hosts(tags)


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



	
def read_clock_rate(constraint_filename, debug = False):
	"""returns a string of the clock rate 50MHz = 50000000"""
	base_location = os.getenv("SAPLIB_BASE")
	base_location = base_location + "/hdl/boards"
	filename = ""
	buf = ""
	clock_rate = ""
#	print "rtl dir: " + base_location
	if debug:
		print "Looking for: " + constraint_filename
	for root, dirs, names in os.walk(base_location):
		if debug:
			print "name: " + str(names)

		if constraint_filename in names:
			if debug:
				print "found the file!"
			filename =  os.path.join(root, constraint_filename)
			break

	if (len(filename) == 0):
		if debug:
			print "didn't find constraing file"
		return ""

	#open up the ucf file
	try:
		file_in = open(filename)
		buf = file_in.read() 
		file_in.close()
	except:
		#fail
		if debug:
			print "failed to open file: " + filename
		return ""

	if debug:
		print "Opened up the UCF file"

	lines = buf.splitlines()
	#first search for the TIMESPEC keyword
	for line in lines:
		line = line.lower()
		#get rid of comments
		if ("#" in line):
			line = line.partition("#")[0]

		#is this the timespec for the "clk" clock?
		if ("timespec" in line) and ("ts_clk" in line):
			if debug:
				print "found timespec"
			#this is the "clk" clock, now read the clock value 
			if debug:
				print "found TIMESPEC"
			line = line.partition("period")[2].strip()
			if debug:
				print "line: " + line
			line = line.partition("clk")[2].strip()
			line = line.strip("\"");
			line = line.strip();
			line = line.strip(";")
			if debug:
				print "line: " + line

			#now there is a time value and a multiplier
			clock_lines = line.split(" ")
			if debug:
				for line in clock_lines:
					print "line: " + line
				
			if (clock_lines[1] == "mhz"):
				clock_rate = clock_lines[0] + "000000"
			if (clock_lines[1] == "khz"):
				clock_rate = clock_lines[0] + "000"


	#if that didn't work search for the PERIOD keyword, this is an older version
	if (len(clock_rate) == 0):
		if debug:
			print "didn't find TIMESPEC, looking for period"
		#we need to check period
		for line in lines:
			#get rid of comments
			line = line.lower()
			if ("#" in line):
				line = line.partition("#")[0]
			if ("period" in line) and  ("clk" in line):
				if debug:
					print "found clock period"
				line = line.partition("period")[2]
				line = line.partition("=")[2].strip()
				if " " in line:
					line = line.partition(" ")[0].strip()
				if debug:
					print "line: " + line
				clock_rate = str(int(1/(string.atoi(line) * 1e-9)))
				break;
	
	if debug:
		print "Clock Rate: " + clock_rate
	return clock_rate


def get_slave_list(bus = "wishbone", debug = False):
	if debug:
		print "in get slave list"
	base_dir = os.getenv("SAPLIB_BASE")	
	directory = base_dir + "/hdl/rtl/" + bus + "/slave"

	file_list = _get_file_recursively(directory)
	
	if debug:
		print "verilog files: "
	for f in file_list:
		if debug:
			print "\t" + f

	slave_list = []
	#check to see if the files are a wishbone slave file
	for f in file_list:
		fin = None
		data = ""
		try:
			fin = open(f, "r")
			data = fin.read()
			fin.close()
		except IOError as err:
			if debug:
				print "failed to open: " + str(err)

		if "DRT_ID" not in data:
			continue
		if "DRT_FLAGS" not in data:
			continue
		if "DRT_SIZE" not in data:
			continue

		name = f.split("/")[-1]
		if name == "wishbone_slave_template.v":
			continue

		slave_list.append(f)

	if debug:
		print "slave list: "
		for f in slave_list:
			print "\t" + f

	return slave_list

def _get_file_recursively(directory):
	file_dir_list = glob.glob(directory + "/*")
	file_list = []
	for f in file_dir_list:
		if (os.path.isdir(f)):
			if 	(f.split("/")[-1] != "sim"): 
				file_list += _get_file_recursively(f) 
		elif (os.path.isfile(f)):
			if f.endswith(".v"):
				file_list.append(f)

	return file_list

