#! /usr/bin/env python

import threading
import time
import subprocess
import os


class buildThread(threading.Thread):
	
	def __init__(self, threadID, name, project_dir):
		threading.Thread.__init__(self)
		self.threadID = threadID
		self.name = name
		self.project_dir = project_dir
		self.sub = None


	def run(self):
		print "Starting " + self.name
		#start the build
		#os.chdir(self.project_dir)
		os.chdir("/home/cospan/sandbox")

#		self.sub = subprocess.Popen(["bash", "./pa_no_gui.sh"], 
#		self.sub = subprocess.Popen(["ls", "-R"],
		self.sub = subprocess.Popen(["bash", "./demo.sh"],
									stdout = subprocess.PIPE,
									stderr = subprocess.PIPE,
									shell = False)
		output = self.get_std_out()
		print "Done!, %s" % output
		print "Thread finished"


	def get_std_out(self):
		print "getting STD out!"
		if self.sub is None:
			return None
		print "reading sub"
		output, error,  = self.sub.communicate()
		#print "output: %s" % output
		return output

	def is_running(self):
		print "IS Running!"
		return self.isAlive()

	def kill(self):
		if self.isAlive():
			self.sub.kill()

def print_time(threadName, delay, counter):
	while counter:
		if exitFlag:
			thread.exit()
		time.sleep(delay)
		print "%s: %s" % (threadName, time.ctime(time.time()))
		counter -= 1


