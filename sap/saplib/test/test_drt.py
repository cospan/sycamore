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
		self.gen_module = __import__("gen_drt")
		for name in dir (self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				print "found" + name
		return


	def test_gen_drt(self):
		"""generate a drt ROM file"""
		tags = {}
		drt_buffer = ""
		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/example_project/example1.json"
			filein = open(filename)
			filestr = filein.read()
			tags = json.loads(filestr)

		except IOError as err:
			print "File Error: " + str(err)

		result = self.gen.gen_script(tags, buf = "", debug = False)
#		print result
		self.assertEqual(len(result) > 0, True)


if __name__ == "__main__":
	unittest.main()
