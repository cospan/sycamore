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
		self.sub = subprocess.Popen(["ls", "-l"],
									bufsize = 4096,
									stdout = subprocess.PIPE,
									stderr = subprocess.PIPE)


	def read(self):
#		rlist = [self.sub.stdout]
#		wlist = []
#		elist = []
				
		newdata = self.sub.stdout.readline()
		data = ""
		if len(newdata) > 0:
			data += newdata
			newdata = self.sub.stdout.readline()

		if len(data) == 0:
			return None

		return data
	
#		retval = select.select(rlist, wlist, elist, None)[0]
#		if len (retval) == 0:
#			return None


#		return self.sub.stdout.readline()

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
		data = p.read()
		if data is None:
			continue
		#data = p.read()
		print str(data)

#	data = p.read()
#	print str(data)

	print "finished"

	
