# Sap main interface

import saplib
import sys
import getopt




def test(test_name = ""):
	""" If unit is blank Test all subcomponents"""

	if (test_name == "all"):
		print "testing all"
	else:
		print "testing unit"



def gui():
	"""start up the GUI"""
	print "staring the GUI"








def usage():
	"""Print out the usage of sap"""
	print "usage: sap [options]"
	print "Options and arguments (and corresponding environmental variables"
	print "-h\t--help\t\t\t: prints this help message"
	print "-d\t--debug\t\t\t: prints debug messages"
	print "-t\t--test\t<test name>\t: runs either all tests, or if a file is specified runs the unit test for that file"

def main(argv):
	"""Process arguments and run the specified commands"""
	unit_test = ""
	if (len(argv) == 0):
		usage()
	else:
		try:
			opts, args = getopt.getopt(argv, "ht:d", ["help", "test", "debug"])
		except getopt.GetoptError, err:
			print (err)
			usage()
			sys.exit(2)

		for opt, arg in opts:
			if opt in ("-h", "--help"):
				usage()
				sys.exit()
			elif opt in ("-d", "--debug"):
				print "Debug flag enabled"
				_debug = True
		
			elif opt in ("-t", "--test"):
				#testing modules
				test(arg)

		#source = "".join(args)
		if ("gui" in args or "GUI" in args):
			gui()

		else:
			if (len(args) > 0):
				print "whats left over?: "
				for arg in args:
					print arg



if __name__ == "__main__":
	main(sys.argv[1:])
