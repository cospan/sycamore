import unittest
from gen import Gen
import os
from inspect import isclass

class Test (unittest.TestCase):
	"""Unit test for the gen_top.v"""

	def setUp(self):
		return

	def test_gen_top(self):
		"""generate a top.v file"""
		self.gen = None
		
		top_buffer = ""
		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/hdl/rtl/wishbone/wishbone_top.v"
			filein = open(filename)
			top_buffer = filein.read()
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)
			self.assertEqual(False, True)

		print "buf: " + top_buffer
		self.gen_module = __import__("gen_top")
		for name in dir(self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				print "found " + name

		tags = {}
		result = self.gen.gen_script(tags, buf = top_buffer, debug=True)
		self.assertEqual(len(result) > 0, True)

if __name__ == "__main__":
	unittest.main()
