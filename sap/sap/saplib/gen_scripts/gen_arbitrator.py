import gen
from string import Template
from gen import Gen

class GenArbitrator(Gen):

	def __init__(self):
		print "in GenInterconnect"
		return

	def gen_script (self, tags = {}, buf = "", debug=False):
		"""Overridden function"""
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

		for key in tags.keys():
			print "arbitrator key: " + key
		#get the number of masters
		if (tags.has_key("MASTERS")):
			num_masters = len(tags["MASTERS"])
			
		else:
			print "Error in generate arbitrator: no list of masters in the tag"
#XXX HOW DO i RAISE AN EXCEPTION?
			return

		if (debug):
			print "Number of masters: " + str(num_masters)

		#generate the ports 
		for i in range (num_masters):
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
		for i in range (num_masters):
			port_def_buf = port_def_buf + "input\t\tm" + str(i) + "_we_i;\n"
			port_def_buf = port_def_buf + "input\t\tm" + str(i) + "_cyc_i;\n"
			port_def_buf = port_def_buf + "input\t\tm" + str(i) + "_stb_i;\n"
			port_def_buf = port_def_buf + "input\t[3:0]\tm" + str(i) + "_sel_i;\n"
			port_def_buf = port_def_buf + "input\t[31:0]\tm" + str(i) + "_adr_i;\n"
			port_def_buf = port_def_buf + "input\t[31:0]\tm" + str(i) + "_dat_i;\n"
			port_def_buf = port_def_buf + "output\t[31:0]\tm" + str(i) + "_dat_o;\n"
			port_def_buf = port_def_buf + "output\t\tm" + str(i) + "_ack_o;\n"
			port_def_buf = port_def_buf + "output\t\tm" + str(i) + "_ont_o;\n"
			port_def_buf = port_def_buf + "\n\n"

		if (debug):
			print "port define buf: \n\n" + port_def_buf

		#generate the master_select logic
		master_sel_buf = "//master select block\n"
		master_sel_buf += "parameter MASTER_NO_SEL = 8'hFF;\n"
		for i in range(num_masters):
			master_sel_buf += "parameter MASTER_" + str(i) + " = " + str(i) + ";\n"

		master_sel_buf += "\n\n"

		master_sel_buf += "always @(rst or master_select "
		for i in range(num_masters):
			master_sel_buf += "or m" + str(i) + "_stb_i "

		master_sel_buf += ") begin\n"
		master_sel_buf += "\tif (rst) begin\n"
		master_sel_buf += "\t\tmaster_select <= MASTER_NO_SEL;\n"
		master_sel_buf += "\tend\n"

		master_sel_buf += "\telse begin\n"
		master_sel_buf += "\t\tcase (master_select)\n"
		
		for i in range(num_masters):
			master_sel_buf += "\t\t\tMASTER_" + str(i) + ": begin\n"
			master_sel_buf += "\t\t\t\tif (~m" + str(i) + "_stb_i) begin\n"
			master_sel_buf += "\t\t\t\t\tmaster_select <= MASTER_NO_SEL;\n"
			master_sel_buf += "\t\t\t\tend\n"
			master_sel_buf += "\t\t\tend\n"

		master_sel_buf += "\t\t\tdefault: begin\n"
		master_sel_buf += "\t\t\t\t//nothing selected\n"

		first_if_flag = True
		for i in range(num_masters):
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
		for i in range(num_masters):
			write_buf += " or m" + str(i) + "_we_i"
		write_buf += ") begin\n"
		write_buf += "\tcase (master_select)\n"
		for i in range(num_masters):
			write_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
			write_buf += "\t\t\ts_we_o <= m" + str(i) + "_we_i;\n"
			write_buf += "\t\tend\n"

		write_buf += "\t\tdefault: begin\n"
		write_buf += "\t\t\ts_we_o <= 1'hx;\n"
		write_buf += "\t\tend\n"
		write_buf += "\tendcase\n"
		write_buf += "end\n"

		#generate the strobe logic
		strobe_buf = "//strobe select block\n"
		strobe_buf += "always @(master_select"
		for i in range(num_masters):
			strobe_buf += " or m" + str(i) + "_we_i"
		strobe_buf += ") begin\n"
		strobe_buf += "\tcase (master_select)\n"
		for i in range(num_masters):
			strobe_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
			strobe_buf += "\t\t\ts_stb_o <= m" + str(i) + "_stb_i;\n"
			strobe_buf += "\t\tend\n"

		strobe_buf += "\t\tdefault: begin\n"
		strobe_buf += "\t\t\ts_stb_o <= 1'hx;\n"
		strobe_buf += "\t\tend\n"
		strobe_buf += "\tendcase\n"
		strobe_buf += "end\n"

		#generate the cycle logic
		cycle_buf = "//cycle select block\n"
		cycle_buf += "always @(master_select"
		for i in range(num_masters):
			cycle_buf += " or m" + str(i) + "_cyc_i"
		cycle_buf += ") begin\n"
		cycle_buf += "\tcase (master_select)\n"
		for i in range(num_masters):
			cycle_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
			cycle_buf += "\t\t\ts_cyc_o <= m" + str(i) + "_cyc_i;\n"
			cycle_buf += "\t\tend\n"

		cycle_buf += "\t\tdefault: begin\n"
		cycle_buf += "\t\t\ts_cyc_o <= 1'hx;\n"
		cycle_buf += "\t\tend\n"
		cycle_buf += "\tendcase\n"
		cycle_buf += "end\n"

		#generate the select logic
		select_buf = "//select select block\n"
		select_buf += "always @(master_select"
		for i in range(num_masters):
			select_buf += " or m" + str(i) + "_sel_i"
		select_buf += ") begin\n"
		select_buf += "\tcase (master_select)\n"
		for i in range(num_masters):
			select_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
			select_buf += "\t\t\ts_sel_o <= m" + str(i) + "_sel_i;\n"
			select_buf += "\t\tend\n"

		select_buf += "\t\tdefault: begin\n"
		select_buf += "\t\t\ts_sel_o <= 1'hx;\n"
		select_buf += "\t\tend\n"
		select_buf += "\tendcase\n"
		select_buf += "end\n"

		#generate the address_logic
		address_buf = "//address seelct block\n"
		address_buf += "always @(master_select"
		for i in range(num_masters):
			address_buf += " or m" + str(i) + "_adr_i"
		address_buf += ") begin\n"
		address_buf += "\tcase (master_select)\n"
		for i in range(num_masters):
			address_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
			address_buf += "\t\t\ts_adr_o <= m" + str(i) + "_adr_i;\n"
			address_buf += "\t\tend\n"

		address_buf += "\t\tdefault: begin\n"
		address_buf += "\t\t\ts_adr_o <= 1'hx;\n"
		address_buf += "\t\tend\n"
		address_buf += "\tendcase\n"
		address_buf += "end\n"

		#generate the data logic
		data_buf = "//data select block\n"
		data_buf += "always @(master_select"
		for i in range(num_masters):
			data_buf += " or m" + str(i) + "_dat_i"
		data_buf += ") begin\n"
		data_buf += "\tcase (master_select)\n"
		for i in range(num_masters):
			data_buf += "\t\tMASTER_" + str(i) + ": begin\n" 
			data_buf += "\t\t\ts_dat_o <= m" + str(i) + "_dat_i;\n"
			data_buf += "\t\tend\n"

		data_buf += "\t\tdefault: begin\n"
		data_buf += "\t\t\ts_dat_o <= 1'hx;\n"
		data_buf += "\t\tend\n"
		data_buf += "\tendcase\n"
		data_buf += "end\n"

		#generate the assigns
		assign_buf = "//assign block\n"
		for i in range(num_masters):
			assign_buf += "m" + str(i) + "_ack_o = (master_select == MASTER_" + str(i) + ") ? s_ack_i : 0;\n"
			assign_buf += "m" + str(i) + "_dat_o = (master_select == MASTER_" + str(i) + ") ? s_ack_i : 0;\n"
			assign_buf += "m" + str(i) + "_int_o = (master_select == MASTER_" + str(i) + ") ? s_ack_i : 0;\n"
			assign_buf += "\n"

		buf = template.substitute ( PORTS=port_buf,
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

	def get_name (self):
		print "gen_arbitrator.py"

