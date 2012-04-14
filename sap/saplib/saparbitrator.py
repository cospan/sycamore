import saputils
import os
from string import Template


"""Analyzes tags, generates arbitrators, sets tags to indicate connections"""
def get_number_of_arbitrator_hosts(module_tags = {}, debug = False):
	"""
	returns the number of arbitrator hosts found inside the module
	"""

	#go through all the inports and verify that after the first 
	#'_' there is a a wbm and hte wbm has all the arbitrator 
	#host components

	if debug:
		print "Module Name: %s" % (module_tags["module"])
		print "ports: "
	wb_bus = [	"dat_i",
				"int_i",
				"ack_i",
				"adr_o",
				"stb_o",
				"we_o",
				"cyc_o",
				"dat_o",
				"sel_o"
			]
	possible_prefix = {}
	prefixes = []
	for io_ports in module_tags["ports"]:
		if debug:
			print "\tio_ports: " + io_ports
		for name in module_tags["ports"][io_ports]:
			if debug:
				print "\t\t: " + str(name)
			#throw out obvious false
			if "_" not in name:
				continue

			for wbm_wire in wb_bus:
				if wbm_wire in name:
					prefix = name.partition("_")[0]
					if prefix not in possible_prefix.keys():
						possible_prefix[prefix] = list(wb_bus)
						if debug:
							print "found a possible arbitrator: %s" % (prefix)

					wbm_post = name.partition("_")[2]
					if wbm_post in possible_prefix[prefix]:
						possible_prefix[prefix].remove(wbm_post)
					


	for prefix in possible_prefix.keys():
		if debug:
			print "examining: %s" % (prefix)
			print "\tlength of prefix list: %s" % (str(possible_prefix[prefix]))
		if len (possible_prefix[prefix]) == 0:
			if debug:
				print "%s is an arbitrator host" % (prefix)
			prefixes.append(prefix)

	return prefixes


def is_arbitrator_host(module_tags = {}, debug = False):
	"""determines if a slave can be an arbitrator host"""
	return (len(get_number_of_arbitrator_hosts(module_tags, debug)) > 0)

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

