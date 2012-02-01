
set signals [list]


lappend signals "__HI__"
lappend signals "ft245_sync_top_tb.clk"
lappend	signals "ft245_sync_top_tb.rst"

lappend signals "__BREAK__"
lappend signals "ft245_sync_top_tb.ftdi_clk"
#uncomment the below line for debug
#lappend signals "wishbone_master_tb.state"




#add the DUT signals, add your own signals by following the format
#lappend signals "wishbone_master_tb.s1.wbs_we_i"
#lappend signals "wishbone_master_tb.s1.wbs_cyc_i"
#lappend signals "wishbone_master_tb.s1.wbs_ack_i"
#lappend signals "wishbone_master_tb.s1.wbs_stb_o"

set num_added [gtkwave::addSignalsFromList $signals]
set min_time [gtkwave::getMinTime]
set max_time [gtkwave::getMaxTime]
gtkwave::setZoomRangeTimes $min_time $max_time
gtkwave::setLeftJustifySigs on
