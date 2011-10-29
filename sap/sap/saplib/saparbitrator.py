import saputils
import os

"""Analyzes tags, generates arbitrators, sets tags to indicate connections"""

def is_arbitrator_required(tags = {}, debug = False):
	"""analyze the project tags to determine if any arbitration is requried""" 
	if debug:
		print "in is_arbitrator_required()"
	#count the number of times a device is referenced

	#SLAVES
	slave_tags = tags["SLAVES"]
	for slave in slave_tags:
		if debug:
			print "found slave " + str(slave) 
		if ("BUS" in slave_tags[slave]):
			if (len(slave_tags[slave]["BUS"]) > 0):
				return True
#FOR THIS FIRST ONE YOU MUST SPECIFIY THE PARTICULAR MEMORY SLAVE AS APPOSED TO JUST MEMORY WHICH IS THAT ACTUAL MEMORY INTERCONNECT

	return False

def generate_arbitrator_tags(tags = {}, debug = False):
	"""generate the arbitrator tags required to generate all the arbitrators, and how and where to connect all the arbitrators"""
	arb_tags = {}
	if (not is_arbitrator_required(tags)):
		return {}

	if debug:
		print "arbitration is required"

	slave_tags = tags["SLAVES"]
	for slave in slave_tags:
		if ("BUS" in slave_tags[slave]):
			if (len(slave_tags[slave]["BUS"]) == 0):
				continue
			if debug:
				print "slave: " + slave + " is an arbtrator master"


	return arb_tags 




