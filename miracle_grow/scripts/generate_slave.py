#! /usr/bin/python
#generate_script


import os
import sys
import glob
import getopt
import shutil
import string


def read_wb_slave_template_file(filename=""):
	template_file_string = ""
	#try:
	#	#open the template file at the default location and read location
	#except:
	#	print "Couldn't find template file"
	return template_file_string


def usage():
	"""prints out a helpful message to the user"""
	print "Sets a new wishbone slave along with the environment to simulate and"
	print "and test it"
	print ""
	print "usage: generate_slave.py [options] <slave name>"
	print ""
	print "slave name: the name of the wishbone slave to generate"
	print "NOTE: if the options flags for the DRT are not specified on"
	print "\t the command line then they must manually be set in the file"
	print ""
	print "options:"
	print "-h\t--help\t\t\t: displays this help"
	print "-v\t--verbose\t\t: print out lots of info"
	print "-d\t--debug\t\t\t: configures modules to perform things through debug"
	print "\t--id\t\t\t: the DRT device (Hexidecimal number)"
	print "\t--flags\t\t\t: DRT flags (Hexidecimal number)"
	print "\t--size\t\t\t: Size of the slave in memory (Hexidecimal number)"
	print ""
	print "Setting the DRT meta data manually"
	print "in the generated file set the 3 variables requred by sycamore"
	print "DRT_ID: the identification number of the slave device see"
	print "\t<sycamore base>/miracle_grow/rtl/wishbone/slave/device_rom_table/drt.txt"
	print "\tfor ID numbers, and their meaning"
	print "DRT_FLAGS: the flags that help identify how the slave should be used"
	print "\tsee drt.txt for more info"
	print "DRT_SIZE: the number of register/memory locations available for the"
	print "\t slave"
	print ""
	print "example:"
	print "generate_slave.py --id=1 --flags=1 --size=3 gpio"
	print ""
	print "\tgenerate two folders:"
	print "\tthe actual slave folder: <sycamore>/miracle_grow/rtl/wishbone/slave/gpio"
	print "\tsimulation/test folder: <sycamore>/miralce_grow/sim/wishbone/slave/gpio"
	print "\tslave name: gpio"
	print "\tDRT_ID: 1"
	print "\tDRT_FLAGS: 1"
	print "\tDRT_SIZE: 3"
	print ""


def slave_exists(slave_dir = "", slave_name = ""):
	"""Check if the slave directory exists"""
	file_list = glob.glob(slave_dir)	
	for f in file_list:
		if (_verbose):
			print "found: " + f
		if (os.path.isdir(f)):
			if (_verbose):
				print "\t is a directory"
				print "\t directory name: " + f.split("/")[-1]
			if (f.split("/")[-1] == slave_name):
				return True
	return False

def remove_slave_dir(mg_path = "", slavename = ""):
	"""remove the slave rtl and sim dir (mostly for debugging)"""
	if (os.path.exists(mg_path + "/rtl/wishbone/slave/" + slavename)):
		try:
			shutil.rmtree(mg_path + "/rtl/wishbone/slave/" + slavename)
		except shutil.error, err:
			print "no files in that slave rtl direcotry"

	if (os.path.exists(mg_path + "/sim/wishbone/slave/" + slavename)):
		try:
			shutil.rmtree(mg_path + "/sim/wishbone/slave/" + slavename)
		except shutil.error, err:
			print "no files in that slave sim direcotry"

	

