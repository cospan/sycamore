all:
	iverilog -o design -cfile_list.txt
clean:
	rm design
	rm *.vcd
sim:
	vvp design
wave:
	iverilog -o design -cfile_list.txt
	vcd design
	gtkwave design.vcd -T wave_script.tcl &

