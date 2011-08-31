//sdram.v

/*
 * 8/29/2011
 *	importing the opencores SDRAM controller
 *
 */

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


/*
	META DATA
	DRT_ID: 5
	DRT_FLAGS:1
	DRT_SIZE:3

*/


module sdram (
	clk,
	rst,

	wbs_we_i,
	wbs_cyc_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o;
	wbs_dat_i;
	wbs_dat_o,
	wbs_adr_i;
	wbs_int_o;
);

input 				clk;
input 				rst;

//wishbone slave signals
input 				wbs_we_i;
input 				wbs_stb_i;
input 				wbs_cyc_i;
input		[31:0]	wbs_adr_i;
input  		[31:0]	wbs_dat_i;
output reg  [31:0]	wbs_dat_o;
output reg			wbs_ack_o;
output reg			wbs_int_o;

parameter			ADDR_0	=	32'h00000000;
parameter			ADDR_1	=	32'h00000001;
parameter			ADDR_2	=	32'h00000002;

//blocks
always @ (posedge clk) begin
	if (rst) begin
		wbs_dat_o	<= 32'h0;
		wbs_ack_o	<= 0;
		wbs_int_o	<= 0;
	end

	//when the master acks our ack, then put our ack down
	if (wbs_ack_o & ~ wbs_stb_i)begin
		wbs_ack_o <= 0;
	end

	if (wbs_stb_i & wbs_cyc_i) begin
		//master is requesting somethign
		if (wbs_we_i) begin
			//write request
			case (wbs_adr_i) 
				ADDR_0: begin
					//writing something to address 0
				end
				ADDR_1: begin
					//writing something to address 1
				end
				ADDR_2: begin
					//writing something to address 3
				end
				default: begin
				end
				//ADDRESS DEFINE : begin

				//	do something
				//end
			endcase
		end

		else begin 
			//read request
			case (wbs_adr_i)
				ADDR_0: begin
					//reading something from address 0
				end
				ADDR_1: begin
					//reading something from address 1
				end
				ADDR_2: begin
					//reading soething from address 2
				end
				default: begin
				end
			endcase
		end
		wbs_ack_i;
	end
end


endmodule
