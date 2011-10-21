import unittest
from gen import Gen
import os
import sys
from inspect import isclass
import json
import saputils

class Test (unittest.TestCase):
	"""Unit test for gen_drt.py"""


	def setUp(self):
		self.gen = None
		self.gen_module = __import__("gen_drt")
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		#print "debug: " + str(self.dbg)

		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		for name in dir (self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				if (self.dbg == True):
					print "found " + name


		return


#	def test_gen_drt(self):
#		"""generate a drt ROM file"""
#		tags = {}
#		drt_buffer = ""
#		try:
#			filename = os.getenv("SAPLIB_BASE") + "/example_project/example1.json"
#			filein = open(filename)
#			filestr = filein.read()
#			tags = json.loads(filestr)
#
#		except IOError as err:
#			print "File Error: " + str(err)
#
#		result = self.gen.gen_script(tags, buf = "", debug = self.dbg)
##		print result
#		self.assertEqual(len(result) > 0, True)

	def test_gen_drt_v2(self):
		"""generate a drt ROM file"""
		tags = {}
		drt_buffer = ""
		try:
			filename = os.getenv("SAPLIB_BASE") + "/example_project/gpio_v2.json"
			filein = open(filename)
			filestr = filein.read()
			tags = json.loads(filestr)

		except IOError as err:
			print "File Error: " + str(err)

		result = self.gen.gen_script(tags, buf = "", debug = self.dbg)
#		print result
		self.assertEqual(len(result) > 0, True)



if __name__ == "__main__":
	unittest.main()
