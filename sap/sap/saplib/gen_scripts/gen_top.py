from gen import Gen
import saputils
from string import Template

class GenTop(Gen):
	"""Generate the top module for a project"""

	def __init__(self):
		print "in GenTop"
		self.wires=[]
		self.tags = {}
		return

	def add_ports_to_wires(self):
		"""add all the ports to wires list so that no item adds wires"""
		#bindings = self.tags["CONSTRAINTS"]["bind"]
		for name in self.bindings.keys():
			self.wires.append(self.bindings[name]["port"])


	def generate_ports(self):
		"""create the ports string"""
		port_buf = ""
		#bindings = self.tags["CONSTRAINTS"]["bind"]
		for name in self.bindings.keys():
			port_name = self.bindings[name]["port"]
			if (port_name.__contains__("[") and port_name.__contains__(":")):
				port_name = "[" + port_name.partition("[")[2] + "\t" + port_name.partition("[")[0]
				port_buf = port_buf + "\t" + self.bindings[name]["direction"] + "\t" + port_name + ";\n"
			else:
				port_buf = port_buf + "\t" + self.bindings[name]["direction"] + "\t\t" + port_name + ";\n"

		return port_buf
				

	def gen_script (self, tags = {}, buf = "", debug = False):
		"""Generate the Top Module"""
		en_mem_bus = False
		slave_list = tags["SLAVES"]
		if "MEMORY" in tags:
#			if debug:
#				print "Found a memory bus"
			if (len(tags["MEMORY"]) > 0):
