//uart_top_tb.v
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

`include "project_defines.v"

module ft245_sync_top_tb; 


	reg 			clk			=	0;
	reg 			rst			=	0;

	wire 	[7:0]	data;
	reg 	[7:0] 	in_data;
	reg				txe_n;
	wire			wr_n;
	reg				rde_n;
	wire			rd_n;
	wire			oe_n;
	wire			siwu;

	wire			ftdi_clk;

	reg		[31:0]	host_data_in;
	reg				host_rd;
	wire			host_empty;

	wire	[31:0]	host_data_out;
	reg				host_wr;
	wire			host_full;

	
	//instantiate the uart
	ft245_sync_fifo sync_fifo(
		.rst(rst),
		.ftdi_clk(ftdi_clk),
		.ftdi_data(data),
		.ftdi_txe_n(txe_n),
		.ftdi_wr_n(wr_n),
		.ftdi_rde_n(rde_n),
		.ftdi_rd_n(rd_n),
		.ftdi_oe_n(oe_n),
		.ftdi_siwu(siwu),

		.hi_clk(clk),
		.hi_data_in(host_data_in),
		.hi_rd(host_rd),
		.hi_empty(host_empty),
		
		.hi_data_out(host_data_out),
		.hi_wr(host_wr),
		.hi_full(host_full)
	);


integer ch;
integer fd_in;
integer fd_out;



initial begin

	ch 		= 0;
	$dumpfile ("design.vcd");
	$dumpvars (0, ft245_sync_top_tb);
	fd_in = $fopen ("fsync_input_data.txt", "r");

	//testing input
	if (fd_in == 0) begin
		$display("fsync_input_data.txt was not found");
	end	
	else begin
	end
	#10000
	$finish;
end

//virtual FTDI chip
always @ (posedge ftdi_clk) begin
	if (rst) begin
		txe_n	<= 1;
		rde_n	<= 1;
	end
	else begin
		//not in reset
	end
end


//host_interface
always @ (posedge clk) begin
	if (rst) begin
		host_data_in	<= 32'h0;
		host_rd			<= 0;
		
		host_wr			<= 0;
	end
	else begin
		//not in reset
	end
end

endmodule
