import unittest
import saputils
import os

class Test (unittest.TestCase):
	"""Unit test for saputils"""

	def test_create_dir(self):
		"""create a directory"""
		result = saputils.create_dir("~/sandbox/projects")
		self.assertEqual(result, True)
	
	def test_open_linux_file(self):
		"""try and open a file with the ~ keyword"""
		try: 
			myfile = saputils.open_linux_file("~/sandbox/README")
			myfile.close()
		except:
			self.assertEqual(True, False)
			return
		self.assertEqual(True, True)
	
	def test_read_slave_tags(self):
		"""try and extrapolate all info from the slave file"""
		base_dir = os.getenv("SAPLIB_BASE")	
		filename = base_dir + "/data/hdl/rtl/wishbone/slave/simple_gpio/simple_gpio.v"
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

	def test_remove_comments(self):
		"""try and remove all comments from a buffer"""
		bufin = "not comment /*comment\n\n*/\n\n//comment\n\n/*\nabc\n*/soemthing//comment"
		#print "input buffer:\n" + bufin
		output_buffer = saputils.remove_comments(bufin)
		#print "output buffer:\n" + bufout
		
		self.assertEqual(len(output_buffer) > 0, True)
			
	def test_find_rtl_file_location(self):
		"""give a filename that should be in the RTL"""

		result = saputils.find_rtl_file_location("simple_gpio.v")
		#print "file location: " + result
		try:
			testfile = open(result)
			result = True
			testfile.close()
		except:
			result = Fail

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

if __name__ == "__main__":
	unittest.main()
