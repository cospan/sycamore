#gen_project_defines.py

from gen import Gen
import saputils
from string import Template

class GenProjectDefines(Gen):
	"""Generate the top module for a project"""

	def __init__(self):
		print "in GenProjectDefines"
		return

	def gen_script (self, tags={}, buf="", debug = False):
		"""Generate the project_defines.v"""
	
		if debug:
			print ""
			print ""
			print ""
			print ""
			print ""
			print ""
			print ""
		
		template = Template(buf) 
		vendor_string = "VENDOR_FPGA"

		if (tags["BUILD_TOOL"] == "xilinx"):
			buf = template.safe_substitute(VENDOR_FPGA = "VENDOR_XILINX")
			vendor_string = "VENDOR_XILINX"

		num_of_slaves = str(len(tags["SLAVES"]))
		print "num of slaves: " + str(num_of_slaves)
		buf = template.substitute(PROJECT_NAME = tags["PROJECT_NAME"], NUMBER_OF_DEVICES=num_of_slaves, VENDOR_FPGA=vendor_string)
		return buf


	def get_name(self):
		print "Generate the project defines"


