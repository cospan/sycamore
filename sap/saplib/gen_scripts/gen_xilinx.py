#gen xilinx_gen.py

from gen import Gen
import saputils
from string import Template
from string import atoi

class GenXilnx(Gen):
	"""
	Generate the Xilnx Build script
	"""

	def __init__(self):
		#print "in GenXilnx"
		return

	def gen_script(self, tags = {}, buf = "", debug = False):
		"""
		Need to do a replace, but due to the {} in the script file it
		doesn't make sense to use the template
		"""
		board_dict = saputils.get_board_config(tags["board"])
		fpga_pn = board_dict["fpga_part_number"]
	
		out_buf = ""

		if (len(buf.partition("set projName")[2]) > 0):
			temp_pre = buf.partition("set projName")[0] + "set projName"
			temp_buf = buf.partition("set projName")[2]	

			out_buf = temp_pre + " " + tags["PROJECT_NAME"] + "\n" + temp_buf.partition("\n")[2]


		#add the device
		if (len(buf.partition("set device")[2]) > 0):
			temp_pre = buf.partition("set device")[0] + "set device"
			temp_buf = buf.partition("set device")[2]

			
			out_buf = temp_pre + " " + fpga_pn + "\n" + temp_buf.partition("\n")[2]

		return out_buf

		
			
		

	def gen_name(self):
		print "generate a Xilnx Generate project"
