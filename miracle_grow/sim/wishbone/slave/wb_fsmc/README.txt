Auto generated slave data

Files:
1. drt_rom_file.txt: example drt data file (using the DRT in the simulation is not implemented yet)
2. project_defines.v: a dependency file that is used primarily for DRT (not used right now)

3. wishbone_master_tb.v: main entry point for the code, this is the testbench used to exercise the code, it behaves as both a stimulus and and input/output interface to the wihbone master
4.Makefile: MAIN CONTROL point
	-'make': compiles generated slave files
	-'make sim': runs a simulation based on the "master_input_test_data.txt"
	-'make wave': opens up GTK wave and runs the "wave_script.tcl" in order to load the signals, feel free to mofiy this file in order to view your own signals
	-'make clean': clean everythin up

5. file_list.txt: a list of files that are fed into the Makefile to generate the simulation, some of the files will be the same used in an actual project (example: wishbone_main.v)
6. wave_script.tcl: a TCL script that is fed into gtkwave in order to load up the signals, feel free to modify this in order to add your own signals at start up

7. master_input_test_data.txt: this is the bus stimulus, it will behave similar to a real design input/output handler, you can ping the master, send data to/from peripheral or memory slaves
	format: for non write burst communication the format is always 4 double words that are send to the host
		AAAAAAAA:BBBBBBBB:CCCCCCCC:DDDDDDDD
			A: Number of double words to read or write, (for a single read or write, leave this to 0)
			B: Flags (top 16 bits)/Commands (bottom 16 bits)
				Flags:
					bit 1:
						0 = Peripheral
						1 = Memory
				Commands:
					0 = Ping
					1 = Write
					2 = Read
			C: Address: the default base location of the generated slave is at 0x01000000
				to write to register 0 of you slave enter 0x01000000, to write to address 1 0x01000001 etc...
				Note: for the memory bus, addresses should jump by 4 bytes, so first double word is at 0x01000000, address '2' 0x010000004
			D: Data to send to the device, right now Sycamore only supports sending 32 bits down at a time, but a combination of read/mask/write can be used to work around this
8. master_output_test_data.txt: output for the test (under construction) 
				


Simulation notes:

-Sometimes you need to view waveforms but you don't want to have to keep reloading 'make wave' because you may have manually added signals, the best practice I've found is to always have the gtkwave window open, and in the command window run 'make' then 'make sim' and then in your gtkwave press <ctrl + shift + r> and the signals will be reloaded 
-iVerilog is amazing, but it does have its flaws, I've found that iVerilog will let a lot of errors go that are caught by Xilinx's PlanAhead but this will get your code VERY far
