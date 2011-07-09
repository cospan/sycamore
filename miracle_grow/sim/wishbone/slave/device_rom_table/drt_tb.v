//drt_tb.v
/*
Distributed under the MIT licesnse.
Copyright (c) 2011 Dave McCoy (dave.mccoy@leaflabs.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/

`define INPUT_FILE "drt_input.txt"
`define OUTPUT_FILE "drt_output.txt"
module drt_tb (
);

//defparam drt.DRT_NUM_OF_DEVICES = 1;

//test signals
reg			clk	= 0;
reg			rst = 0;

//wishbone signals
reg			wbs_we_i;
reg			wbs_cyc_i;
reg	[31:0]	wbs_dat_i;
reg			wbs_stb_i;
wire		wbs_ack_o;
wire [31:0]	wbs_dat_o;
reg	[31:0]	wbs_adr_i;
wire		wbs_int_o;

device_rom_table drt (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(wbs_we_i),
	.wbs_cyc_i(wbs_cyc_i),
	.wbs_dat_i(wbs_dat_i),
	.wbs_stb_i(wbs_stb_i),
	.wbs_ack_o(wbs_ack_o),
	.wbs_dat_o(wbs_dat_o),
	.wbs_adr_i(wbs_adr_i),
	.wbs_int_o(wbs_int_o)
);

integer fd_in;
integer fd_out;
integer read_count;
integer timeout_count;
integer ch;

integer data_count;
integer	i;

reg [15:0] version;
reg [15:0] id;

reg [31:0] num_of_devices;

reg	[31:0] device1_flags;
reg [31:0] device1_id;
reg [31:0] device1_offset;
reg [31:0] device1_size;


always #1 clk = ~clk;


initial begin

	$dumpfile("design.vcd");
	$dumpvars(0, drt_tb);
	$dumpvars(0, drt);
	fd_in = $fopen(`INPUT_FILE, "r");
	fd_out = $fopen(`OUTPUT_FILE, "w");


	rst			<= 0;
	#4

	rst 	<= 1;
	wbs_we_i	<= 0;
	wbs_cyc_i	<= 0;
	wbs_dat_i	<= 32'h0;
	wbs_stb_i	<= 0;
	wbs_adr_i	<= 32'h0;

	version		<= 16'h0;
	id			<= 16'h0;
	num_of_devices 	<= 32'h0;
	device1_flags	<= 32'h0;
	device1_offset	<= 32'h0;
	device1_size	<= 32'h0;

	#4
	rst <= 0;
	#4

	//use wishbone a virtual master ro read all the data from the ROM
	

	//we are guaranteed the first four words
	//read the version and ID
	wbs_adr_i	<= 32'h00000000;
	#2
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;

	version	<= wbs_dat_o[31:16];
	id		<= wbs_dat_o[15:0];

	#2

	//read the number of devices attached
	wbs_adr_i	<= 32'h00000001;
	#2
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;

	num_of_devices	<= wbs_dat_o;

	#2
	//read the 1st device ID's
	wbs_adr_i	<= 32'h00000004;
	#2
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;
	device1_id	<= wbs_dat_o;

	#2
	//read the 1st device flags
	wbs_adr_i	<= 32'h00000005;
	#2
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;

	device1_flags	<= wbs_dat_o;

	#2
	//read the 1st device base offset
	wbs_adr_i	<= 32'h00000006;
	#2
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;

	device1_offset	<= wbs_dat_o;

	#2

	//read the 1st device sie
	wbs_adr_i	<= 32'h00000007;
	#2
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;

	device1_size	<= wbs_dat_o;

	#2

	$display ("ID: %h", id);
	$display ("Version:	%h", version);
	$display ("Device 1 ID:	%h", device1_id);
	$display ("Device 1 flags: %h", device1_flags);
	$display ("Device 1 offset: %h", device1_offset);
	$display ("Device 1 size: %h", device1_size);

	//end
	$fclose(fd_in);
	$fclose(fd_out);
	$finish();
end
endmodule
