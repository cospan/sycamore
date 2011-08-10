import unittest
from gen import Gen
import os
from inspect import isclass
import json
import saputils

class Test (unittest.TestCase):
	"""Unit test for the gen_top.v"""

	def setUp(self):

		self.gen = None
		self.gen_module = __import__("gen_top")
		for name in dir(self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				print "found " + name

		return

	def test_gen_top(self):
		"""generate a top.v file"""
		self.gen = None
		
		tags = {}
		top_buffer = ""
		#get the example project data
		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/example_project/example1.json"
			filein = open(filename)
			filestr = filein.read()
			tags = json.loads(filestr)

		except IOError as err:
			print "File Error: " + str(err)
			self.assertEqual(False, True)

		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/hdl/rtl/wishbone/wishbone_top.v"
			filein = open(filename)
			top_buffer = filein.read()
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)
			self.assertEqual(False, True)

		#print "buf: " + top_buffer
		self.gen_module = __import__("gen_top")
		for name in dir(self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				print "found " + name

		result = self.gen.gen_script(tags, buf = top_buffer, debug=False)
		print "Top file: \n" + result

		self.assertEqual(len(result) > 0, True)


	def test_generate_buffer_slave(self):
		
		absfilepath = saputils.find_rtl_file_location("simple_gpio.v")
		#print "simple_gpio.v location: " + absfilepath
		slave_keywords = [
			"DRT_ID",
			"DRT_FLAGS",
			"DRT_SIZE"
		]
		tags = saputils.get_module_tags(filename = absfilepath, bus="wishbone", keywords = slave_keywords) 

			

		self.gen.wires = [
			"clk",
			"rst"
		]
		result = self.gen.generate_buffer(name="wbs", index=0, module_tags = tags) 

		buf = result
		#print "out:\n" + buf
		self.assertEqual(len(buf) > 0, True)

	def test_generate_buffer_io_handler(self):

		absfilepath = saputils.find_rtl_file_location("uart_io_handler.v")
		#print "uart_io_handler.v location: " + absfilepath

		tags = saputils.get_module_tags(filename = absfilepath, bus="wishbone") 
		self.gen.wires=[
			"clk",
			"rst"
		]

		result = self.gen.generate_buffer(name = "uio", module_tags = tags) 
		
		buf = result
		#print "out:\n" + buf
		self.assertEqual(len(buf) > 0, True)

if __name__ == "__main__":
	unittest.main()
