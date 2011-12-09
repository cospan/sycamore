//uart_top_tb.v
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

`include "project_defines.v"
`define BAUD_RATE 9600
`define PRESCALER 8 

`define CLOCK_DIVIDE `CLOCK_RATE / (`BAUD_RATE * `PRESCALER)

`define HALF_PERIOD (`PRESCALER / 2 * `CLOCK_DIVIDE)
`define FULL_PERIOD (`PRESCALER * `CLOCK_DIVIDE)


module fsmc_top_tb; 


	reg clk = 0;
	reg rst = 0;

	reg [15:0]	delay		= 0;
	reg			delay_finished = 0;
	reg			hp_delay	= 0;
	reg			fp_delay	= 0;

	reg	[15:0]	fsmc_adr	=	0;	
	wire [15:0]	fsmc_dat;
	reg [15:0]	fsmc_dat_o	=	0;
	wire [15:0]	fsmc_dat_i;
	reg			fsmc_dat_en	=	0;
	reg			fsmc_ce_n	=	1;
	reg			fsmc_we_n	=	1;
	reg			fsmc_oe_n	=	1;
	reg			fsmc_ub_n	=	1;
	reg			fsmc_lb_n	=	1;

	wire [31:0]	wb_adr_o;
	wire [31:0]	wb_dat_o;
	reg [31:0]	wb_dat_i	=	32'h0;
	wire [3:0]	wb_sel_o;
	wire		wb_cyc_o;
	wire		wb_we_o;
	wire		wb_stb_o;
	reg			wb_ack_i	=	0;


	assign fsmc_dat = (fsmc_dat_en) ? fsmc_dat_o : 16'hZ;
	assign fsmc_dat_i = fsmc_dat;

	fsmc_module fsmc (
		.clk(clk),
		.rst(rst),

		.fsmc_adr(fsmc_adr),
		.fsmc_dat(fsmc_dat),
		.fsmc_ce_n(fsmc_ce_n),
		.fsmc_we_n(fsmc_we_n),
		.fsmc_oe_n(fsmc_oe_n),
		.fsmc_ub_n(fsmc_ub_n),
		.fsmc_lb_n(fsmc_lb_n),

		.wb_adr_o(wb_adr_o),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.wb_sel_o(wb_sel_o),
		.wb_cyc_o(wb_cyc_o),
		.wb_we_o(wb_we_o),
		.wb_stb_o(wb_stb_o),
		.wb_ack_i(wb_ack_i)
	);

	integer fd_in;
	integer fd_out;
	reg [7:0] ch = 0;
	reg [3:0]	bit_index =0;

	always #1 clk = ~clk;

	
initial begin

	ch 		= 0;

	$dumpfile ("design.vcd");
	$dumpvars (0, fsmc_top_tb);
	//fd_out = $fopen ("uart/uart_output_data.txt", "r");

	rst 					<= 0;	
	#5
	rst 					<= 1;
	hp_delay				<= 0;
	fp_delay				<= 0;

	fsmc_adr				<=	0;	
	fsmc_dat_en				<=	1;
	fsmc_dat_o				<=	0;
	fsmc_ce_n				<=	1;
	fsmc_we_n				<=	1;
	fsmc_oe_n				<=	1;
	fsmc_ub_n				<=	1;
	fsmc_lb_n				<=	1;

	wb_dat_i				<= 	32'h0;
	wb_ack_i				<=	0;


	#5
	rst 					<= 0;
	#10

	//testing fsmc write

	#10

	//send a word to the lower address bits
	//(Should output 0x00005555 to addres 0x0000AAAA)
	fsmc_ce_n	<=	0;
	fsmc_we_n	<= 	0;
	fsmc_oe_n	<=	1;
	fsmc_ub_n	<=	1;
	fsmc_lb_n	<= 	0;
	fsmc_adr	<=	16'hAAAA;
	fsmc_dat_en	<= 	1;
	fsmc_dat_o	<=	16'h5555;

	#10
	$display ("Read %h on Wishbone", wb_dat_o);
	wb_ack_i	<=	1;
	#10
	wb_ack_i	<= 	0;
	#10
	fsmc_ce_n	<= 1;
	fsmc_we_n	<= 1;
	fsmc_oe_n	<= 1;
	fsmc_ub_n	<= 1;
	fsmc_lb_n	<= 1;
	#10
	

	//send a word to the uppder address bits
	//(Should output 0x55550000 to addres 0x00005555)
	fsmc_ce_n	<= 0;	
	fsmc_we_n	<= 0;
	fsmc_oe_n	<= 1;
	fsmc_ub_n	<= 0;
	fsmc_lb_n	<= 1;
	fsmc_adr	<= 16'h5555;
	fsmc_dat_en	<= 1;
	fsmc_dat_o	<= 16'hAAAA;

	#10
	$display ("Read %h on Wishbone", wb_dat_o);
	wb_ack_i	<=	1;
	#10
	wb_ack_i	<= 	0;
	#10
	fsmc_ce_n	<= 1;
	fsmc_we_n	<= 1;
	fsmc_oe_n	<= 1;
	fsmc_ub_n	<= 1;
	fsmc_lb_n	<= 1;
	#10
	

	//data to read
	wb_dat_i	<= 32'hFEDCBA98;
	//read a word from the lower space (should read BA98)
	fsmc_ce_n	<= 0;
	fsmc_we_n	<= 1;
	fsmc_oe_n	<= 0;
	fsmc_ub_n	<= 1;
	fsmc_lb_n	<= 0;
	fsmc_adr	<= 16'h1234;
	fsmc_dat_en	<= 0;
	#10
	wb_ack_i	<= 1;
	#10
	wb_ack_i	<= 0;
	#10
	fsmc_ce_n	<= 1;
	fsmc_we_n	<= 1;
	fsmc_oe_n	<= 1;
	fsmc_ub_n	<= 1;
	fsmc_lb_n	<= 1;
	$display("read %h from the FSMC Read", fsmc_dat_i);
	#10
	

	//read a word from the upper space (should read FEDC)
	fsmc_ce_n	<= 0;
	fsmc_we_n	<= 1;
	fsmc_oe_n	<= 0;
	fsmc_ub_n	<= 0;
	fsmc_lb_n	<= 1;
	fsmc_adr	<= 16'h9876;
	fsmc_dat_en	<= 0;
	#10
	wb_ack_i	<= 1;
	#10
	wb_ack_i	<= 0;
	#10
	fsmc_ce_n	<= 1;
	fsmc_we_n	<= 1;
	fsmc_oe_n	<= 1;
	fsmc_ub_n	<= 1;
	fsmc_lb_n	<= 1;
	$display("read %h from the FSMC Read", fsmc_dat_i);
	#10

	#10
	$finish;
end

always @ (posedge clk) begin
	if (rst) begin
		delay <= 16'h0;
		delay_finished	<= 0;
	end
	else begin
		if (delay > 0) begin
			delay <= delay - 1;
			delay_finished	<= 0;
		end
		else begin
			delay_finished	<= 1;
			if (fp_delay) begin
				$display ("full period wait");
				delay	<= `FULL_PERIOD;
			end
			else if (hp_delay) begin
				$display ("half period wait");
				delay	<= `HALF_PERIOD;
			end
		end
	end
end

endmodule
