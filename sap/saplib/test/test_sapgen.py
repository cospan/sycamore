import unittest
import sapgen

class Test (unittest.TestCase):
	"""Unit test for sapgen"""

	def setUp(self):
		"""open up a sapgen class"""
		self.sapgen = sapgen.SapGen()

	def test_open_file(self):
		"""a file should be open for modifying"""
		result = self.sapgen.open_file("./data/bus", "README")
		self.assertEqual(result, True)

	def test_write_file(self):
		"""a file will end up in a directory after this is tested"""
		self.sapgen.buf = "crappidy crap data!"
		result = self.sapgen.write_file(location="~/sandbox", filename="test")
		self.assertEqual(result, True)

	def test_generate_file(self):
		"""generate a file, a file should come out of this"""
		self.sapgen.generate_file()
		self.assertEqual(False, False)

	def test_modify_file(self):
		"""a file should be changed based on the tags"""
		project_name = "projjjjeeeecccttt NAME!!!"
		self.sapgen.open_file("./data/bus", "README")
		print self.sapgen.buf
		self.sapgen.clear_tag_map();
		self.sapgen.set_project_name(project_name)
		tag_map = {}
		self.sapgen.set_tag_map(tag_map)
		self.sapgen.modify_file()
		print self.sapgen.buf
		result = (self.sapgen.buf.find(project_name) == 0)
		self.assertEqual(result, True)

	def test_load_tag_file(self):
		"""test to see if a tag file was loaded correctly"""
		tag_file = "./data/tags/README.json"
		result = self.sapgen.load_tag_file(tag_file)
		self.assertEqual(result, True)
	
	def test_tag_file_was_loaded(self):
		"""load the tag file"""
		tag_file = "./data/tags/README.json"
		result = self.sapgen.load_tag_file(tag_file)
		#print result
		#result = self.sapgen.tag_map.has_key("LICENSE")
		#print result
		self.assertEqual(result, True)

	def test_process_file_no_dir(self):
		"""make sure the process_file fales when user doesn't put in directory"""
		result = self.sapgen.process_file(filename = "README")
		self.assertNotEqual(result, True)

	def test_process_file_no_location(self):
		"""make sue the process file fails when user doesn't give a location"""
		result = self.sapgen.process_file(filename = "README", directory="~/sandbox")
		self.assertNotEqual(result, True)
	
		
	def test_process_file(self):
		"""excercise all functions of the class"""
		print "testing process file"
		project_tags_file = "./data/example_project/example1.json"
		self.sapgen.load_tag_file(project_tags_file)
		file_tags = {"location":"./data/bus"}
		result = self.sapgen.process_file(filename = "README", directory="~/sandbox", file_dict = file_tags)
		print self.sapgen.buf
		self.assertEqual(result, True)
		
		

if __name__ == "__main__":
	unittest.main()
