all:
	iverilog -o design -cfile_list.txt
faux_uart:
	iverilog -o design -cfaux/uart/file_list.txt
clean:
	rm design
	rm *.vcd
sim:
	vvp design
wave:
	iverilog -o design -cfile_list.txt
	vcd design
	gtkwave design.vcd -T wave_script.tcl &

