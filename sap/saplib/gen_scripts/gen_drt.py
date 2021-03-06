#gen_drt.py
from gen import Gen
import saputils
from string import Template
from string import atoi

"""
Changes:

12/13/2011
	-Changed the response from 25 characters to 32
12/02/2011
	-Changed the DRT size from 4 to 8
"""


class GenDRT(Gen):
	"""Generate the DRT ROM"""

	def __init__(self):
		#print "in GenDRT"
		return


	def gen_script(self, tags = {}, buf = "", debug = False):
		out_buf = ""

		#Get the DRT version from the DRT info
		version = 0x0004
		version_string = "{0:0=4X}"
		version_string = version_string.format(version)
		id	= 0x1EAF
		id_string = "{0:0=4X}"
		id_string = id_string.format(id)
		#add 1 for the DRT
		number_of_devices = 0
		#number_of_devices = 1
		number_of_devices += len(tags["SLAVES"])

		if debug:
			print "number of slaves: " + str(number_of_devices)

		if ("MEMORY" in tags):
			if debug:
				print "num of mem devices: " + str(len(tags["MEMORY"]))
			number_of_devices += len(tags["MEMORY"])

		if debug:
			print "number of entities: " + str(number_of_devices)
		num_dev_string = "{0:0=8X}"
		num_dev_string = num_dev_string.format(number_of_devices)

		#header
		out_buf = version_string + id_string + "\n"
		out_buf += num_dev_string + "\n" 
		out_buf += "00000000" + "\n"
		out_buf += "00000000" + "\n"
		out_buf += "00000000" + "\n"
		out_buf += "00000000" + "\n"
		out_buf += "00000000" + "\n"
		out_buf += "00000000" + "\n"



		#peripheral slaves
		for i in range (0, len(tags["SLAVES"])):
			key = tags["SLAVES"].keys()[i]
			name = tags["SLAVES"][key]["filename"]
			absfilename = saputils.find_rtl_file_location(name)
			slave_keywords = [
				"DRT_ID",
				"DRT_FLAGS",
				"DRT_SIZE"
			]
			slave_tags = saputils.get_module_tags(filename = absfilename, bus = "wishbone", keywords = slave_keywords)

			drt_id_buffer = "{0:0=8X}"
			drt_flags_buffer = "{0:0=8X}"
			drt_offset_buffer = "{0:0=8X}"
			drt_size_buffer = "{0:0=8X}"

			offset = 0x01000000 * (i + 1)
			drt_id_buffer = drt_id_buffer.format(atoi(slave_tags["keywords"]["DRT_ID"].strip()))
			drt_flags_buffer = drt_flags_buffer.format(0x00000000 + atoi(slave_tags["keywords"]["DRT_FLAGS"]))
			drt_offset_buffer = drt_offset_buffer.format(offset)
			drt_size_buffer = drt_size_buffer.format(atoi(slave_tags["keywords"]["DRT_SIZE"]))

			out_buf += drt_id_buffer + "\n"
			out_buf += drt_flags_buffer + "\n"
			out_buf += drt_offset_buffer + "\n"
			out_buf += drt_size_buffer + "\n"
			out_buf += "00000000\n"
			out_buf += "00000000\n"
			out_buf += "00000000\n"
			out_buf += "00000000\n"


		#memory slaves
		if ("MEMORY" in tags):
			mem_offset = 0
			for i in range (0, len(tags["MEMORY"])):
				key = tags["MEMORY"].keys()[i]
				name = tags["MEMORY"][key]["filename"]
				absfilename = saputils.find_rtl_file_location(name)
				slave_keywords = [
					"DRT_ID",
					"DRT_FLAGS",
					"DRT_SIZE"
				]
				slave_tags = saputils.get_module_tags(filename = absfilename, bus = "wishbone", keywords = slave_keywords)

				drt_id_buffer = "{0:0=8X}"
				drt_flags_buffer = "{0:0=8X}"
				drt_offset_buffer = "{0:0=8X}"
				drt_size_buffer = "{0:0=8X}"
#add the offset from the memory
				drt_id_buffer = drt_id_buffer.format(atoi(slave_tags["keywords"]["DRT_ID"]))
				drt_flags_buffer = drt_flags_buffer.format(0x00010000 +  atoi(slave_tags["keywords"]["DRT_FLAGS"]))
				drt_offset_buffer = drt_offset_buffer.format(mem_offset)
				drt_size_buffer = drt_size_buffer.format(atoi(slave_tags["keywords"]["DRT_SIZE"]))
				mem_offset += atoi(slave_tags["keywords"]["DRT_SIZE"]) 

				out_buf += drt_id_buffer + "\n"
				out_buf += drt_flags_buffer + "\n"
				out_buf += drt_offset_buffer + "\n"
				out_buf += drt_size_buffer + "\n"
				out_buf += "00000000\n"
				out_buf += "00000000\n"
				out_buf += "00000000\n"
				out_buf += "00000000\n"


		return out_buf 

	def gen_name(self):
		print "generate a ROM"
