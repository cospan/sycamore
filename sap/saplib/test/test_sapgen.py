import unittest
import sapgen

class Test (unittest.TestCase):
	"""Unit test for sapgen"""

	def setUp(self):
		"""open up a sapgen class"""
		self.sapgen = sapgen.SapGen()

	def test_open_file(self):
		"""a file should be open for modifying"""
		result = self.sapgen.open_file("./data/templates", "README")
		self.assertEqual(result, True)

	def test_write_file(self):
		"""a file will end up in a directory after this is tested"""
		self.sapgen.write_file()
		self.assertEqual(False, False)

	def test_generate_file(self):
		"""generate a file, a file should come out of this"""
		self.sapgen.generate_file()
		self.assertEqual(False, False)

	def test_modify_file(self):
		"""a file should be changed based on the tags"""
		project_name = "projjjjeeeecccttt NAME!!!"
		self.sapgen.open_file("./data/templates", "README")
		print self.sapgen.buffer
		self.sapgen.clear_tag_map();
		self.sapgen.set_project_name(project_name)
		tag_map = {}
		self.sapgen.set_tag_map(tag_map)
		self.sapgen.modify_file()
		print self.sapgen.buffer
		result = (self.sapgen.buffer.find(project_name) == 0)
		self.assertEqual(result, True)

	def test_load_tag_file(self):
		"""test to see if a tag file was loaded correctly"""
		tag_file = ".data/tags/README.json"
		result = self.sapgen.load_tag_file(tag_file)
		self.assertEqual(result, True)
	
	def test_tag_file_was_loaded(self):
		tag_file = ".data/tags/README.json"
		result = self.sapgen.load_tag_file(tag_file)
		result = self.sapgen.tag_map.has_key("LICENSE")
		self.assertEqual(result, True)


		
		

if __name__ == "__main__":
	unittest.main()