#				if debug:
				print "found " + str(len(tags["MEMORY"])) + " memory devices"
				en_mem_bus = True

		num_slaves = len(slave_list) + 1
		self.tags = tags
		self.bindings = self.tags["CONSTRAINTS"]["bind"]
		if debug:
			print "found " + str(len(slave_list)) + " slaves"
			for slave in slave_list:
				print slave

		#remove all the ports from the possible wires
		self.add_ports_to_wires()

		template = Template(buf)

		header = ""
		port_buf = self.generate_ports()
		wr_buf = ""
		wi_buf = ""
		wmi_buf = ""
		wm_buf = ""
		footer = ""

		header = "module top (\n"
		#header = header + "\tclk_in,\n"
		header = header + "\tclk,\n"
		header = header + "\trst,\n"

		#bindings = tags["CONSTRAINTS"]["bind"]
		for c_index in range(0, len(self.bindings.keys())):
			name = self.bindings.keys()[c_index]	
			header = header + "\t" + self.bindings[name]["port"]
			if (c_index < len(self.bindings.keys()) - 1):
				header = header + ","
			header = header + "\n"

		header = header + ");"
		
		footer = "endmodule"
		#declare the ports
		#in the future utilize the constraints to generate the connections

		#declare the wires
		wr_buf = wr_buf + "\t//inupt handler signals\n"
		#wr_buf = wr_buf + "\tinput\t\tclk_in;\n"
		wr_buf = wr_buf + "\tinput\t\tclk;\n"
		#wr_buf = wr_buf + "\twire\t\tclk;\n"
		self.wires.append("clk")
		#self.wires.append("clk_in")
		wr_buf = wr_buf + "\tinput\t\trst;\n"
		self.wires.append("rst")
		wr_buf = wr_buf + "\twire\t[31:0]\tin_command;\n"
		self.wires.append("in_command")
		wr_buf = wr_buf + "\twire\t[31:0]\tin_address;\n"
		self.wires.append("in_address")
		wr_buf = wr_buf + "\twire\t[31:0]\tin_data;\n"
		self.wires.append("in_data")
		wr_buf = wr_buf + "\twire\t[27:0]\tin_data_count;\n"
		self.wires.append("in_data_count")
		wr_buf = wr_buf + "\twire\t\tih_ready;\n\n"
		self.wires.append("ih_ready")

		wr_buf = wr_buf + "\t//output handler signals\n"
		wr_buf = wr_buf + "\twire\t[31:0]\tout_status;\n"
		self.wires.append("out_status")
		wr_buf = wr_buf + "\twire\t[31:0]\tout_address;\n"
		self.wires.append("out_address")
		wr_buf = wr_buf + "\twire\t[31:0]\tout_data;\n"
		self.wires.append("out_data")
		wr_buf = wr_buf + "\twire\t[27:0]\tout_data_count;\n"
		self.wires.append("out_data_count")
		wr_buf = wr_buf + "\twire\t\toh_ready;\n"
		self.wires.append("oh_ready")
		wr_buf = wr_buf + "\twire\t\toh_en;\n\n"
		self.wires.append("oh_en")

		wr_buf = wr_buf + "\t//master signals\n"
		wr_buf = wr_buf + "\twire\t\tmaster_ready;\n"
		self.wires.append("master_ready")
		wr_buf = wr_buf + "\twire\t\twbm_we_o;\n"
		self.wires.append("wbm_we_o")
		wr_buf = wr_buf + "\twire\t\twbm_cyc_o;\n"	
		self.wires.append("wbm_cyc_o")
		wr_buf = wr_buf + "\twire\t\twbm_stb_o;\n"
		self.wires.append("wbm_stb_o")
		wr_buf = wr_buf + "\twire\t[3:0]\twbm_sel_o;\n"
		self.wires.append("wbm_sel_o")
		wr_buf = wr_buf + "\twire\t[31:0]\twbm_adr_o;\n"
		self.wires.append("wbm_adr_o")
		wr_buf = wr_buf + "\twire\t[31:0]\twbm_dat_i;\n"
		self.wires.append("wbm_dat_i")
		wr_buf = wr_buf + "\twire\t[31:0]\twbm_dat_o;\n"
		self.wires.append("wbm_dat_o")
		wr_buf = wr_buf + "\twire\t\twbm_ack_i;\n"
		self.wires.append("wbm_ack_i")
		wr_buf = wr_buf + "\twire\t\twbm_int_i;\n\n"
		self.wires.append("wbm_int_i")

		wr_buf = wr_buf + "\twire\t\tmem_we_o;\n"
		self.wires.append("mem_we_o")
		wr_buf = wr_buf + "\twire\t\tmem_cyc_o;\n"	
		self.wires.append("mem_cyc_o")
		wr_buf = wr_buf + "\twire\t\tmem_stb_o;\n"
		self.wires.append("mem_stb_o")
		wr_buf = wr_buf + "\twire\t[3:0]\tmem_sel_o;\n"
		self.wires.append("mem_sel_o")
		wr_buf = wr_buf + "\twire\t[31:0]\tmem_adr_o;\n"
		self.wires.append("mem_adr_o")
		wr_buf = wr_buf + "\twire\t[31:0]\tmem_dat_i;\n"
		self.wires.append("mem_dat_i")
		wr_buf = wr_buf + "\twire\t[31:0]\tmem_dat_o;\n"
		self.wires.append("mem_dat_o")
		wr_buf = wr_buf + "\twire\t\tmem_ack_i;\n"
		self.wires.append("mem_ack_i")
		wr_buf = wr_buf + "\twire\t\tmem_int_i;\n\n"
		self.wires.append("mem_int_i")


		#put the in clock on the global buffer
		#wr_buf = wr_buf + "\t//add a global clock buffer to the input clock\n"
		#wr_buf = wr_buf + "\tIBUFG clk_ibuf(.I(clk_in), .O(clk));\n\n"

		wr_buf = wr_buf + "\t//slave signals\n\n"

		for i in range (0, num_slaves):
			wr_buf = wr_buf + "\t//slave " + str(i) + "\n"
			wr_buf = wr_buf + "\twire\t\ts" + str(i) + "_wbs_we_i;\n" 
			self.wires.append("s" + str(i) + "_wbs_we_i")
			wr_buf = wr_buf + "\twire\t\ts" + str(i) + "_wbs_cyc_i;\n" 
			self.wires.append("s" + str(i) + "_wbs_cyc_i")
			wr_buf = wr_buf + "\twire\t[31:0]\ts" + str(i) + "_wbs_dat_i;\n"
			self.wires.append("s" + str(i) + "_wbs_dat_i")
			wr_buf = wr_buf + "\twire\t[31:0]\ts" + str(i) + "_wbs_dat_o;\n" 
			self.wires.append("s" + str(i) + "_wbs_dat_o")
			wr_buf = wr_buf + "\twire\t[31:0]\ts" + str(i) + "_wbs_adr_i;\n" 
			self.wires.append("s" + str(i) + "_wbs_adr_i")
			wr_buf = wr_buf + "\twire\t\ts" + str(i) + "_wbs_stb_i;\n" 
			self.wires.append("s" + str(i) + "_wbs_stb_i")
			wr_buf = wr_buf + "\twire\t[3:0]\ts" + str(i) + "_wbs_sel_i;\n" 
			self.wires.append("s" + str(i) + "_wbs_sel_i")
			wr_buf = wr_buf + "\twire\t\ts" + str(i) + "_wbs_ack_o;\n" 
			self.wires.append("s" + str(i) + "_wbs_ack_o")
			wr_buf = wr_buf + "\twire\t\ts" + str(i) + "_wbs_int_o;\n\n" 
			self.wires.append("s" + str(i) + "_wbs_int_o")


		if (en_mem_bus):
			for i in range (0, len(tags["MEMORY"])):
				wr_buf = wr_buf + "\t//mem slave " + str(i) + "\n"
				wr_buf = wr_buf + "\twire\t\tsm" + str(i) + "_wbs_we_i;\n" 
				self.wires.append("sm" + str(i) + "_wbs_we_i")
				wr_buf = wr_buf + "\twire\t\tsm" + str(i) + "_wbs_cyc_i;\n" 
				self.wires.append("sm" + str(i) + "_wbs_cyc_i")
				wr_buf = wr_buf + "\twire\t[31:0]\tsm" + str(i) + "_wbs_dat_i;\n"
				self.wires.append("sm" + str(i) + "_wbs_dat_i")
				wr_buf = wr_buf + "\twire\t[31:0]\tsm" + str(i) + "_wbs_dat_o;\n" 
				self.wires.append("sm" + str(i) + "_wbs_dat_o")
				wr_buf = wr_buf + "\twire\t[31:0]\tsm" + str(i) + "_wbs_adr_i;\n" 
				self.wires.append("sm" + str(i) + "_wbs_adr_i")
				wr_buf = wr_buf + "\twire\t\tsm" + str(i) + "_wbs_stb_i;\n" 
				self.wires.append("sm" + str(i) + "_wbs_stb_i")
				wr_buf = wr_buf + "\twire\t[3:0]\tsm" + str(i) + "_wbs_sel_i;\n" 
				self.wires.append("sm" + str(i) + "_wbs_sel_i")
				wr_buf = wr_buf + "\twire\t\tsm" + str(i) + "_wbs_ack_o;\n" 
				self.wires.append("sm" + str(i) + "_wbs_ack_o")
				wr_buf = wr_buf + "\twire\t\tsm" + str(i) + "_wbs_int_o;\n\n" 
				self.wires.append("sm" + str(i) + "_wbs_int_o")


		if debug:
			print "wr_buf: \n" + wr_buf

		
		#generate the IO handler
		io_filename = tags["INTERFACE"]
		absfilepath = saputils.find_rtl_file_location(io_filename)
		io_tags = saputils.get_module_tags(filename = absfilepath, bus = "wishbone")

		io_buf = self.generate_buffer(name = "io", module_tags = io_tags)


		
		#for the FPGA
			#constraints can be a dictionary with the mappings from device
			#to input/output/inout multidimensional values

