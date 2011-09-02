#set d[gtkwave::getDisplayedSignals]
#puts "$d"

#foreach item d {
#	puts $item;
#}

set signals [list]

#lappend signals "input_handler_tb.clk"
#lappend signals "input_handler_tb.byte"
#lappend signals "input_handler_tb.byte_available"
#lappend signals "input_handler_tb.ready"


lappend signals "wishbone_master_tb.clk"
lappend	signals "wishbone_master_tb.rst"
lappend signals "wishbone_master_tb.in_command"
lappend signals "wishbone_master_tb.ram.local_usr_cmd_vld"
lappend signals "wishbone_master_tb.ram.vld_pos_edge"

lappend signals "wishbone_master_tb.ram.ddr.ddr_clk"
lappend signals "wishbone_master_tb.ram.ddr.ddr_2x_clk"
lappend signals "wishbone_master_tb.ram.ddr.init_state"
lappend signals "wishbone_master_tb.ram.ddr.ddr_cmd_state"
lappend signals "wishbone_master_tb.ram.ddr_cmd_count"
lappend signals "wishbone_master_tb.ram.mem_clk"
lappend signals "wishbone_master_tb.ram.mem_ba"
lappend signals "wishbone_master_tb.ram.mem_addr"
lappend signals "wishbone_master_tb.ram.mem_cke"
lappend signals "wishbone_master_tb.ram.mem_cs"
lappend signals "wishbone_master_tb.ram.mem_ras"
lappend signals "wishbone_master_tb.ram.mem_cas"
lappend signals "wishbone_master_tb.ram.mem_we"


set num_added [gtkwave::addSignalsFromList $signals]

