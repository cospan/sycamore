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
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		#self.gen = gen_mem_interconnect.GenMemInterconnect()

	def test_gen_mem_interconnect (self):
		"""Generate an actual interconnect file"""
		interconnect_buffer = ""
		tags = {"MEMORY":{
						"memory1":{
							"filename":"wb_bram.v"
						}, 
						"memory2":{
							"filename":"wb_bram.v"
						}
					}
				}
		try:
			filename = os.getenv("SAPLIB_BASE") + "/hdl/rtl/wishbone/interconnect/wishbone_mem_interconnect.v"
			filein = open(filename)
			interconnect_buffer = filein.read()
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)

#		print "buf: " + interconnect_buffer
		self.gen_module = __import__("gen_mem_interconnect")
		for name in dir(self.gen_module):
			obj = getattr(self.gen_module, name)
			if isclass(obj) and issubclass(obj, Gen) and obj is not Gen:
				self.gen = obj()
#				print "found " + name
				
		#self.gen = self.gen_module.Gen()
		result = self.gen.gen_script(tags, buf = interconnect_buffer)

		#write out the file
		try:
			filename = os.getenv("HOME") + "/sandbox/wishbone_mem_interconnect.v"
			fileout = open(filename, "w")
			fileout.write(result)
		except IOError as err:
			print "File Error: " + str(err)

#		print result
		self.assertEqual(len(result) > 0, True)
			


if __name__ == "__main__":
	unittest.main()
