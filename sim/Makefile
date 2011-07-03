all:
	iverilog -o design -cfile_list.txt
uart_sim:
	iverilog -o design -cuart/file_list.txt
clean:
	rm design
	rm *.vcd
sim:
	vvp design
wave:
	vvp design
	gtkwave design.vcd -T wave_script.tcl &

