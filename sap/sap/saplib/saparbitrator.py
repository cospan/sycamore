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
			for bus in slave_tags[slave]["BUS"].keys():
				if debug:
					print "bus for " + slave + " is " + bus
				arb_slave = slave_tags[slave]["BUS"][bus]
				if debug:
					print "adding: " + arb_slave + " to the arb_tags for " + bus
				
				if (not already_existing_arb_bus(arb_tags, arb_slave)):
					#create a new list
					arb_tags[arb_slave] = {}

				arb_tags[arb_slave][slave] = bus

	return arb_tags 

def already_existing_arb_bus(arb_tags = {}, arb_slave = "", debug = False):
	"""check if the arbitrated slave already exists in the arbitrator tags"""
	for arb_item in arb_tags.keys():
		if (arb_item == arb_slave):
			return True

	return False