#this should just be file with text that I can pull in, it will always be
#the same!
		#instantiate the connection interface
			#should this be another script that is clled within here?
			#can I extrapolate the required information directly from the
			#file?

		#interconnect
		wi_buf = "\twishbone_interconnect wi (\n"

		wi_buf = wi_buf + "\t.clk(clk),\n"
		wi_buf = wi_buf + "\t.rst(rst),\n\n"

		wi_buf = wi_buf + "\t//master\n"
		wi_buf = wi_buf + "\t.m_we_i(wbm_we_o),\n"
		wi_buf = wi_buf + "\t.m_cyc_i(wbm_cyc_o),\n"
		wi_buf = wi_buf + "\t.m_stb_i(wbm_stb_o),\n"
		wi_buf = wi_buf + "\t.m_sel_i(wbm_sel_o),\n"
		wi_buf = wi_buf + "\t.m_ack_o(wbm_ack_i),\n"
		wi_buf = wi_buf + "\t.m_dat_i(wbm_dat_o),\n"
		wi_buf = wi_buf + "\t.m_dat_o(wbm_dat_i),\n"
		wi_buf = wi_buf + "\t.m_adr_i(wbm_adr_o),\n"
		wi_buf = wi_buf + "\t.m_int_o(wbm_int_i),\n\n"

		for i in range (0, num_slaves):
			wi_buf = wi_buf + "\t//slave " + str(i) + "\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_we_o (s" + str(i) + "_wbs_we_i),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_cyc_o(s" + str(i) + "_wbs_cyc_i),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_stb_o(s" + str(i) + "_wbs_stb_i),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_sel_o(s" + str(i) + "_wbs_sel_i),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_ack_i(s" + str(i) + "_wbs_ack_o),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_dat_o(s" + str(i) + "_wbs_dat_i),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_dat_i(s" + str(i) + "_wbs_dat_o),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_adr_o(s" + str(i) + "_wbs_adr_i),\n"
			wi_buf = wi_buf + "\t.s" + str(i) + "_int_i(s" + str(i) + "_wbs_int_o)"

			if (i < num_slaves - 1):
				wi_buf = wi_buf + ",\n"
				
			wi_buf = wi_buf + "\n\n"

		wi_buf = wi_buf + "\t);"
	
		if debug:
			print "wi_buf: \n" + wi_buf



		#memory interconnect
		if en_mem_bus:
			print "make the membus"
			wmi_buf = "\twishbone_mem_interconnect wmi (\n"

			wmi_buf = wmi_buf + "\t.clk(clk),\n"
			wmi_buf = wmi_buf + "\t.rst(rst),\n\n"

			wmi_buf = wmi_buf + "\t//master\n"
			wmi_buf = wmi_buf + "\t.m_we_i(mem_we_o),\n"
			wmi_buf = wmi_buf + "\t.m_cyc_i(mem_cyc_o),\n"
			wmi_buf = wmi_buf + "\t.m_stb_i(mem_stb_o),\n"
			wmi_buf = wmi_buf + "\t.m_sel_i(mem_sel_o),\n"
			wmi_buf = wmi_buf + "\t.m_ack_o(mem_ack_i),\n"
			wmi_buf = wmi_buf + "\t.m_dat_i(mem_dat_o),\n"
			wmi_buf = wmi_buf + "\t.m_dat_o(mem_dat_i),\n"
			wmi_buf = wmi_buf + "\t.m_adr_i(mem_adr_o),\n"
			wmi_buf = wmi_buf + "\t.m_int_o(mem_int_i),\n\n"

			for i in range (0, len(tags["MEMORY"])):
				wmi_buf = wmi_buf + "\t//slave " + str(i) + "\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_we_o(sm" + str(i) + "_wbs_we_i),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_cyc_o(sm" + str(i) + "_wbs_cyc_i),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_stb_o(sm" + str(i) + "_wbs_stb_i),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_sel_o(sm" + str(i) + "_wbs_sel_i),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_ack_i(sm" + str(i) + "_wbs_ack_o),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_dat_o(sm" + str(i) + "_wbs_dat_i),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_dat_i(sm" + str(i) + "_wbs_dat_o),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_adr_o(sm" + str(i) + "_wbs_adr_i),\n"
				wmi_buf = wmi_buf + "\t.s" + str(i) + "_int_i(sm" + str(i) + "_wbs_int_o)"

				if (i < num_slaves - 1):
					wmi_buf = wmi_buf + ",\n"
				
				wmi_buf = wmi_buf + "\n\n"

			wmi_buf = wmi_buf + "\t);"
	
			if debug:
				print "wmi_buf: \n" + wmi_buf



		#instantiate the io handler
		
		#instantiate the master
		wm_buf = wm_buf + "\twishbone_master wm (\n"
		wm_buf = wm_buf + "\t.clk(clk),\n"
		wm_buf = wm_buf + "\t.rst(rst),\n\n"

		wm_buf = wm_buf + "\t//input handler signals\n"
		wm_buf = wm_buf + "\t.in_ready(ih_ready),\n"
		wm_buf = wm_buf + "\t.in_command(in_command),\n"
		wm_buf = wm_buf + "\t.in_address(in_address),\n"
		wm_buf = wm_buf + "\t.in_data(in_data),\n\n"

		wm_buf = wm_buf + "\t//output handler signals\n"
		wm_buf = wm_buf + "\t.out_ready(oh_ready),\n"
		wm_buf = wm_buf + "\t.out_en(oh_en),\n"
		wm_buf = wm_buf + "\t.out_status(out_status),\n"
		wm_buf = wm_buf + "\t.out_address(out_address),\n"
		wm_buf = wm_buf + "\t.out_data(out_data),\n"
		wm_buf = wm_buf + "\t.out_data_count(out_data_count),\n"
		wm_buf = wm_buf + "\t.master_ready(master_ready),\n\n"
		
		wm_buf = wm_buf + "\t//interconnect signals\n"
		wm_buf = wm_buf + "\t.wb_adr_o(wbm_adr_o),\n"
		wm_buf = wm_buf + "\t.wb_dat_o(wbm_dat_o),\n"
		wm_buf = wm_buf + "\t.wb_dat_i(wbm_dat_i),\n"
		wm_buf = wm_buf + "\t.wb_stb_o(wbm_stb_o),\n"
		wm_buf = wm_buf + "\t.wb_cyc_o(wbm_cyc_o),\n"
		wm_buf = wm_buf + "\t.wb_we_o(wbm_we_o),\n"
		wm_buf = wm_buf + "\t.wb_msk_o(wbm_msk_o),\n"
		wm_buf = wm_buf + "\t.wb_sel_o(wbm_sel_o),\n"
		wm_buf = wm_buf + "\t.wb_ack_i(wbm_ack_i),\n"
		wm_buf = wm_buf + "\t.wb_int_i(wbm_int_i),\n\n"
	
		wm_buf = wm_buf + "\t//memory interconnect signals\n"
		wm_buf = wm_buf + "\t.mem_adr_o(mem_adr_o),\n"
		wm_buf = wm_buf + "\t.mem_dat_o(mem_dat_o),\n"
		wm_buf = wm_buf + "\t.mem_dat_i(mem_dat_i),\n"
		wm_buf = wm_buf + "\t.mem_stb_o(mem_stb_o),\n"
		wm_buf = wm_buf + "\t.mem_cyc_o(mem_cyc_o),\n"
		wm_buf = wm_buf + "\t.mem_we_o(mem_we_o),\n"
		wm_buf = wm_buf + "\t.mem_msk_o(mem_msk_o),\n"
		wm_buf = wm_buf + "\t.mem_sel_o(mem_sel_o),\n"
		wm_buf = wm_buf + "\t.mem_ack_i(mem_ack_i),\n"
		wm_buf = wm_buf + "\t.mem_int_i(mem_int_i)\n\n"
		wm_buf = wm_buf + "\t);"

		if debug:
			print "wm_buf: \n" + wm_buf



		#Slaves
		slave_index = 0
		slave_buffer_list = []
		absfilename = saputils.find_rtl_file_location("device_rom_table.v")
		slave_tags = saputils.get_module_tags(filename = absfilename, bus="wishbone")
		slave_buf = self.generate_buffer(name="drt", index=0, module_tags = slave_tags)
		slave_buffer_list.append(slave_buf)
		
		for i in range (0, len(tags["SLAVES"])):
			slave_name = tags["SLAVES"].keys()[i]
			slave = tags["SLAVES"][slave_name]["filename"]	
			if debug:
				print "Slave name: " + slave
			absfilename = saputils.find_rtl_file_location(slave)
			slave_tags = saputils.get_module_tags(filename = absfilename, bus="wishbone")
			slave_buf = self.generate_buffer(name = slave_name, index = i + 1, module_tags = slave_tags)
			slave_buffer_list.append(slave_buf)	


		#Memory devices
		mem_buf = ""
		mem_buffer_list = []
		if en_mem_bus:
			#need to make all the memory devices for the memory bus
			mem_index = 0
			mem_buffer_list = []
			for i in range (0, len(tags["MEMORY"])):
				mem_name = tags["MEMORY"].keys()[i]
				filename = tags["MEMORY"][mem_name]["filename"]
