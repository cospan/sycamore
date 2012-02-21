//wishbone_interconnect_tb.v
/*
Distributed under the MIT licesnse.
Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

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

/**
 * Test the 2 port wishbone interconnect
 * 
 *  there are two fo the GPIO ports attached to the intereconnect,
 *  the design can be tested out in a similar manner as the individual GPIO slave
 *
 *  Tests: 
    1) test that I can successfully write to GPIO slave 1
 *      -set the addr 0 GPIO mask to all F's
 *      -write an output to GPIO addr, read the outputted value on both the GPIO's
 *          to confirm that the write was just to one of them
 *
 *  2) repeat test 1 on port 2
 *
 */
`define INPUT_FILE "wi_input.txt"
`define OUTPUT_FILE "wi_output.txt"

module wishbone_interconnect_tb (
);

//test signals
reg			clk	= 0;
reg			rst = 0;

//wishbone signals
reg			wbm_we_i;
reg			wbm_cyc_i;
reg			wbm_stb_i;
reg	[31:0]	wbm_adr_i;
reg	[31:0]	wbm_dat_i;
wire [31:0]	wbm_dat_o;
wire		wbm_ack_o;
wire		wbm_int_o;

//wishbone slave 0 signals
wire		wbs0_we_i;
wire		wbs0_cyc_i;
wire[31:0]	wbs0_dat_i;
wire		wbs0_stb_i;
wire		wbs0_ack_o;
wire [31:0]	wbs0_dat_o;
wire [31:0]	wbs0_adr_o;
wire		wbs0_int_o;

reg	[31:0]	gpio0_in;
wire [31:0]	gpio0_out;


//wishbone slave 1 signals
wire		wbs1_we_i;
wire		wbs1_cyc_i;
wire[31:0]	wbs1_dat_i;
wire		wbs1_stb_i;
wire		wbs1_ack_o;
wire [31:0]	wbs1_dat_o;
wire [31:0]	wbs1_adr_o;
wire		wbs1_int_o;

reg [31:0]  gpio1_in;
wire [31:0] gpio1_out;

//slave 0
simple_gpio sg0 (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(wbs0_we_o),
	.wbs_cyc_i(wbs0_cyc_o),
	.wbs_dat_i(wbs0_dat_o),
	.wbs_stb_i(wbs0_stb_o),
	.wbs_ack_o(wbs0_ack_i),
	.wbs_dat_o(wbs0_dat_i),
	.wbs_adr_i(wbs0_adr_o),
	.wbs_int_o(wbs0_int_i),

	.gpio_in(gpio0_in),
	.gpio_out(gpio0_out)
);

//slave 1
simple_gpio sg1 (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(wbs1_we_o),
	.wbs_cyc_i(wbs1_cyc_o),
	.wbs_dat_i(wbs1_dat_o),
	.wbs_stb_i(wbs1_stb_o),
	.wbs_ack_o(wbs1_ack_i),
	.wbs_dat_o(wbs1_dat_i),
	.wbs_adr_i(wbs1_adr_o),
	.wbs_int_o(wbs1_int_i),

	.gpio_in(gpio1_in),
	.gpio_out(gpio1_out)
);

wishbone_interconnect wi (
    .clk(clk),
    .rst(rst),

    .m_we_i(wbm_we_i),
    .m_cyc_i(wbm_cyc_i),
    .m_stb_i(wbm_stb_i),
    .m_ack_o(wbm_ack_o),
    .m_dat_i(wbm_dat_i),
    .m_dat_o(wbm_dat_o),
    .m_adr_i(wbm_adr_i),
    .m_int_o(wbm_int_o),

    .s0_we_o(wbs0_we_o),
    .s0_cyc_o(wbs0_cyc_o),
    .s0_stb_o(wbs0_stb_o),
    .s0_ack_i(wbs0_ack_i),
    .s0_dat_o(wbs0_dat_o),
    .s0_dat_i(wbs0_dat_i),
    .s0_adr_o(wbs0_adr_o),
    .s0_int_i(wbs0_int_i),

    .s1_we_o(wbs1_we_o),
    .s1_cyc_o(wbs1_cyc_o),
    .s1_stb_o(wbs1_stb_o),
    .s1_ack_i(wbs1_ack_i),
    .s1_dat_o(wbs1_dat_o),
    .s1_dat_i(wbs1_dat_i),
    .s1_adr_o(wbs1_adr_o),
    .s1_int_i(wbs1_int_i)

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
	$dumpvars(0, wishbone_interconnect_tb);
	$dumpvars(0, wi);
    $dumpvars(0, sg0);
    $dumpvars(0, sg1);
	fd_in = $fopen(`INPUT_FILE, "r");
	fd_out = $fopen(`OUTPUT_FILE, "w");


	rst			<= 0;
	#2

	rst 	<= 1;
	wbm_we_i	<= 0;
	wbm_cyc_i	<= 0;
	wbm_dat_i	<= 32'h0;
	wbm_stb_i	<= 0;
	wbm_adr_i	<= 32'h0;

	gpio0_in			<= 32'h0;
    gpio1_in            <= 32'h0;

	#2
	rst <= 0;
	#2
	gpio0_in	<= 32'hAAAAAAAA;
    gpio1_in    <= 32'hFFFFFFFF;
	#2

    //read the state of the GPIO
	wbm_adr_i	<= 32'h00000000;
	#4
	wbm_stb_i <= 1;
	wbm_cyc_i <= 1;
	#8
	while (!wbm_ack_o) begin
		#1
		rst <= 0;
	end
	wbm_stb_i <= 0;
	wbm_cyc_i <= 0;

	#4

	$display ("gpio0_in value: %h", gpio0_in);
	$display ("data0 read from simple gpio: %h", wbm_dat_o);


    //end
	$fclose(fd_in);
	$fclose(fd_out);
	$finish();

end
/*
initial begin
    $monitor("%t: addr: %h", $time, wbm_adr_i);
end
*/
endmodule
