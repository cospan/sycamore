import gen
from string import Template
from gen import Gen

class GenInterconnect(Gen):


	def __init__(self):
		print "in GenInterconnect"
		return

	def gen_script (self, tags = {}, buf = ""):
		"""Overridden function"""
		slave_list = []
		template = Template(buf)
		
		port_buf = ""
		port_def_buf = ""
		assign_buf = ""
		data_block_buf = ""
		ack_block_buf = ""
		int_block_buf = ""
		address_param_buf = ""

		#start with 1 to account for DRT
		num_slaves = 1
		if (tags.has_key("SLAVES")):
			#got a list of all the slaves to add to make room for
			slave_list = tags["SLAVES"]	
			num_slaves = num_slaves + len(slave_list)


		#for i in range ( 0, num_slaves):
		#	print "count: " + str(i)

		# ports
		for i in range (0, num_slaves):
			port_buf = port_buf + "\ts" + str(i) + "_we_o,\n"
			port_buf = port_buf + "\ts" + str(i) + "_cyc_o,\n"
			port_buf = port_buf + "\ts" + str(i) + "_stb_o,\n"
			port_buf = port_buf + "\ts" + str(i) + "_ack_i,\n"
			port_buf = port_buf + "\ts" + str(i) + "_dat_o,\n"
			port_buf = port_buf + "\ts" + str(i) + "_dat_i,\n"
			port_buf = port_buf + "\ts" + str(i) + "_adr_o,\n"
			port_buf = port_buf + "\ts" + str(i) + "_int_i,\n"
			port_buf = port_buf + "\n\n"
			

		# port defines
		for i in range (0, num_slaves):
			port_def_buf = port_def_buf + "output\t\t\ts" + str(i) + "_we_o;\n"
			port_def_buf = port_def_buf + "output\t\t\ts" + str(i) + "_cyc_o;\n"
			port_def_buf = port_def_buf + "output\t\t\ts" + str(i) + "_stb_o;\n"
			port_def_buf = port_def_buf + "output\t[31:0]\ts" + str(i) + "_adr_o;\n"
			port_def_buf = port_def_buf + "output\t[31:0]\ts" + str(i) + "_dat_o;\n"
			port_def_buf = port_def_buf + "input\t[31:0]\ts" + str(i) + "_dat_i;\n"
			port_def_buf = port_def_buf + "input\t\t\ts" + str(i) + "_ack_i;\n"
			port_def_buf = port_def_buf + "input\t\t\ts" + str(i) + "_int_i;\n"
			port_def_buf = port_def_buf + "\n\n"
		
		#addresss
		for i in range(0, num_slaves):
			address_param_buf = address_param_buf + "parameter ADDR_" + str(i) + "\t=\t" + str(i) + "\n"
		
		#assign defines
		for i in range (0, num_slaves):
			assign_buf = assign_buf + "assign s" + str(i) + "_we_o\t=\t(slave_select == ADDR_" + str(i) + ") ? m_we_i: 0;\n"
			assign_buf = assign_buf + "assign s" + str(i) + "_stb_o\t=\t(slave_select == ADDR_" + str(i) + ") ? m_stb_i: 0;\n"
			assign_buf = assign_buf + "assign s" + str(i) + "_cyc_o\t=\t(slave_select == ADDR_" + str(i) + ") ? m_cyc_i: 0;\n"
			assign_buf = assign_buf + "assign s" + str(i) + "_adr_o\t=\t(slave_select == ADDR_" + str(i) + ") ? {8\'h0, m_adr_i[23:0]}: 0;\n"
			assign_buf = assign_buf + "assign s" + str(i) + "_dat_i\t=\t(slave_select == ADDR_" + str(i) + ") ? m_dat_i: 0;\n"
			assign_buf = assign_buf + "\n"

		#data in block
		data_block_buf = "//data in from slave\n"	
		data_block_buf = data_block_buf + "always @ (slave_select"
		for i in range (0, num_slaves):
			data_block_buf = data_block_buf + " or s" + str(i) + "_dat_i"
		data_block_buf = data_block_buf + ") begin\n\tcase (slave_select)\n"
		for i in range (0, num_slaves):
			data_block_buf = data_block_buf + "\t\tADDR_" + str(i) + ": begin\n\t\t\tm_dat_o = s" + str(i) + "_dat_i\n\t\tend\n";
		data_block_buf = data_block_buf + "\t\tdefault: begin\n\t\t\tm_dat_o <= 32\'hx;\n\t\tend\n\tendcase\nend\n\n"

		#ack in block
		ack_block_buf = "//ack in from slave\n\n"	
		ack_block_buf = ack_block_buf + "always @ (slave_select"
		for i in range (0, num_slaves):
			ack_block_buf = ack_block_buf + " or s" + str(i) + "_ack_i"
		ack_block_buf = ack_block_buf + ") begin\n\tcase (slave_select)\n"
		for i in range (0, num_slaves):
			ack_block_buf = ack_block_buf + "\t\tADDR_" + str(i) + ": begin\n\t\t\tm_ack_o = s" + str(i) + "_ack_i\n\t\tend\n";
		ack_block_buf = ack_block_buf + "\t\tdefault: begin\n\t\t\tm_ack_o <= x;\n\t\tend\n\tendcase\nend\n\n"


		#int in block
		int_block_buf = "//int in from slave\n\n"	
		int_block_buf = int_block_buf + "always @ (slave_select"
		for i in range (0, num_slaves):
			int_block_buf = int_block_buf + " or s" + str(i) + "_int_i"
		int_block_buf = int_block_buf + ") begin\n\tcase (slave_select)\n"
		for i in range (0, num_slaves):
			int_block_buf = int_block_buf + "\t\tADDR_" + str(i) + ": begin\n\t\t\tm_int_o = s" + str(i) + "_int_i\n\t\tend\n";
		int_block_buf = int_block_buf + "\t\tdefault: begin\n\t\t\tm_int_o <= x;\n\t\tend\n\tendcase\nend\n\n"


		buf = template.substitute(PORTS=port_buf, PORT_DEFINES=port_def_buf, ASSIGN=assign_buf, DATA=data_block_buf, ACK=ack_block_buf, INT=int_block_buf, ADDRESSES=address_param_buf)
		#print "buf: " + buf

		return buf

		def get_name (self):
			print "wishbone_interconnect.py"
