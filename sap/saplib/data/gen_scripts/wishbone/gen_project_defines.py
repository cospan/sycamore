#gen_project_defines.py

from gen import Gen
import saputils
from string import Template

class GenProjectDefines(Gen):
	"""Generate the top module for a project"""

	def __init__(self):
		print "in GenProjectDefines"
		return

	def gen_script (self, tags={}, buf="", debug = False):
		"""Generate the project_defines.v"""

		
		template = Template(buf) 
		num_of_slaves = str(len(tags["SLAVES"]))
		buf = template.substitute(PROJECT_NAME = tags["PROJECT_NAME"], NUMBER_OF_DEVICES=num_of_slaves)
		return buf


	def get_name(self):
		print "Generate the project defines"


