import unittest
from gen import Gen
import os
import sys
from inspect import isclass
import json
import saputils

class Test (unittest.TestCase):
	"""Unit test for gen_xilinx.py"""

	def setUp(self):
		self.gen = None
		self.gen_module = __import__("gen_xilinx")
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		for name in dir (self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
#				print "found " + name
		return

	def test_xilinx_gen(self):
		"""generate a xilinx generate script"""
		tags = {}
		xbuf = ""
		try:
			filename = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"
			filein = open(filename)
			filestr = filein.read()
			tags = json.loads(filestr)

		except IOError as err:
			print "File Error: " + str (err)
			self.assertEquals(True, False)

		try:
			filename = os.getenv("SAPLIB_BASE") + "/tool_scripts/xilinx/project_gen.tcl"
			filein = open(filename)
			xbuf = filein.read()
		except IOError as err:
			print "File Error: " + str (err)
			self.assertEquals(True, False)

		result = self.gen.gen_script(tags, buf = xbuf) 
#		print "out buf: " + result
		self.assertEquals(len(result) > 0, True)
		return


if __name__ == "__main__":
	unittest.main()


