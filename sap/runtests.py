#!/usr/bin/env python
import sys
import os
import getopt
import glob
import unittest

#import saplib.saplib


def usage():
	"""prints out message for the user"""
	print ""
	print "usage: runtests.py [options] test_name"
	print ""
	print "test_name can be an entire package"
	print ""
	print "\tsaplib"
	print "\tsapcmd"
	print "\tsapgui"
	print ""
	print "test_name can be a specific file"
	print ""
	print "-l\t--list\t:list the files/packages that can be tested"
	print "-d\t--debug\t:enable the global debug flag"
	print "-v\t--verbose\t:lots of messages"
	print ""


def get_testfile_list():
	testnames = []
	for root, dir, testfile in os.walk(sys.path[0] + "/saplib/tests"):
		testfiles = testfile	

	for root, dir, testfile in os.walk(sys.path[0] + "/sapgui/tests"):
		testfiles += testfile	



	if (testfiles.__contains__("__init__.py")):
		testfiles.remove("__init__.py")
	
	testnames = []	
#
	for testfile in testfiles:
		if (testfile.__contains__('test_') and (not testfile.__contains__('swp')) and (not testfile.__contains__(".pyc"))):
			testnames.append(testfile)
#		testnames.append(testfile.partition(".")[0])


	return testnames

def list_tests():
	"""list all the tests"""
	testfiles = get_testfile_list()
	print "Test Files:"
	for testfile in testfiles:
		print testfile


def test (arg):
	"""run the specified test"""
	testfiles = []
	if (arg == "all"):
		print "All tests"
		tl = unittest.TestLoader()
		pt = tl.discover(sys.path[0] + "/saplib/tests", pattern = 'test*.py')
		print "package tests: "
		print dir (pt)
		print "number of test cases: " + str(pt.countTestCases())
		print pt._tests
		pt.debug()
	else:
		testfiles.append(arg)

		print "Searching for test"
		tl = unittest.TestLoader()
		pt = tl.discover(sys.path[0] + "/saplib/tests", pattern = arg)
		paths = [	sys.path[0] + "/saplib/tests"]
#					sys.path[0] + "/sapgui/tests"]
		for p in paths:
			print "searching " + p + "...",
			pt = tl.discover(p, pattern = arg)
			if pt.countTestCases() != 0:
				print "Found!"
				break;
			else:
				print ""

		if (pt.countTestCases()  == 0):
			print "Didn't find test"
			#print "Didn't find: " + sys.path[0] + "/saplib/tests/" + arg
		else:
			print "Found test"
			pt.debug()	


def main(argv):
	"""Process arguments and run the specified commands"""
	sys.path.append(sys.path[0] + "/sapgui")
	sys.path.append(sys.path[0] + "/sapgui/tests")
	sys.path.append(sys.path[0] + "/saplib")
	sys.path.append(sys.path[0] + "/saplib/gen_scripts")
	sys.path.append(sys.path[0] + "/saplib/tests")


	global _debug
	_debug = False
	global verbose
	_verbose = False

	if (len(argv) == 0):
		usage()
		sys.exit(1)
	else:
		try:
			opts, args = getopt.getopt(argv, "hldv", ["help", "list", "debug", "verbose"])
		except getopt.GetoptError, err:
			print (err)
			usage()
			sys.exit(2)

		os.environ["SAPLIB_DEBUG"] = "False"
		os.environ["SAPLIB_VERBOSE"] = "False"

		for opt, arg in opts:
			if opt in ("-h", "--help"):
				usage()
				sys.exit()
			elif opt in ("-l", "--list"):
				#list the files
				list_tests()
			elif opt in ("-d", "--debug"):
				print "Debug flag enabled"
				os.environ["SAPLIB_DEBUG"] = "True"
				_debug = True
			elif opt in ("-v", "--verbose"):
				print "Verbose flag enabled"
				os.environ["SAPLIB_VERBOSE"] = "True"
				_debug = False


		if ("all" in args):
			test("all")

		else:
			for arg in args:
				test(arg)

		
if __name__ == "__main__":
	main(sys.argv[1:])
