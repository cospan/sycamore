//simple_gpio_tb.v

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

`define INPUT_FILE "simple_gpio_input.txt"
`define OUTPUT_FILE "simple_gpio_output.txt"
module simple_gpio_tb (
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

reg	[31:0]	gpio_in;
wire [31:0]	gpio_out;

simple_gpio sg (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(wbs_we_i),
	.wbs_cyc_i(wbs_cyc_i),
	.wbs_dat_i(wbs_dat_i),
	.wbs_stb_i(wbs_stb_i),
	.wbs_ack_o(wbs_ack_o),
	.wbs_dat_o(wbs_dat_o),
	.wbs_adr_i(wbs_adr_i),
	.wbs_int_o(wbs_int_o),

	.gpio_in(gpio_in),
	.gpio_out(gpio_out)
);

integer fd_in;
integer fd_out;
integer read_count;
integer timeout_count;
integer ch;

integer data_count;
integer	i;

always #1 clk = ~clk;


initial begin

	$dumpfile("design.vcd");
	$dumpvars(0, simple_gpio_tb);
	$dumpvars(0, sg);
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

	gpio_in			<= 32'h0;

	#4
	rst <= 0;
	#4
	gpio_in	<= 32'hF0E1D2E3;
	#4

	//read the state of the GPIO
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

	#4

	$display ("gpio_in value: %h", gpio_in);
	$display ("data read from simple gpio: %h", wbs_dat_o);

	//write the mask value
	wbs_adr_i	<= 32'h00000001;
	wbs_dat_i	<= 32'h0000FFFF;
	#4
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	wbs_we_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;
	wbs_we_i 	<= 0;
	#4

	//read the state of the mask
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
	wbs_we_i 	<= 0;
	#4
	$display ("mask value is 0x0000FFFF");
	$display ("value read back from mask: %h", wbs_dat_i);
	
	//write a value to the output
	wbs_adr_i	<= 32'h00000000;
	wbs_dat_i	<= 32'hFFFFFFFF;
	#4
	wbs_stb_i <= 1;
	wbs_cyc_i <= 1;
	wbs_we_i <= 1;
	#2
	while (!wbs_ack_o) begin
		#1
		rst <= 0;
	end
	wbs_stb_i <= 0;
	wbs_cyc_i <= 0;
	wbs_we_i 	<= 0;
	#4

	//loop what was just written to the output back in on the input
	gpio_in	<= gpio_out;
	#4
	$display ("%h", gpio_out);
	$display ("%h", gpio_in);
	#4
	
	//read the state of gpio
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

	#4



	$display ("wrote 0xFFFFFFFF with a mask of 0x0000FFFF to the output");
	$display ("read back %h", wbs_dat_o);

	//end
	$fclose(fd_in);
	$fclose(fd_out);
	$finish();
end
endmodule
