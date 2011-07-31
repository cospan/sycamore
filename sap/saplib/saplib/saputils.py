import os

"""utilites that don't really belong in any of the sap classes"""

def create_dir(filename):
	"""Generate a directory with the specified location"""
	
	#print "os: ", os.name, "..."
	#print "split: ", os.path.split(filename)
	#print "split text: ", os.path.splitext(filename)
	#print "dirname: ", os.path.dirname(filename)
	#print "basename", os.path.basename(filename)
	#print "join: ", os.path.join(os.path.dirname(filename), 
	#							os.path.basename(filename))
	#print "cwd: ", os.getcwd()	
	#print "uname: ", os.uname()
	
	if filename.startswith("~"):
		filename = filename.strip("~")
		filename = os.getenv("HOME") + filename

	print "Directory to create: ", filename

	if  (not os.path.exists(filename)):
		print ("Directory doesn't exist attempting to create...")
		try: 
			os.makedirs(filename)
		except os.error:
			print "Error: failed to create the directory"
	else:
		print ("Found the directory")
	return True

def open_linux_file(filename):
	"""fixes linux issues when openeing a file"""

	if filename.startswith("~"):
		filename = filename.strip("~")
		filename = os.getenv("HOME") + filename
	
	return open(filename)
	
