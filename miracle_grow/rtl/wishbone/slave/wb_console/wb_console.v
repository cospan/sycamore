//wb_console.v
/*
Distributed under the MIT license.
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
	11/02/2011
		-changed the DRT ID to 6
*/

/*
	Use this to tell sycamore how to populate the Device ROM table
	so that users can interact with your slave

	META DATA

	identification of your device 0 - 65536
	DRT_ID:6

	flags (read drt.txt in the slave/device_rom_table directory 1 means
	a standard device
	DRT_FLAGS:1

	number of registers this should be equal to the nubmer of ADDR_???
	parameters
	DRT_SIZE:3

*/


module wb_console (
	clk,
	rst,

	//Add signals to control your device here

	wbs_we_i,
	wbs_cyc_i,
	wbs_sel_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,

	fb_we_o,
	fb_stb_o,
	fb_cyc_o,
	fb_sel_o,
	fb_adr_o,
	fb_dat_o,
	fb_dat_i,
	fb_ack_i,
	fb_int_i
);

input 				clk;
input 				rst;

//wishbone slave signals
input 				wbs_we_i;
input 				wbs_stb_i;
input 				wbs_cyc_i;
input		[3:0]	wbs_sel_i;
input		[31:0]	wbs_adr_i;
input  		[31:0]	wbs_dat_i;
output reg  [31:0]	wbs_dat_o;
output reg			wbs_ack_o;
output reg			wbs_int_o;

//master control signal for arbitration
output reg			fb_we_o;
output reg			fb_stb_o;
output reg			fb_cyc_o;
output reg	[3:0]	fb_sel_o;
output reg	[31:0]	fb_adr_o;
output reg	[31:0]	fb_dat_o;
input		[31:0]	fb_dat_i;
input				fb_ack_i;
input				fb_int_i;

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

	else begin
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
						//do something
	
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user wrote %h", wbs_dat_i);
					end
					ADDR_1: begin
						//writing something to address 1
						//do something
	
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user wrote %h", wbs_dat_i);
					end
					ADDR_2: begin
						//writing something to address 3
						//do something
	
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user wrote %h", wbs_dat_i);
					end
					//add as many ADDR_X you need here
					default: begin
					end
				endcase
			end

			else begin 
				//read request
				case (wbs_adr_i)
					ADDR_0: begin
						//reading something from address 0
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user read %h", ADDR_0);
						wbs_dat_o <= ADDR_0;
					end
					ADDR_1: begin
						//reading something from address 1
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user read %h", ADDR_1);
						wbs_dat_o <= ADDR_1;
					end
					ADDR_2: begin
						//reading soething from address 2
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user read %h", ADDR_2);
						wbs_dat_o <= ADDR_2;
					end
					//add as many ADDR_X you need here
					default: begin
					end
				endcase
			end
			wbs_ack_o <= 1;
		end
	end
end


endmodule
