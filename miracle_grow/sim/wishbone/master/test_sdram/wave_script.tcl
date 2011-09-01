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
lappend signals "fb.send_frame"
lappend signals "fb.core.vis_x_pos"
lappend signals "fb.core.vis_y_pos"
lappend signals "disp_en"
lappend signals "vsync"
lappend signals "hsync"
lappend	signals "data_en"
lappend signals "pclk"
lappend signals "red"
lappend signals "green"
lappend signals "blue"


set num_added [gtkwave::addSignalsFromList $signals]

