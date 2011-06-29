all:
	iverilog -o design -cfile_list.txt
clean:
	rm design
sim:
	vvp design
wave:
	iverilog -o design -cfile_list.txt
	vvp design
	gtkwave design.vcd -T wave_script.tcl &

