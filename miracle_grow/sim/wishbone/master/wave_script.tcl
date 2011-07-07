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


#lappend signals "ih.r_STATE"
#lappend signals "ih.command"
#lappend signals "ih.data_count"
#lappend	signals "ih.r_low_byte"
#lappend signals "ih.buffer"
#lappend signals "ih.r_count"

lappend signals "wishbone_master_tb.clk"
lappend	signals "wishbone_master_tb.rst"
lappend signals "wishbone_master_tb.in_command"
lappend signals "wishbone_master_tb.in_ready"
lappend signals "wishbone_master_tb.out_en"


set num_added [gtkwave::addSignalsFromList $signals]

