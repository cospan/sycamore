import unittest
import sys
import os
import xilinxutils

class Test (unittest.TestCase):
	"""Unit test for saputils"""

	def setUp(self):
	
		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		#print "SAPLIB_BASE: " + os.getenv("SAPLIB_BASE")

	def test_get_version_list(self):
		"""
		returns a list of the version on this computer
		"""
		#get a list of the version on this computer
		versions = xilinxutils.get_version_list(base_directory = None, 
												debug = self.dbg)

		self.assertIsNotNone(versions)	

	def test_get_supported_version(self):
		"""
		gets the correct version of the Xilnx toolchain to use
		"""

		#give two different versions of the toolchain
		versions = [14.1, 13.4]
		v = xilinxutils.get_supported_version(	"xc6slx9csg324-2", 
												versions, 
												debug = self.dbg)

		if self.dbg:
			print "Version for Spartan/Virtex 6: %f" % v
		self.assertEqual(v, 14.1)
		v = xilinxutils.get_supported_version(	"xc3s500efg320", 
												versions, 
												debug = self.dbg)
		if self.dbg:
			print "Version for Spartan 3: %f" % v
		self.assertEqual(v, 13.4)

if __name__ == "__main__":
	sys.path.append (sys.path[0] + "/../")
	unittest.main()