#				if debug:
				print "Mem device: " + mem_name + ", mem file: " + filename
				absfilename = saputils.find_rtl_file_location(filename)
				mem_tags = saputils.get_module_tags(filename = absfilename, bus="wishbone")
				mem_buf = self.generate_buffer(name = mem_name, index = i, module_tags = mem_tags, mem_slave = True)
				mem_buffer_list.append(mem_buf)

	
		buf_bind = ""
		#Generate the bindings
		if (len(self.bindings.keys()) > 0):
			buf_bind = buf_bind + "\t//assigns\n"
			for key in self.bindings.keys():
				if (self.bindings[key]["direction"] == "input"):
					buf_bind = buf_bind + "\tassign\t" + key + "\t=\t" + self.bindings[key]["port"] + ";\n"
				elif (self.bindings[key]["direction"] == "output"):
					buf_bind = buf_bind + "\tassign\t" + self.bindings[key]["port"] + "\t=\t" + key + ";\n"


		
		
		top_buffer = header + "\n\n"
		top_buffer += port_buf + "\n\n"
		top_buffer += wr_buf + "\n\n"
		top_buffer += io_buf + "\n\n"
		top_buffer += wi_buf + "\n\n"
		top_buffer += wmi_buf + "\n\n"
		top_buffer += wm_buf + "\n\n"
		for slave_buf in slave_buffer_list:
			top_buffer = top_buffer + "\n\n" + slave_buf

		for mem_buf in mem_buffer_list: 
			top_buffer = top_buffer + "\n\n" + mem_buf

		top_buffer = top_buffer + "\n\n" + buf_bind + "\n\n" + footer
		return top_buffer

	def generate_buffer(self, name="", index=-1, module_tags={}, mem_slave = False, debug = False):
		"""Generate a buffer that attaches wishbone signals and 
		return a buffer that can be used to generate the top module"""

		out_buf = ""

		out_buf = "\t//" + name + "( " + module_tags["module"] + " )\n\n"
		out_buf = out_buf + "\t//wires\n"
		#if index == -1 then don't add an index
		#top_name will apply to all signals

		#go through each of hte module tags, and extrapolate the ports

		#generate the wires
		io_types = [
			"input",
			"output",
			"inout"
		]

		#add a prename to all the slaves
		pre_name = ""
		if (index != -1):
			if mem_slave:
				pre_name += "sm" + str(index) + "_"
			else:
				pre_name += "s" + str(index) + "_"


		for io in io_types:
			for port in module_tags["ports"][io].keys():
				pdict = module_tags["ports"][io][port]
				if ((len(name) > 0) and (index != -1)):
					wire = pre_name + port
					if (wire in self.wires):
						continue
				if (port in self.wires):
