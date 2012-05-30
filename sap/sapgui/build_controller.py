#! /usr/bin/env python

import subprocess
import os
import select
import fcntl


class BuildController(object):
	def __init__(self):
		self.sub = None

	def run (self, command):
		"""
		Creates a spawned process
		"""
#		self.sub = subprocess.Popen(["bash", "/home/cospan/Projects/python/subprocess/demo.sh"],
#		self.sub = subprocess.Popen(["ls", "-l"],
		args = ["bash", command]
		self.sub = subprocess.Popen(args,
									stdout = subprocess.PIPE,
									stderr = subprocess.STDOUT)

		flags = fcntl.fcntl(self.sub.stdout, fcntl.F_GETFL)
		fcntl.fcntl(self.sub.stdout, fcntl.F_SETFL, flags | os.O_NONBLOCK)
		data = self.read()
		if data is not None:
			print "data is not None"
			print data

	def read(self):
		data = None
		try:
			data = self.sub.stdout.readline()
		except:
			return None
		return data
			
	def kill_child(self):
		print "kill child"
		self.sub.kill()

	def is_running(self):
		if self.sub is None:
			print "sub == None"
			return False
		if os.path.exists("/proc/" + str(self.sub.pid)):
			procfile = open("/proc/%d/stat" % self.sub.pid)
			status = procfile.readline().split(' ')[2]
			procfile.close()
			if status == 'Z':
				print "Zombie!"
				return False
			return True

		print "process file isn't found"
		return False

if __name__ == "__main__":
	print "starting"
	p = BuildController()
	p.run("tests/demo.sh")
	print "child process created"
	while p.is_running():
		#data = p.sub.stdout.readlines()
		data = p.read()
		if data is None:
			continue
		print data,

	print "finished"

	
