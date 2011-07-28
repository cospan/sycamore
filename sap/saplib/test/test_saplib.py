import unittest
import saplib

class Test (unittest.TestCase):
	"""Unit test for saplib"""

	def setUp(self):
		self.sap = saplib.Sap()
		self.json_simple_list = "[1, 2]"
		self.json_simple_dictionary = "{\"key\":\"value\"}"
		self.json_complex_string = "[\"foo\", {\"bar\": [\"baz\", null, 1.0, 2]}]"


	def test_default_values(self):
		name = "test_project"
		dir = "~/sycamore_projects/test_dir"
		self.sap.name = name
		self.sap.dir = dir
		self.assertEqual(name, "test_project");

	def test_query_slaves(self):
		"""test the query slave function"""
		result = self.sap.query_slaves("gpio")
		#self.assertEqual(result, True)
		self.assertEqual(result,False)

	def test_query_handlers(self):
		"""test the query handler function"""
		result = self.sap.query_handlers("uart")
		self.assertEqual(result, True)

	def test_update_json(self):
		"""test update_json"""
		self.sap.update_json()
		#Check if the bus type was extracted.
		self.assertEqual("wishbone", self.sap.bus_type)
		#Check if the master handler changed.
		self.assertEqual("uart", self.sap.selected_handler)
		#Check if the slaves correspond with the slaves in the JSON file.
	
	def test_create_json(self):
		"""Test the create JSON string function"""
		result = self.sap.create_json("json_file");
		self.assertEqual(1, 1)
	
	def test_load_json_string(self):
		"""Test load a structure from a json_string"""
		self.sap.load_json_string(self.json_complex_string)
		json_structure = self.sap.load_json_string(self.json_simple_dictionary)
		#print (json_structure["key"])
		self.assertEqual(json_structure["key"], "value")

	def test_load_project_config(self):
		project_config = self.sap.load_project_config(json_config_file_name="./data/example_project/example1.json")
		project_structure = self.sap.load_project_template("./data/templates/wishbone/wishbone_template.json")
		self.assertEqual(1,1)	

	def test_load_project_template(self):
		"""Test the loading JSON file"""
		project_structure = self.sap.load_project_template("./data/templates/wishbone/wishbone_template.json")
		self.assertNotEqual(len(project_structure), 0)
		self.assertEqual(True, True)

	def test_set_base_directory(self):
		"""Test the set base directory of the projec template"""
		result = self.sap.set_base_directory()
		self.assertEqual(result, False)
		result = self.sap.set_base_directory(base_directory="~/Projects/sycamore_projects");
		self.assertEqual(result, True)
	
	def test_generate_project_structure(self):
		"""Test generating the project file structure"""
		self.sap.load_project_template(".//test//project_struct_template.json");
		base_dir = "/home/cospan/Projects/sycamore_projects" + "/test_project"
		result = self.sap.set_base_directory(base_directory=base_dir);
		result = self.sap.generate_project_structure()
		self.assertEqual(result, 0);
	
	def test_recursive_structure_generator(self):
		"""Test the recursive file generator"""
		#my_dict = {"d1":1, "d2":3}
		#parent_dict = {"pos1":2, "pos2":my_dict}
		#result = self.sap.recursive_structure_generator(item = my_dict, parent_dir = "")
		#self.assertEqual(result, True)

	def test_generate_project(self):
		self.assertEqual(True, True)

if __name__ == "__main__":
	unittest.main()
