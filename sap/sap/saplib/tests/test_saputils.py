import unittest
import sys
import os

class Test (unittest.TestCase):
	"""Unit test for saputils"""

	def setUp(self):
	
		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		#print "SAPLIB_BASE: " + os.getenv("SAPLIB_BASE")


	def test_create_dir(self):
		"""create a directory"""
		import saputils
		result = saputils.create_dir("~/sandbox/projects")
		self.assertEqual(result, True)
	

	def test_remove_comments(self):
		"""try and remove all comments from a buffer"""
		import saputils
		bufin = "not comment /*comment\n\n*/\n\n//comment\n\n/*\nabc\n*/soemthing//comment"
		#print "input buffer:\n" + bufin
		output_buffer = saputils.remove_comments(bufin)
		#print "output buffer:\n" + bufout
		
		self.assertEqual(len(output_buffer) > 0, True)
			
	def test_find_rtl_file_location(self):
		"""give a filename that should be in the RTL"""

		import saputils
		result = saputils.find_rtl_file_location("simple_gpio.v")
		#print "file location: " + result
		try:
			testfile = open(result)
			result = True
			testfile.close()
		except:
			result = False

		self.assertEqual(result, True)

	def test_resolve_linux_path(self):
		"""given a filename with or without the ~ return a filename with the ~ expanded"""
		import saputils
		filename1 = "/filename1"
		filename = saputils.resolve_linux_path(filename1)
		#print "first test: " + filename
		#if (filename == filename1):
	#		print "test1: they are equal!"
		self.assertEqual(filename == "/filename1", True)

		filename2 = "~/filename2"
		filename = saputils.resolve_linux_path(filename2)
		correct_result = os.path.expanduser("~") + "/filename2"
		#print "second test: " + filename + " should equal to: " + correct_result
		#if (correct_result == filename):
	#		print "test2: they are equal!"
		self.assertEqual(correct_result == filename, True)

		filename = filename.strip()

	
	def test_read_slave_tags(self):
		"""try and extrapolate all info from the slave file"""
		import saputils
		base_dir = os.getenv("SAPLIB_BASE")	
		filename = base_dir + "/hdl/rtl/wishbone/slave/simple_gpio/simple_gpio.v"
		drt_keywords = [
			"DRT_ID",
			"DRT_FLAGS",
			"DRT_SIZE"
		]
		tags = saputils.get_module_tags(filename, keywords = drt_keywords, debug = False)

		io_types = [
			"input",
			"output",
			"inout"
		]
		#
		#for io in io_types:
		#	for port in tags["ports"][io].keys():
		#		print "Ports: " + port

		self.assertEqual(True, True)

	def test_read_slave_tags_with_params(self):
		"""some verilog files have a paramter list"""
		import saputils
		base_dir = os.getenv("SAPLIB_BASE")
		filename = base_dir + "/hdl/rtl/wishbone/slave/ddr/wb_ddr.v"
		drt_keywords = [
			"DRT_ID",
			"DRT_FLAGS",
			"DRT_SIZE"
		]
		tags = saputils.get_module_tags(filename, keywords = drt_keywords, debug = True)

		io_types = [
			"input",
			"output",
			"inout"
		]
		#
		#for io in io_types:
		#	for port in tags["ports"][io].keys():
		#		print "Ports: " + port

		print "\n\n\n\n\n\n"
		print "module name: " + tags["module"]
		print "\n\n\n\n\n\n"

		self.assertEqual(True, True)


	
	def test_read_hard_slave_tags(self):
		"""try and extrapolate all info from the slave file"""
		import saputils
		base_dir = os.getenv("SAPLIB_BASE")	
		filename = base_dir + "/hdl/rtl/wishbone/slave/ddr/wb_ddr.v"
		drt_keywords = [
			"DRT_ID",
			"DRT_FLAGS",
			"DRT_SIZE"
		]
		tags = saputils.get_module_tags(filename, keywords = drt_keywords, debug = True)

		io_types = [
			"input",
			"output",
			"inout"
		]
		#
		#for io in io_types:
		#	for port in tags["ports"][io].keys():
		#		print "Ports: " + port

		self.assertEqual(True, True)




if __name__ == "__main__":
	sys.path.append (sys.path[0] + "/../")
	import saputils
	unittest.main()
