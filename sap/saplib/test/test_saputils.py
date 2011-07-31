import unittest
import saputils

class Test (unittest.TestCase):
	"""Unit test for saputils"""

	def test_create_dir(self):
		"""create a directory"""
		result = saputils.create_dir("~/sandbox/projects")
		self.assertEqual(result, True)
	
	def test_open_linux_file(self):
		"""try and open a file with the ~ keyword"""
		try: 
			myfile = saputils.open_linux_file("~/sandbox/README")
			myfile.close()
		except:
			self.assertEqual(True, False)
			return
		self.assertEqual(True, True)
			

if __name__ == "__main__":
	unittest.main()
