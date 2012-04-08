import unittest
from saplib import saplib
import os
import sys

class Test (unittest.TestCase):
	"""Unit test for the verilog pre-processor module"""

	def setUp(self):
		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

		return

	def test_generate_define_table(self):
		"""generate a define table given a file"""
		import sappreproc
		import saputils
		filename = saputils.find_rtl_file_location("wb_ddr.v")
		print "filename: " + filename
		filestring = ""
		try:
			f = open(filename)
			print "opened file"
			filestring = f.read()
			f.close()
		except:
			print "Failed to open test filename"
			self.assertEqual(True, False)
			return

		result = sappreproc.generate_define_table(filestring, debug = self.dbg)


		self.assertEqual(len(result) > 0, True)

	def test_resolve_one_define(self):
		"""First test to see if the system will replace a define"""
		import sappreproc	
		import saputils
		#first get the filename
		filename = saputils.find_rtl_file_location("wb_ddr.v")
		filestring = ""
		try:
			f = open(filename)
			filestring = f.read()
			f.close()
		except:
			print "Failed to open test file"
			self.assertEqual(True, False)
			return

		define_dict = sappreproc.generate_define_table(filestring)
		#print "number of defines: " + str(len(define_dict.keys()))
		result = sappreproc.resolve_defines("`WB_ADR_WIDTH", define_dict, debug = self.dbg)

		self.assertEqual(len(result) > 0, True)

	def test_resolve_non_wsp_define(self):
		"""First test to see if the system will replace a define that isn't separated by whitespaces"""
		import sappreproc	
		import saputils
		#first get the filename
		filename = saputils.find_rtl_file_location("wb_ddr.v")
		filestring = ""
		try:
			f = open(filename)
			filestring = f.read()
			f.close()
		except:
			print "Failed to open test file"
			self.assertEqual(True, False)
			return

		define_dict = sappreproc.generate_define_table(filestring)
		#print "number of defines: " + str(len(define_dict.keys()))
		result = sappreproc.resolve_defines("`WB_ADR_WIDTH:0", define_dict, debug = self.dbg)

		self.assertEqual(len(result) > 0, True)




	def test_resolve_multiple_defines(self):
		"""second easiest test, this one requires multiple passes of the 
		replacement string"""
		import sappreproc	
		import saputils
		#first get the filename
		filename = saputils.find_rtl_file_location("wb_ddr.v")
		filestring = ""
		try:
			f = open(filename)
			filestring = f.read()
			f.close()
		except:
			print "Failed to open test file"
			self.assertEqual(True, False)
			return

		define_dict = sappreproc.generate_define_table(filestring)
		#print "number of defines: " + str(len(define_dict.keys()))
		result = sappreproc.resolve_defines("`WB_ADR_WIDTH:`WB_SEL_WIDTH", define_dict, debug = self.dbg)

		self.assertEqual(len(result) > 0, True)

	def test_evaluate_range(self):
		"""test whether resolve string will get rid of parenthesis"""
		import sappreproc
		import saputils

		filename = saputils.find_rtl_file_location("wb_ddr.v")
		filestring = ""
		try:
			f = open(filename)
			filestring = f.read()
			f.close()
		except:
			print "Failed to open test file"
			self.assertEqual(True, False)
			return

		define_dict = sappreproc.generate_define_table(filestring)
		result = sappreproc.evaluate_range("val[(48 -12):0]", debug = self.dbg)
		
		print "final result: " + result
		self.assertEqual(result == "val[36:0]", True)


#		result = sappreproc.evaluate_equation("(4 * 3)", debug = self.dbg)
#		self.assertEqual((result == "12"), True)
#		result = sappreproc.evaluate_equation("(1 != 2)", debug = self.dbg)
#		self.assertEqual((result == "True"), True)

#	def test_resolve_string(self):
#		"""test whether resolve string will get rid of multiply"""
#		import sappreproc
#		import saputils
#
#		filename = saputils.find_rtl_file_location("wb_ddr.v")
#		filestring = ""
#		try:
#			f = open(filename)
#			filestring = f.read()
##			f.close()
#		except:
#			print "Failed to open test file"
#			self.assertEqual(True, False)
#			return

#		define_dict = sappreproc.generate_define_table(filestring)

#		result = sappreproc.resolve_string("3 * 4", debug = True)
#		self.assertEqual((result == "12"), True)




	def test_complicated_string(self):
		"""Hardest test of all, filled with multiple replacements and
		all of the pre-processing techniques"""
		self.assertEqual(True, True)

	def test_pre_processor(self):
		"""test a real file in the miracle grow directory"""
		self.assertEqual(True, True)
		"""test adding multiple lines togeterh with the \ key"""



if __name__ == "__main__":
	unittest.main()