#					print "found redundant wire: " + port
					continue
				self.wires.append(port)
				out_buf = out_buf + "\twire"
				#if the size is greater than one add it
				if (pdict["size"] > 1):
					out_buf = out_buf + "\t[" + str(pdict["max_val"]) + ":" + str(pdict["min_val"]) + "]\t\t"
				else:
					out_buf = out_buf + "\t\t"

				#add name and index if required
				if (len(name) > 0):
#				if ((len(name) > 0) and (index != -1)):
#					if (port.startswith(name)):	
#						out_buf = out_buf + name + str(index) + port.partition(name)[2]
#					else:
					if (port == "clk" or port == "rst"):
						out_buf += port
					else:
						out_buf += name + "_" + port
#				else:
#					if (port == "clk" or port == "rst"):
#						out_buf = out_buf + port
#					else:
#						out_buf = out_buf + pre_name + port
				out_buf = out_buf + ";\n"

		out_buf = out_buf + "\n\n"
		#Finished Generating the Wires



		#Generate the instantiation
		out_buf = out_buf + "\t" + module_tags["module"] + " " + name
#		if (index != -1):
#			out_buf = out_buf + str(index)

		out_buf = out_buf + "(\n"
		
		pindex = 0
		last = len(module_tags["ports"]["input"].keys())
		last = last + len(module_tags["ports"]["output"].keys())
		last = last + len(module_tags["ports"]["inout"].keys())

		#add the port assignments
		for io in io_types:
			for port in module_tags["ports"][io].keys(): 
				pdict = module_tags["ports"][io][port]
				out_buf = out_buf + "\t\t." + port + "(" 			

				found_binding = False
				inout_binding = ""
				if (io == "inout"):
					if debug:
						print "found inout!: " + port
					bkeys = self.bindings.keys()
					for bkey in bkeys:
						name = bkey.partition("[")[0]
						name = name.strip()
						if (name == (pre_name + port)):
							if debug:
								print "found: " + bkey
							out_buf = out_buf + self.bindings[bkey]["port"]
							found_binding = True

				if( not found_binding):
					#add name and index if required
					if ((len(name) > 0) and (index != -1)):
						if (port.startswith(name)):	
							out_buf = out_buf + name + str(index) + port.partition(name)[2]
						else:
							if (port == "clk" or port == "rst"):
								out_buf = out_buf + port
							else:
								out_buf = out_buf + pre_name + port
							
					else:
						if (port == "clk" or port == "rst"):
							out_buf = out_buf + port
						else:
							out_buf = out_buf + pre_name +  port
				out_buf = out_buf + ")"
				pindex = pindex + 1
				if (pindex == last):
					out_buf = out_buf + "\n"
				else:
					out_buf = out_buf + ",\n"

		out_buf = out_buf + "\t);"

		return out_buf

	def get_name (self):
		print "generate top!"
