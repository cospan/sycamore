import unittest
import gen
import gen_interconnect 
import os

class Test (unittest.TestCase):
	"""Unit test for sapfile"""

	def setUp(self):
		"""open up a sapfile class"""
		#self.gen = gen_interconnect.GenInterconnect()

	def test_generate_file (self):
		"""Generate file"""
		#need to test the super class
		tags = {"SLAVES":["slave1", "slave2"]}
		interconnect_buffer = "\n${PORTS}\n${PORT_DEFINES}\n${ADDRESSES}\n${ASSIGN}\n${DATA}\n${ACK}\n${INT}"

		#print "input buffer: " + interconnect_buffer

		self.gen_module = __import__("gen_interconnect")
		self.gen = self.gen_module.GenInterconnect()
		self.gen.print_name()

		result = self.gen.gen_script(tags, buf = interconnect_buffer)

		#print "output buffer: " + result
		self.assertEqual(len(result) > 0, True)

	def test_gen_interconnect (self):
		"""Generate an actual interconnect file"""
		interconnect_buffer = ""
		tags = {"SLAVES":["slave1", "slave2"]}
		try:
			filename = os.getenv("SAPLIB_BASE") + "/data/hdl/rtl/wishbone/interconnect/wishbone_interconnect.v"
			filein = open(filename)
			interconnect_buffer = filein.read()
			filein.close()
		except IOError as err:
			print "File Error: " + str(err)

		print "buf: " + interconnect_buffer
		self.gen_module = __import__("gen_interconnect")
		self.gen = self.gen_module.GenInterconnect()
		result = self.gen.gen_script(tags, buf = interconnect_buffer)

		#write out the file
		try:
			filename = os.getenv("HOME") + "/sandbox/wishbone_interconnect.v"
			fileout = open(filename, "w")
			fileout.write(result)
		except IOError as err:
			print "File Error: " + str(err)

		self.assertEqual(len(result) > 0, True)
			


if __name__ == "__main__":
	unittest.main()
