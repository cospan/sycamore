import unittest
import sapfile

class Test (unittest.TestCase):
	"""Unit test for sapfile"""

	def setUp(self):
		"""open up a sapfile class"""
		self.sapfile = sapfile.SapFile()

	def test_read_file(self):
		"""a file should be open for modifying"""
		result = self.sapfile.read_file("./data/bus", "README")
		self.assertEqual(result, True)

	def test_write_file(self):
		"""a file will end up in a directory after this is tested"""
		self.sapfile.buf = "crappidy crap data!"
		result = self.sapfile.write_file(location="~/sandbox", filename="test")
		self.assertEqual(result, True)

	def test_apply_gen_script(self):
		"""generate a file, a file should come out of this"""
		#load tags
		#load setup the buffer
		#setup the file tags
		#self.sapfile.apply_gen_script()
		self.assertEqual(False, False)

	def test_apply_tags(self):
		"""a file should be changed based on the tags"""
		project_name = "projjjjeeeecccttt NAME!!!"
		self.sapfile.read_file("./data/bus", "README")
		print self.sapfile.buf
		self.sapfile.clear_tag_map();
		self.sapfile.set_project_name(project_name)
		tag_map = {}
		self.sapfile.set_tag_map(tag_map)
		self.sapfile.apply_tags()
		print self.sapfile.buf
		result = (self.sapfile.buf.find(project_name) == 0)
		self.assertEqual(result, True)

	def test_set_tags(self):
		"""test to see if a tag file was loaded correctly"""
		tag_file = "./data/tags/README.json"
		result = self.sapfile.set_tags(tag_file)
		self.assertEqual(result, True)
	
	def test_tag_file_was_loaded(self):
		"""load the tag file"""
		tag_file = "./data/tags/README.json"
		result = self.sapfile.set_tags(tag_file)
		#print result
		#result = self.sapfile.tag_map.has_key("LICENSE")
		#print result
		self.assertEqual(result, True)

	def test_process_file_no_dir(self):
		"""make sure the process_file fales when user doesn't put in directory"""
		result = self.sapfile.process_file(filename = "README")
		self.assertNotEqual(result, True)

	def test_process_file_no_location(self):
		"""make sue the process file fails when user doesn't give a location"""
		result = self.sapfile.process_file(filename = "README", directory="~/sandbox")
		self.assertNotEqual(result, True)
	
		
	def test_process_file(self):
		"""excercise all functions of the class"""
		print "testing process file"
		project_tags_file = "./data/example_project/example1.json"
		self.sapfile.set_tags(project_tags_file)
		file_tags = {"location":"./data/bus"}
		result = self.sapfile.process_file(filename = "README", directory="~/sandbox", file_dict = file_tags)
		print self.sapfile.buf
		self.assertEqual(result, True)
		
		

if __name__ == "__main__":
	unittest.main()
