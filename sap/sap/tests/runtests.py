import sys
import getopt


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

	else:
		print "Running: " + arg
		test_module = __import__(arg)



def main(argv):
	"""Process arguments and run the specified commands"""
	if (len(argv) == 0):
		usage()
		sys.exit(1)
	else:
		try:
			opt, args = getopt.getopt(argv, "hld", ["help", "list", "debug"])
		except:
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

			elif opt in ("-l", "--list"):
				#list the files
				list_tests()

		if ("all" in args):
			test("all")

		else:
			for arg in args:
				test(arg)

		
if __name__ == "__main__":
	main(sys.argv[1:])