if __name__=="__main__":
	#assume we are in <sycamore>/miragle_grow/scripts
	global _verbose 
	global _debug
	global _kill

	_verbose = False
	_debug = False
	_kill = False

	cl_id_en = False
	cl_id = 0
	cl_flags_en = False
	cl_flags = 0
	cl_size_en = False
	cl_size = 0

	mg_path = os.path.realpath(sys.path[0] + "/..")

	args = sys.argv[1:]
	if (len(args) == 0):
		usage()
		sys.exit(1)
	else:
		try:
			opts, args = getopt.getopt(args, "hvdk", ["help", "verbose", "debug", "id=", "flags=", "size=", "kill"])
		except getopt.GetoptError, err:
			print(err)
			usage()
			sys.exit(2)
		
		for opt, arg in opts:
			if opt in ("-h", "--help"):
				usage()
				sys.exit()
			elif opt in ("-v", "--verbose"):
				print "Verbose flag enabled"
				_verbose = True
			elif opt in ("-d", "--debug"):
				print "Debug flag enabled"
				_debug = True
			elif opt in ("--id"):
				print "Setting DRT_ID to " + str(arg)
				cl_id = string.atoi(arg, 16)
				cl_id_en = True
			elif opt in ("--flags"):
				print "Setting DRT_FLAGS to " + str(arg)
				cl_flags = string.atoi(arg, 16)
				cl_flags_en = True
			elif opt in ("--size"):
				print "Setting DRT_SIZE to " + str(arg)
				cl_size = string.atoi(arg, 16)
				cl_size_en = True
			elif opt in ("-k", "--kill"):
				print "removing dir"
				_kill = True


		if (len (args) == 0):
			print ""
			print "no slaves to process"
			usage()
			sys.exit(1)

		else:
			for slavename in args:
				if _verbose:
					print "processing " + slavename
				#check if the slave name exists
				if (slave_exists(mg_path + "/rtl/wishbone/slave/*", slavename)):
					if (_kill):
						remove_slave_dir(mg_path, slavename)
						sys.exit(0)
					print "slave " + slavename + " already exists"
					sys.exit(3)
				else:
					if (_kill):
						print "nothing to remove"
						sys.exit(0)
			

	rtl_path = mg_path + "/rtl/wishbone/slave/" + slavename
	sim_path = mg_path + "/sim/wishbone/slave/" + slavename


	if (_debug):
		print "rtl_dir: " + rtl_path
		print "sim_dir: " + sim_path
	#generate a folder structure in the rtl/wishbone/slave/<slave_name>
	print "Generating: " + mg_path + "/rtl/wishbone/slave/" + slavename
	if (not os.path.exists(rtl_path)):
		try:
			os.makedirs(rtl_path)
		except os.error:
			print "Error: failed to create rtl directory"
	

	#read in the wishbone slave template in as a string
	slave_string = ""
	try:
		f = open(mg_path + "/rtl/wishbone/slave/wishbone_slave_template.v")
		slave_string = f.read()
		f.close()
	except IOError, err:
		print "File Error: " + str(err)
		sys.exit(4)

	while ("wishbone_slave_template" in slave_string):
		pre  = slave_string.partition("wishbone_slave_template")[0]
		post = slave_string.partition("wishbone_slave_template")[2]
		slave_string = pre + slavename + post
		#if the user inputed any of the meta data on the command line
		#enter it here
		if (cl_id_en):
			if (_debug):
				print "Setting the DRT_ID to " + str(cl_id)
			pre = slave_string.partition("DRT_ID:")[0]	
			pre = pre + ("DRT_ID: ")
			post = slave_string.partition("DRT_ID:")[2]
			post = post.partition("\n")[2]
			post = " " + str(cl_id) + "\n" + post
			slave_string = pre + post

		if (cl_flags_en):
			if (_debug):
				print "Setting the DRT_FLAGS to " + str(cl_flags)
			pre = slave_string.partition("DRT_FLAGS:")[0]	
			pre = pre + ("DRT_FLAGS: ")
			post = slave_string.partition("DRT_FLAGS:")[2]
			post = post.partition("\n")[2]
			post = " " + str(cl_flags) + "\n" + post
			slave_string = pre + post

		if (cl_size_en):
			if (_debug):
				print "Setting the DRT_SIZE to " + str(cl_size)
			pre = slave_string.partition("DRT_SIZE:")[0]	
			pre = pre + ("DRT_SIZE: ")
			post = slave_string.partition("DRT_SIZE:")[2]
			post = post.partition("\n")[2]
			post = " " + str(cl_size) + "\n" + post
			slave_string = pre + post


	if (_verbose):
		print "slave buffer: "
		print slave_string

	try: 
		f = open(rtl_path + "/" + slavename + ".v", "w")
		f.write(slave_string)
		f.close()
	except IOError, err:
		print "File Error: " + str(err)

	#generate a folder in the sim/wishbone/slave/<slave_name>
	print "Generating: " + sim_path + "/" + slavename
	if (not os.path.exists(sim_path)):
		try:
			os.makedirs(sim_path)
		except os.error:
			print "Error: failed to create rtl directory"
			sys.exit(4)

	#copy all the sim/wishbone/slave_template files to the new directory
	if (_debug):
		print "copying over files from template:"
	for filename in glob.glob(mg_path + "/sim/wishbone/slave/slave_template/*"):
		if (_debug):
			print filename
			shutil.copyfile(filename, sim_path + "/" + filename.split("/")[-1])

	curdir = os.getcwd()
	if (_debug):
		print "curdir: " + curdir
	os.chdir(rtl_path)
	#generate a symlink to the simulation
	if (_debug):
		print "generating rtl -> sim symlink"
	os.symlink("../../../../sim/wishbone/slave/" + slavename, "sim")
	

	os.chdir(curdir)
	os.chdir(sim_path)
	#generate a sim -> rtl link
	if (_debug):
		print "generating sim -> rtl symlink"
	os.symlink("../../../../rtl/wishbone/slave/" + slavename, "rtl")

	os.chdir(curdir)
	#modify the file_list.txt contents to compile the new slave
	try:
		f = open (sim_path + "/" + "file_list.txt", "r")
		fl_string = f.read()
		f.close()
		pre = fl_string.partition("USER_SLAVE_FILES")[0]
		post = fl_string.partition("USER_SLAVE_FILES")[2]
		fl_string = pre + "rtl/" + slavename + ".v" + post

		f = open (sim_path + "/" + "file_list.txt", "w")
		if (_debug):
			print "writing new file_list.txt"
		f.write(fl_string)
		f.close()
	except IOError, err:
		print "File IO Error: " + str(err)
	#modify the wishbone_master_tb.v to include the RTL slave
	try:
		f = open (sim_path + "/" + "wishbone_master_tb.v", "r")
		fl_string = f.read()
		f.close()
		pre = fl_string.partition("USER_SLAVE")[0]
		post = fl_string.partition("USER_SLAVE")[2]
		fl_string = pre + slavename + post

		f = open (sim_path + "/" + "wishbone_master_tb.v", "w")
		if (_debug):
			print "writing new wishbone_master_tb.v"
		f.write(fl_string)
		f.close()
	except IOError, err:
		print "File IO Error: " + str(err)

