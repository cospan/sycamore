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


	reg 			clk = 0;
	reg 			rst = 0;

	wire 	[7:0]	data;
	reg 	[7:0] 	in_data;
	reg				txe_n;
	wire			wr_n;
	reg				rde_n;
	wire			rd_n;
	wire			oe_n;
	wire			siwu;

	
	
	//instantiate the uart
	ft245_sync_fifo sync_fifo(
		.clk(clk),
		.rst(rst),
		.data(data),
		.txe_n(txe_n),
		.wr_n(wr_n),
		.rde_n(rde_n),
		.rd_n(rd_n),
		.oe_n(oe_n),
		.siwu(siwu)
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

always @ (posedge clk) begin
	if (rst) begin
	end
	else begin
		//not in reset
	end
end

endmodule
