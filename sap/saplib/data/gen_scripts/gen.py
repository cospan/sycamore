
class Gen:
	"""class specifically for overriding and generating a file"""
	def	__init__(self):
		self.tags = {}
		return

	def gen_script (self, tags = {}, buf = ""):
		"""This function is made for overriding, tags = input tags that modify the file, buf is the file buffer itself, its easier to modify a buffer than a file"""
		return ""

	def print_name (self):
		print "Base class: Gen"
