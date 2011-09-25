#!/usr/bin/env python

# Sap main interface
import sys
import getopt 

_debug = False
_verbose = False

def test():
	""" Test Everythin in all subcomponents"""


def test_saplib():
	"""Test all saplib components"""




def usage():
	"""prints out a helpful message to the user"""
	print ""
	print "usage: sap.py [options] <filename>"
	print ""
	print "filename: JSON file to be used to generate an FPGA image"
	print ""
	print "options:"
	print "-h\t--help\t\t\t: displays this help"
	print "-v\t--verbose\t\t: print out lots of info"
	print "-d\t--debug\t\t\t: configures modules to perform things through debug"
	print "-c\t--compress\t\t: compress output folders"
	print "-o\t--outfile <name>\t: output folder/filename"
	print ""


def main(argv):
	sys.path.append(sys.path[0] + '/saplib')
	sys.path.append(sys.path[0] + '/saplib/gen_scripts')
	compress = False

	if (len(argv) == 0):
		usage()
		sys.exit(1)
	else:
		try:
			opts, args = getopt.getopt(argv, "hvdco:", ["help", "verbose", "debug", "compress", "outfile"])
		except getopt.GetptError, err:
			print (err)
			usage()
			sys.exit(2)

		for opt, arg in opts:
			if opt in ("-h", "--help"):
				usage()
				sys.exit()
			elif opt in ("-v", "--verbose"):
				print "Verbose flage enabled"
				global _verbose
				_verbose = True
			elif opt in ("-d", "--debug"):
				print "Debug flage enabled"
				global _debug
				_debug = True
			elif opt in ("-c", "--compress"):
				print "Compress output, tgz"
				compress = True			
			elif opt in ("-o", "--output"):
				print "Output filename: " + output_filename
				output_filename = arg


		if (len(args) == 0):
			print ""
			print "no input file to process"
			usage()
			sys.exit(1)

		else:
			for filename in args:
				if _verbose:
					print "processing " + filename
				#saplib.generate_project(filename):


if __name__ == "__main__":
	main(sys.argv[1:])
