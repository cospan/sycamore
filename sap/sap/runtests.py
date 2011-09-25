#!/usr/bin/env python
import sys
import getopt
import glob

#import saplib.saplib


def usage():
	"""prints out message for the user"""
	print "usage: runtests.py [options] test_name"
	print "test_name can be an entire package"
	print "\tsaplib"
	print "\tsapcmd"
	print "\tsapgui"
	print "test_name can be a specific file"
	print "-l\t--list\t:list the files/packages that can be tested"
	print "-d\t--debug\t:enable the global debug flag"


def list_tests():
	"""list all the tests"""


def test (arg):
	"""run the specified test"""
	if (arg == "all"):
		print "Running all tests"
		#need to find all the tests

	else:
		print "Running: " + arg
		import test_xilinx
		#module = imp.load_source("saplib.py", mod_paths)


def main(argv):
	"""Process arguments and run the specified commands"""
	sys.path.append(sys.path[0] + "./saplib")
	sys.path.append(sys.path[0] + "./saplib/gen_scripts")
	sys.path.append(sys.path[0] + "./saplib/tests")

	if (len(argv) == 0):
		usage()
		sys.exit(1)
	else:
		try:
			opts, args = getopt.getopt(argv, "hld", ["help", "list", "debug"])
		except:
			print (err)
			usage()
			sys.exit(2)


		for opt, arg in opts:
			if opt in ("-h", "--help"):
				usage()
				sys.exit()
			elif opt in ("-l", "--list"):
				#list the files
				list_tests()
			elif opt in ("-d", "--debug"):
				print "Debug flag enabled"
				_debug = True


		if ("all" in args):
			test("all")

		else:
			for arg in args:
				test(arg)

		
if __name__ == "__main__":
	main(sys.argv[1:])
