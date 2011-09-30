#gen_drt.py
from gen import Gen
import saputils
from string import Template
from string import atoi


class GenDRT(Gen):
	"""Generate the DRT ROM"""

	def __init__(self):
		print "in GenDRT"
		return


	def gen_script(self, tags = {}, buf = "", debug = True):
		out_buf = ""

		#Get the DRT version from the DRT info
		version = 0x0001
		version_string = "{0:0=4X}"
		version_string = version_string.format(version)
		id	= 0x1EAF
		id_string = "{0:0=4X}"
		id_string = id_string.format(id)
		#add 1 for the DRT
		number_of_devices = len(tags["SLAVES"])
		num_dev_string = "{0:0=8X}"
		num_dev_string = num_dev_string.format(number_of_devices)

		out_buf = version_string + id_string + "\n"
		out_buf = out_buf + num_dev_string + "\n" 
		out_buf = out_buf + "00000000" + "\n"
		out_buf = out_buf + "00000000" + "\n"

		if debug:
			print "Number of slaves: " + str(len(tags["SLAVES"]))
		for i in range (0, len(tags["SLAVES"])):
			name = tags["SLAVES"][i]
			absfilename = saputils.find_rtl_file_location(name)
			slave_keywords = [
				"DRT_ID",
				"DRT_FLAGS",
				"DRT_SIZE"
			]
			if debug:
				print "filename: " + absfilename
			local_debug = debug

			slave_tags = saputils.get_module_tags(filename = absfilename, bus = "wishbone", keywords = slave_keywords, debug=local_debug)

			drt_id_buffer = "{0:0=8X}"
			drt_flags_buffer = "{0:0=8X}"
			drt_offset_buffer = "{0:0=8X}"
			drt_size_buffer = "{0:0=8X}"

			offset = 0x01000000 * (i + 1)
			for item in slave_tags["keywords"].keys():
				if debug:
					print "keywords" + item + ":" + slave_tags["keywords"][item]
			drt_id_buffer = drt_id_buffer.format(atoi(slave_tags["keywords"]["DRT_ID"]))
			drt_flags_buffer = drt_flags_buffer.format(atoi(slave_tags["keywords"]["DRT_FLAGS"]))
			drt_offset_buffer = drt_offset_buffer.format(offset)
			drt_size_buffer = drt_size_buffer.format(atoi(slave_tags["keywords"]["DRT_SIZE"]))

			out_buf = out_buf + drt_id_buffer + "\n"
			out_buf = out_buf + drt_flags_buffer + "\n"
			out_buf = out_buf + drt_offset_buffer + "\n"
			out_buf = out_buf + drt_size_buffer + "\n"



		return out_buf 

	def gen_name(self):
		print "generate a ROM"
