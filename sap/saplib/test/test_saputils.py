import unittest
import saputils

class Test (unittest.TestCase):
	"""Unit test for saputils"""

	def test_create_dir(self):
		"""create a directory"""
		result = saputils.create_dir("projects")
		self.assertEqual(result, True)
	
if __name__ == "__main__":
	unittest.main()
