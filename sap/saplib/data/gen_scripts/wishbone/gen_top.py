from gen import Gen
from string import Template

class GenTop(Gen):
	"""Generate the top module for a project"""

	def __init__(self):
		print "in GenTop"
		return

	def gen_script (self, tags = {}, buf = "", debug = False):
		"""Generate the Top Module"""
		slave_list = []
		template = Template(buf)

		#declare the ports
		#in the future utilize the constraints to generate the connections

		#for the FPGA
			#constraints can be a dictionary with the mappings from device
			#to input/output/inout multidimensional values

#this should just be file with text that I can pull in, it will always be
#the same!
		#instantiate the connection interface
			#should this be another script that is clled within here?
			#can I extrapolate the required information directly from the
			#file?

		#instantiate the input handler
		#instantiate the output handler


		#instantiate the wishbone master
#will the master always be the same???, I could have a separate bus just for memory???

		#instantiate the wishbone interconnect
#I can use the number of slaves to generate the interface to this

		#instantiate all the slaves
#I might have to probe each of the slaves... it may not be that difficult
#all I will have to do is read any "input" "output" or "inout" lines and figure out how to read the names, and bus widths... for the most part they are all wires
		return ""

	def get_name (self):
		print "generate top!"
