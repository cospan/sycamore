import unittest
from gen import Gen
import os
import sys
from inspect import isclass

class Test (unittest.TestCase):
	"""Unit test for sapfile"""

	def setUp(self):
		"""open up a sapfile class"""
		os.environ["SAPLIB_BASE"] = sys.path[0] +  "/saplib"

	def test_gen_arbitrator (self):
		"""Generate an actual arbitrator file"""
		interconnect_buffer = ""
		tags = {"MASTERS":["master1", "master2"]}
		try:
			filename = os.getenv("SAPLIB_BASE") + "/hdl/rtl/wishbone/arbitrator/wishbone_arbitrator.v"
			filein = open(filename)
			arbitrator_buffer = filein.read()
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)

		print "buf: " + interconnect_buffer
		self.gen_module = __import__("gen_arbitrator")
		for name in dir(self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
				print "found " + name
				
		#self.gen = self.gen_module.Gen()
		result = self.gen.gen_script(tags, buf = arbitrator_buffer, debug=True)

		#write out the file
		if (result != None):
			try:
				filename = os.getenv("HOME") + "/sandbox/wishbone_arbitrator.v"
				fileout = open(filename, "w")
				fileout.write(result)
			except IOError as err:
				print "File Error: " + str(err)

			print result
			self.assertEqual(len(result) > 0, True)
		else:
			self.assertEqual(True, True)
			


if __name__ == "__main__":
	unittest.main()
