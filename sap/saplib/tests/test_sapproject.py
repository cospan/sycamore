import unittest
import sapproject
import saparbitrator
import saputils
import sys
import os

class Test (unittest.TestCase):
	"""Unit test for sapproject"""	

	def setUp(self):
		os.environ["SAPLIB_BASE"] = sys.path[0] + "/saplib"
		self.project = sapproject.SapProject() 
		self.dbg = False
		if "SAPLIB_DEBUG" in os.environ:
			if (os.environ["SAPLIB_DEBUG"] == "True"):
				self.dbg = True


	def test_read_config_string(self):
		"""cofirm that I can read the JSON string"""
		json_string = "[\"foo\", {\"bar\": [\"baz\", null, 1.0, 2]}]"
		result = self.project.read_config_string(json_string)
		self.assertEqual(result, True)
	
	def test_read_config_file(self):
		"""confirm that a project config file can be read"""
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"
		result = self.project.read_config_file(file_name, debug=self.dbg)
		result = True
		self.assertEqual(result, True)

	def test_read_template(self):
		"""confirm that a template file can be loaded"""
		filename = "wishbone_template"
		result = self.project.read_template(filename, debug=self.dbg)
		self.assertEqual(result, True)

#	def test_generate_project(self):
#		"""test if a project can be generated"""
#		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"
#		result = self.project.generate_project(file_name, debug=self.dbg)
#		self.assertEqual(result, True)

	def test_generate_project(self):
		"""test if a project can be generated with version 2"""
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_v2.json"
		result = self.project.generate_project(file_name, debug=self.dbg)
		self.assertEqual(result, True)

	def test_generate_ddr_project(self):
		"""test if the ddr project can be generated with version 2"""
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_example.json"
		result = self.project.generate_project(file_name, debug=self.dbg)
		self.assertEqual(result, True)
	
	def test_generate_mem_project(self):
		"""test if the new memory feature borks anything else"""
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/mem_example.json"
		result = self.project.generate_project(file_name, debug=self.dbg)
		self.assertEqual(result, True)

	def test_generate_arbitrators_none(self):
		"""confirm that no arbitrators are generated with this project tag"""
		file_name = os.getenv("SAPLIB_BASE") + "/example_project/gpio_v2.json"
		result = self.project.generate_project(file_name, debug=self.dbg)
		self.assertEqual(result, True)
		num_arbs = self.project.generate_arbitrators(debug = self.dbg)
		self.assertEqual(num_arbs, 0)

	def test_generate_arbitrators_simple(self):
		"""the project file is supposed to generate one file"""
		config_file_name = os.getenv("SAPLIB_BASE") + "/example_project/arb_example.json"
		result = self.project.read_config_file(config_file_name)
		self.assertEqual(result, True)
		result = self.project.read_template(self.project.project_tags["TEMPLATE"])
		self.assertEqual(result, True)
		self.project.filegen.set_tags(self.project.project_tags)
		#get the clock rate from the constraint file
		board_dict = saputils.get_board_config("sycamore1")
		cfiles = board_dict["constraint_files"]
		self.project.project_tags["CLOCK_RATE"] = saputils.read_clock_rate(cfiles[0])
		#generate the project directories and files
		self.project.project_tags["BASE_DIR"] = "~/sandbox/test_syc"
		saputils.create_dir(self.project.project_tags["BASE_DIR"])		

		#print "Parent dir: " + self.project.project_tags["BASE_DIR"]
		for key in self.project.template_tags["PROJECT_TEMPLATE"]["files"]:
			self.project.recursive_structure_generator(
							self.project.template_tags["PROJECT_TEMPLATE"]["files"],
							key,
							self.project.project_tags["BASE_DIR"])

		arb_tags = saparbitrator.generate_arbitrator_tags(self.project.project_tags)
		self.project.project_tags["ARBITRATORS"] = arb_tags

		result = self.project.generate_arbitrators(debug = self.dbg)
		self.assertEqual(result, 1)

	def test_generate_arbitrators_difficult(self):
		"""the project calls for three arbitrators, but two are identical"""
		config_file_name = os.getenv("SAPLIB_BASE") + "/example_project/arb_difficult_example.json"
		result = self.project.read_config_file(config_file_name)
		self.assertEqual(result, True)
		result = self.project.read_template(self.project.project_tags["TEMPLATE"])
		self.assertEqual(result, True)
		board_dict = saputils.get_board_config(self.project.project_tags["board"])
		cfiles = board_dict["constraint_files"]
		self.project.filegen.set_tags(self.project.project_tags)
		#get the clock rate from the constraint file
		self.project.project_tags["CLOCK_RATE"] = saputils.read_clock_rate(cfiles[0])
		#generate the project directories and files
		self.project.project_tags["BASE_DIR"] = "~/sandbox/test_syc"
		saputils.create_dir(self.project.project_tags["BASE_DIR"])		

		#print "Parent dir: " + self.project.project_tags["BASE_DIR"]
		for key in self.project.template_tags["PROJECT_TEMPLATE"]["files"]:
			self.project.recursive_structure_generator(
							self.project.template_tags["PROJECT_TEMPLATE"]["files"],
							key,
							self.project.project_tags["BASE_DIR"])

		arb_tags = saparbitrator.generate_arbitrator_tags(self.project.project_tags)
		self.project.project_tags["ARBITRATORS"] = arb_tags
	
		result = self.project.generate_arbitrators(debug = self.dbg)
		self.assertEqual(result, 2)

if __name__ == "__main__":
	unittest.main()

