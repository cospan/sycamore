import os
import sys
import string
import glob
import json


"""
Xilinx specific utilities
"""

"""
Changes:
5/21/2012
	-Initial commit

"""


def get_version_list(base_directory = None, debug=False):
	"""
	Returns a list of version of the Xilinx toolchain

	if the user does not specify the base_directory
	the default /opt will be used
	"""

	if base_directory is None:
		base_directory = "/opt"

	if debug:
		print "searching in %s..." % (base_directory)
	dir_list = glob.glob(base_directory + "/*")
	dirs = []
	versions = None
	for d in dir_list:
		if "Xilinx" in d:
			dirs = glob.glob(d + "/*")
			versions = []
			for v in dirs:
				versions.append(float(v.rpartition("/")[2]))	
				break

	if debug:
		print "versions: " + str(versions)
	return versions


def get_supported_version(fpga_part_number, versions, debug = False):
	"""
	using an FPGA number, determine if the FPGA is a 
	Spartan 3 or a Spartan 6

	based off of the fpga_part_number determine what version
	should be used to build the design

	Spartan 3 < 14.0
	Spartan 6 >= 12.0
	"""

	pn = fpga_part_number
	#strip off the first two characters
	pn = pn[2:]
	num = 0
	length = len(pn)
	i = 0
	for i in range (0, length): 
		if pn[i].isdigit():
			i += 1	
		else:
			break

	num = int(pn[0:i])
	if debug:
		print "FPGA number: %d" % num

	versions.sort()
	if len(versions) == 0:
		raise Exception("no Versions of Xilinx Toolchain")
	
	if num == 6:
		#return the largest version
		return versions[-1]	

	if num == 3:
		for i in range (0, len(versions)):
			if versions[-1 - i] < 14.0:
				return versions[-1 - i]

	raise Exception("FPGA Number %d not supported yet!" % num)

		
	

