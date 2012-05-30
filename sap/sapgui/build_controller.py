#! /usr/bin/env python

import subprocess
import os
import select


class buildPseudoTerminal(object):
	def __init__(self):
		self.sub = None

	def run (self, command):
		"""
		Creates a spawned process
		"""
#		self.sub = subprocess.Popen(["bash", "/home/cospan/Projects/python/subprocess/demo.sh"],
		self.sub = subprocess.Popen(["ls", "-l"],
									stdout = subprocess.PIPE,
									stderr = subprocess.STDOUT)


	def read(self):
		rlist = [self.sub.stdout]
		wlist = []
		elist = []
				
		retval = select.select(rlist, wlist, elist, 0)[0]
		if len (retval) == 0:
			return None


		return self.sub.stdout.readline()

	def kill_child(self):
		print "kill child"
		self.sub.kill()

	def is_running(self):
		if os.path.exists("/proc/" + str(self.sub.pid)):
			procfile = open("/proc/%d/stat" % self.sub.pid)
			status = procfile.readline().split(' ')[2]
			procfile.close()
			if status == 'Z':
				return False
			return True

		return False


if __name__ == "__main__":
	print "starting"
	p = buildPseudoTerminal()
	p.run("ls -l")
	print "child process created"
	while p.is_running():
		#data = p.sub.stdout.readlines()
		data = p.read()
		if data is None:
			continue

		print data,

#		for d in data:
#			print d,

#	data = p.read()
#	print str(data)

	print "finished"

	