def generate_arbitrator_buffer(master_count = 0, debug = False):
#need to open up the arbitrator file and create a buffer

	if (master_count == 0):
		if (debug):
			print "master_count == 0, no arbitrators to generate"
		return ""

	try:
		filename = os.getenv("SAPLIB_BASE") + "/hdl/rtl/wishbone/arbitrator/wishbone_arbitrator.v"
		filein = open(filename)
		buf = filein.read()
		filein.close()
	except IOError as err:
		print "File Error: " + str(err)


	template = Template(buf)

	port_buf = ""
	port_def_buf = ""
	master_sel_buf = ""
	write_buf = ""
	strobe_buf = ""
	cycle_buf = ""
	select_buf = ""
	address_buf = ""
	data_buf = ""
	assign_buf = ""

	#generate the ports 
	for i in range (master_count):
		#add the ports
		port_buf = port_buf + "\tm" + str(i) + "_we_i,\n"
		port_buf = port_buf + "\tm" + str(i) + "_cyc_i,\n"
		port_buf = port_buf + "\tm" + str(i) + "_stb_i,\n"
		port_buf = port_buf + "\tm" + str(i) + "_sel_i,\n"
		port_buf = port_buf + "\tm" + str(i) + "_ack_o,\n"
		port_buf = port_buf + "\tm" + str(i) + "_dat_i,\n"
		port_buf = port_buf + "\tm" + str(i) + "_dat_o,\n"
		port_buf = port_buf + "\tm" + str(i) + "_adr_i,\n"
		port_buf = port_buf + "\tm" + str(i) + "_int_o"
		port_buf = port_buf + ",\n"
			
		port_buf = port_buf + "\n\n"
	
	if (debug):
		print "port_buf: " + port_buf

	#generate the port defines
	for i in range (master_count):
		port_def_buf = port_def_buf + "input\t\t\tm" + str(i) + "_we_i;\n"
		port_def_buf = port_def_buf + "input\t\t\tm" + str(i) + "_cyc_i;\n"
		port_def_buf = port_def_buf + "input\t\t\tm" + str(i) + "_stb_i;\n"
		port_def_buf = port_def_buf + "input\t[3:0]\tm" + str(i) + "_sel_i;\n"
		port_def_buf = port_def_buf + "input\t[31:0]\tm" + str(i) + "_adr_i;\n"
		port_def_buf = port_def_buf + "input\t[31:0]\tm" + str(i) + "_dat_i;\n"
		port_def_buf = port_def_buf + "output\t[31:0]\tm" + str(i) + "_dat_o;\n"
		port_def_buf = port_def_buf + "output\t\t\tm" + str(i) + "_ack_o;\n"
		port_def_buf = port_def_buf + "output\t\t\tm" + str(i) + "_int_o;\n"
		port_def_buf = port_def_buf + "\n\n"

	if (debug):
		print "port define buf: \n\n" + port_def_buf

	#generate the master_select logic
	master_sel_buf = "//master select block\n"
	master_sel_buf += "parameter MASTER_NO_SEL = 8'hFF;\n"
	for i in range(master_count):
		master_sel_buf += "parameter MASTER_" + str(i) + " = " + str(i) + ";\n"

	master_sel_buf += "\n\n"

	master_sel_buf += "always @(rst or master_select "
	for i in range(master_count):
		master_sel_buf += "or m" + str(i) + "_stb_i "

	master_sel_buf += ") begin\n"
	master_sel_buf += "\tif (rst) begin\n"
	master_sel_buf += "\t\tmaster_select <= MASTER_NO_SEL;\n"
	master_sel_buf += "\tend\n"

	master_sel_buf += "\telse begin\n"
	master_sel_buf += "\t\tcase (master_select)\n"
		
	for i in range(master_count):
		master_sel_buf += "\t\t\tMASTER_" + str(i) + ": begin\n"
		master_sel_buf += "\t\t\t\tif (~m" + str(i) + "_stb_i) begin\n"
		master_sel_buf += "\t\t\t\t\tmaster_select <= MASTER_NO_SEL;\n"
		master_sel_buf += "\t\t\t\tend\n"
		master_sel_buf += "\t\t\tend\n"

	master_sel_buf += "\t\t\tdefault: begin\n"
	master_sel_buf += "\t\t\t\t//nothing selected\n"

	first_if_flag = True
	for i in range(master_count):
		if (first_if_flag):
			first_if_flag = False
			master_sel_buf += "\t\t\t\tif (m" + str(i) + "_stb_i) begin\n"
		else:
			master_sel_buf += "\t\t\t\telse if (m" + str(i) + "_stb_i) begin\n"

		master_sel_buf += "\t\t\t\t\tmaster_select <= MASTER_" + str(i) + ";\n"
		master_sel_buf += "\t\t\t\tend\n"
	master_sel_buf += "\t\t\tend\n"
	master_sel_buf += "\t\tendcase\n"
	master_sel_buf += "\tend\n"
	master_sel_buf += "end\n"


	#generate the write logic
	write_buf = "//write select block\n"
	write_buf += "always @(master_select"
	for i in range(master_count):
		write_buf += " or m" + str(i) + "_we_i"
	write_buf += ") begin\n"
	write_buf += "\tcase (master_select)\n"
	for i in range(master_count):
		write_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
		write_buf += "\t\t\ts_we_o <= m" + str(i) + "_we_i;\n"
		write_buf += "\t\tend\n"

	write_buf += "\t\tdefault: begin\n"
	write_buf += "\t\t\ts_we_o <= 1'h0;\n"
	write_buf += "\t\tend\n"
	write_buf += "\tendcase\n"
	write_buf += "end\n"

	#generate the strobe logic
	strobe_buf = "//strobe select block\n"
	strobe_buf += "always @(master_select"
	for i in range(master_count):
		strobe_buf += " or m" + str(i) + "_we_i"
	strobe_buf += ") begin\n"
	strobe_buf += "\tcase (master_select)\n"
	for i in range(master_count):
		strobe_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
		strobe_buf += "\t\t\ts_stb_o <= m" + str(i) + "_stb_i;\n"
		strobe_buf += "\t\tend\n"

	strobe_buf += "\t\tdefault: begin\n"
	strobe_buf += "\t\t\ts_stb_o <= 1'h0;\n"
	strobe_buf += "\t\tend\n"
	strobe_buf += "\tendcase\n"
	strobe_buf += "end\n"

	#generate the cycle logic
	cycle_buf = "//cycle select block\n"
	cycle_buf += "always @(master_select"
	for i in range(master_count):
		cycle_buf += " or m" + str(i) + "_cyc_i"
	cycle_buf += ") begin\n"
	cycle_buf += "\tcase (master_select)\n"
	for i in range(master_count):
		cycle_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
		cycle_buf += "\t\t\ts_cyc_o <= m" + str(i) + "_cyc_i;\n"
		cycle_buf += "\t\tend\n"

	cycle_buf += "\t\tdefault: begin\n"
	cycle_buf += "\t\t\ts_cyc_o <= 1'h0;\n"
	cycle_buf += "\t\tend\n"
	cycle_buf += "\tendcase\n"
	cycle_buf += "end\n"

	#generate the select logic
	select_buf = "//select select block\n"
	select_buf += "always @(master_select"
	for i in range(master_count):
		select_buf += " or m" + str(i) + "_sel_i"
	select_buf += ") begin\n"
	select_buf += "\tcase (master_select)\n"
	for i in range(master_count):
		select_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
		select_buf += "\t\t\ts_sel_o <= m" + str(i) + "_sel_i;\n"
		select_buf += "\t\tend\n"

	select_buf += "\t\tdefault: begin\n"
	select_buf += "\t\t\ts_sel_o <= 4'h0;\n"
	select_buf += "\t\tend\n"
	select_buf += "\tendcase\n"
	select_buf += "end\n"

	#generate the address_logic
	address_buf = "//address seelct block\n"
	address_buf += "always @(master_select"
	for i in range(master_count):
		address_buf += " or m" + str(i) + "_adr_i"
	address_buf += ") begin\n"
	address_buf += "\tcase (master_select)\n"
	for i in range(master_count):
		address_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
		address_buf += "\t\t\ts_adr_o <= m" + str(i) + "_adr_i;\n"
		address_buf += "\t\tend\n"

	address_buf += "\t\tdefault: begin\n"
	address_buf += "\t\t\ts_adr_o <= 32'h00000000;\n"
	address_buf += "\t\tend\n"
	address_buf += "\tendcase\n"
	address_buf += "end\n"

	#generate the data logic
	data_buf = "//data select block\n"
	data_buf += "always @(master_select"
	for i in range(master_count):
		data_buf += " or m" + str(i) + "_dat_i"
	data_buf += ") begin\n"
	data_buf += "\tcase (master_select)\n"
	for i in range(master_count):
		data_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
		data_buf += "\t\t\ts_dat_o <= m" + str(i) + "_dat_i;\n"
		data_buf += "\t\tend\n"

	data_buf += "\t\tdefault: begin\n"
	data_buf += "\t\t\ts_dat_o <= 32'h00000000;\n"
	data_buf += "\t\tend\n"
	data_buf += "\tendcase\n"
	data_buf += "end\n"

	#generate the assigns
	assign_buf = "//assign block\n"
	for i in range(master_count):
		assign_buf += "assign m" + str(i) + "_ack_o = (master_select == MASTER_" + str(i) + ") ? s_ack_i : 0;\n"
		assign_buf += "assign m" + str(i) + "_dat_o = (master_select == MASTER_" + str(i) + ") ? s_dat_i : 0;\n"
		assign_buf += "assign m" + str(i) + "_int_o = (master_select == MASTER_" + str(i) + ") ? s_int_i : 0;\n"
		assign_buf += "\n"

	arbitrator_name = "arbitrator_" + str(master_count) + "_masters"

	buf = template.substitute ( ARBITRATOR_NAME=arbitrator_name,
								PORTS=port_buf,
								PORT_DEFINES=port_def_buf,
								MASTER_SELECT=master_sel_buf,
								WRITE=write_buf,
								STROBE=strobe_buf,
								CYCLE=cycle_buf,
								SELECT=select_buf,
								ADDRESS=address_buf,
								DATA=data_buf,
								ASSIGN=assign_buf); 
	return buf




def already_existing_arb_bus(arb_tags = {}, arb_slave = "", debug = False):
	"""check if the arbitrated slave already exists in the arbitrator tags"""
	for arb_item in arb_tags.keys():
		if (arb_item == arb_slave):
			return True
	return False

