import unittest
import saparbitrator
import saputils
import json
import sys
import os

class Test (unittest.TestCase):
	"""Unit test for sapproject"""	

	def setUp(self):
		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True

	def test_get_number_of_arbitrator_hosts(self):
		#the first test should fail
		file_name = "wb_gpio.v"
		file_name = saputils.find_rtl_file_location(file_name)
		m_tags = saputils.get_module_tags(file_name, "wishbone")
		result = saparbitrator.get_number_of_arbitrator_hosts(m_tags, debug = self.dbg)

		self.assertEqual(len(result), 0)

		#the second test should pass
		file_name = "wb_console.v" 
		file_name = saputils.find_rtl_file_location(file_name)
		m_tags = saputils.get_module_tags(file_name, "wishbone")
		result = saparbitrator.get_number_of_arbitrator_hosts(m_tags, debug = self.dbg)

		self.assertEqual(len(result), 2)


		

	def test_is_arbitrator_host(self):
		"""
		test if the slave is an arbitrator host
		"""

		#the first test should fail
		file_name = "wb_gpio.v"
		file_name = saputils.find_rtl_file_location(file_name)
		m_tags = saputils.get_module_tags(file_name, "wishbone")
		result = saparbitrator.is_arbitrator_host(m_tags, debug = self.dbg)

		self.assertEqual(result, False)

		#the second test should pass
		file_name = "wb_console.v" 
		file_name = saputils.find_rtl_file_location(file_name)
		m_tags = saputils.get_module_tags(file_name, "wishbone")
		result = saparbitrator.is_arbitrator_host(m_tags, debug = self.dbg)

		self.assertEqual(result, True)

	def test_is_arbitrator_not_requried(self):
		"""test if the project_tags have been modified to show arbitrator"""
		result = False
		tags = {}
		#get the example project data
		try:
			filename = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"
			filein = open(filename)
			filestr = filein.read()
			tags = json.loads(filestr)

		except IOError as err:
			print "File Error: " + str(err)
			self.assertEqual(False, True)

		result = saparbitrator.is_arbitrator_required(tags, debug = self.dbg)

		self.assertEqual(result, False)
	
	def test_is_arbitrator_requried(self):
		"""test if the project_tags have been modified to show arbitrator"""
		result = False
		tags = {}
		#get the example project data
		try:
			filename = os.getenv("SAPLIB_BASE") + "/example_project/arb_example.json"
			filein = open(filename)
			filestr = filein.read()
			tags = json.loads(filestr)

		except IOError as err:
			print "File Error: " + str(err)
			self.assertEqual(False, True)

		result = saparbitrator.is_arbitrator_required(tags, debug = self.dbg)


		self.assertEqual(result, True)
	
	def test_generate_arbitrator_tags(self):
		"""test if saparbitrator correctly determins if an arbitrator is requried"""
		result = {}
		tags = {}
		#get the example project data
		try:
			filename = os.getenv("SAPLIB_BASE") + "/example_project/arb_example.json"
			filein = open(filename)
			filestr = filein.read()
			tags = json.loads(filestr)

		except IOError as err:
			print "File Error: " + str(err)
			self.assertEqual(False, True)

		result = saparbitrator.generate_arbitrator_tags(tags, debug = self.dbg)

		if (self.dbg):
			for aslave in result.keys():
				print "arbitrated slave: " + aslave

				for master in result[aslave]:
					print "\tmaster: " + master + " bus: " + result[aslave][master]
					

		self.assertEqual((len(result.keys()) > 0), True)

	
	def test_generate_arbitrator_buffer (self):
		"""generate an arbitrator buffer"""
		result = saparbitrator.generate_arbitrator_buffer(2, debug = self.dbg)
		if (self.dbg):
			print "generated arbitrator buffer: \n" + result
		self.assertEqual((len(result) > 0), True)

if __name__ == "__main__":
	unittest.main()
