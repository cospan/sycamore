import unittest
import saparbitrator
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


if __name__ == "__main__":
	unittest.main()
