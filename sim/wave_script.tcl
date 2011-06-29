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

lappend signals "output_handler_tb.clk"
lappend	signals "output_handler_tb.rst"
lappend signals "output_handler_tb.byte"


set num_added [gtkwave::addSignalsFromList $signals]

