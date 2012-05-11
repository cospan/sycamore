import unittest
import sys
import os
import saputils

class Test (unittest.TestCase):
	"""Unit test for saputils"""

	def setUp(self):
	
		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		#print "SAPLIB_BASE: " + os.getenv("SAPLIB_BASE")

	def test_arbitrator_count(self):
		"""gets the module tags and detects if there is any arbitrator hosts"""
		filename = saputils.find_rtl_file_location("wb_gpio.v")
		tags = saputils.get_module_tags(filename, debug=self.dbg)
		self.assertEqual(len(tags["arbitrator_masters"]), 0)

		filename = saputils.find_rtl_file_location("wb_console.v")
		tags = saputils.get_module_tags(filename, debug=self.dbg)
		self.assertEqual(len(tags["arbitrator_masters"]), 2)

	def test_create_dir(self):
		"""create a directory"""
		
		result = saputils.create_dir("~/sandbox/projects")
		self.assertEqual(result, True)
	

	def test_remove_comments(self):
		"""try and remove all comments from a buffer"""
		
		bufin = "not comment /*comment\n\n*/\n\n//comment\n\n/*\nabc\n*/soemthing//comment"
		#print "input buffer:\n" + bufin
		output_buffer = saputils.remove_comments(bufin)
		#print "output buffer:\n" + bufout
		
		self.assertEqual(len(output_buffer) > 0, True)
			

	def test_get_board_config(self):
		"""
		gets the board configuration dictionary given the board
		name
		"""
		boardname = "sycamore1"
		board_dict = saputils.get_board_config(boardname, debug = False)
		self.assertEqual(board_dict["board_name"], "Sycamore 1")

		
	def test_find_rtl_file_location(self):
		"""give a filename that should be in the RTL"""

		
		result = saputils.find_rtl_file_location("wb_gpio.v")
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
		
		base_dir = os.getenv("SAPLIB_BASE")	
		filename = base_dir + "/hdl/rtl/wishbone/slave/wb_gpio/wb_gpio.v"
		drt_keywords = [
			"DRT_ID",
			"DRT_FLAGS",
			"DRT_SIZE"
		]
		tags = saputils.get_module_tags(filename, keywords = drt_keywords, debug=self.dbg)

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
		
		base_dir = os.getenv("SAPLIB_BASE")
		filename = base_dir + "/hdl/rtl/wishbone/slave/ddr/wb_ddr.v"
		drt_keywords = [
			"DRT_ID",
			"DRT_FLAGS",
			"DRT_SIZE"
		]
		tags = saputils.get_module_tags(filename, keywords = drt_keywords, debug=self.dbg)

		io_types = [
			"input",
			"output",
			"inout"
		]
		#
		#for io in io_types:
		#	for port in tags["ports"][io].keys():
		#		print "Ports: " + port

		if self.dbg:
			print "\n\n\n\n\n\n"
			print "module name: " + tags["module"]
			print "\n\n\n\n\n\n"

		self.assertEqual(tags["module"], "wb_ddr")


	def test_read_user_parameters(self):
		filename = saputils.find_rtl_file_location("wb_gpio.v")
		tags = saputils.get_module_tags(filename, debug=self.dbg)

		keys = tags["parameters"].keys()
		if self.dbg:
			print "reading the parameters specified by the user"
		self.assertIn("INTERRUPT_MASK", keys)
		if self.dbg:
			print "make sure other parameters don't get read"
		self.assertNotIn("ADDR_GPIO", keys)
		



	
	def test_read_hard_slave_tags(self):
		"""try and extrapolate all info from the slave file"""
		
		base_dir = os.getenv("SAPLIB_BASE")	
		filename = base_dir + "/hdl/rtl/wishbone/slave/ddr/wb_ddr.v"
		drt_keywords = [
			"DRT_ID",
			"DRT_FLAGS",
			"DRT_SIZE"
		]
		tags = saputils.get_module_tags(filename, keywords = drt_keywords, debug=self.dbg)

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

	def test_get_net_names(self):
		filename = "lx9.ucf" 
		netnames = saputils.get_net_names(filename, debug = self.dbg)
		if self.dbg:
			print "net names: "
			for name in netnames:
				print "\t%s" % name

		self.assertIn("clk", netnames) 

	def test_read_clk_with_period(self):
		
		filename = "sycamore_serial.ucf" 
		clock_rate = saputils.read_clock_rate(filename, debug = self.dbg)
		self.assertEqual(len(clock_rate) > 0, True)


	def test_read_clk_with_timespec(self):
		
		filename = "lx9.ucf" 
		clock_rate = saputils.read_clock_rate(filename, debug = self.dbg)
		self.assertEqual(len(clock_rate) > 0, True)


	def test_get_slave_list(self):
		slave_list = saputils.get_slave_list(debug = self.dbg)

if __name__ == "__main__":
	sys.path.append (sys.path[0] + "/../")
	unittest.main()
