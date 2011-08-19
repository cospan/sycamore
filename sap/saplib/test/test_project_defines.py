import unittest
from gen import Gen
import os
from inspect import isclass
import json
import saputils

class Test (unittest.TestCase):
	"""Unit test for gen_drt.py"""

	def setUp(self):
		self.gen = None
		self.gen_module = __import__("gen_project_defines")
		self.tags = {}
		for name in dir (self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				print "found" + name
		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/example_project/example1.json"
			filein = open(filename)
			filestr = filein.read()
			self.tags = json.loads(filestr)
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)

		return

	def test_gen_project_defines(self):
		#open the io_handler
		ioh_buf = ""
		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/bus/project_defines.v"
			infile = open(filename)
			ioh_buf = infile.read()
			infile.close()

		except IOError as err:
			print "File Error: " + str(err)

		result = self.gen.gen_script(tags = self.tags, buf=ioh_buf, debug = True)
#		print "out_buf: \n" + result
		self.assertEqual(len(result) > 0, True)


if __name__ == "__main__":
	unittest.main()

