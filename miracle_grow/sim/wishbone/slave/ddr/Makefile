all:
	iverilog -o design -cfile_list.txt
clean:
	rm design
	rm *.vcd
go_sim:
	vvp design
wave:
	vvp design
	gtkwave design.vcd -T wave_script.tcl &

