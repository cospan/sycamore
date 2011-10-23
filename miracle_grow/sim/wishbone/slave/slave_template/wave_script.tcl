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

#add the DUT signals, add your own signals by following the format
#lappend signals "wishbone_master_tb.s1.wbs_we_i"
#lappend signals "wishbone_master_tb.s1.wbs_cyc_i"
#lappend signals "wishbone_master_tb.s1.wbs_ack_i"
#lappend signals "wishbone_master_tb.s1.wbs_stb_o"
lappend signals "wishbone_master_tb.s1.wbs_adr_i"
lappend signals "wishbone_master_tb.s1.wbs_dat_i"
lappend signals "wishbone_master_tb.s1.wbs_dat_o"
lappend signals "wishbone_master_tb.s1.wbs_int_i"

set num_added [gtkwave::addSignalsFromList $signals]

