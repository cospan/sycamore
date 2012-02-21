//wb_fsmc.v
/*
Distributed under the MIT license.
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

/*
	10/29/2011
		-added an 'else' statement that so either the
		reset HDL will be executed or the actual code
		not both
*/

/*
	10/23/2011
		-fixed the wbs_ack_i to wbs_ack_o
		-added the default entries for read and write
			to illustrate the method of communication
		-added license
*/
/*
	9/10/2011
		-removed the duplicate wbs_dat_i
		-added the wbs_sel_i port
*/

/*
	Use this to tell sycamore how to populate the Device ROM table
	so that users can interact with your slave

	META DATA

	identification of your device 0 - 65536
	DRT_ID:  7

	flags (read drt.txt in the slave/device_rom_table directory 1 means
	a standard device
	DRT_FLAGS:  1

	number of registers this should be equal to the nubmer of ADDR_???
	parameters
	DRT_SIZE:  4

*/


module wb_fsmc (
	clk,
	rst,

	//Add signals to control your device here

	fsmc_adr,
	fsmc_dat,
	fsmc_ce_n,
	fsmc_we_n,
	fsmc_oe_n,
	fsmc_ub_n,
	fsmc_lb_n,

	wbs_we_i,
	wbs_cyc_i,
	wbs_sel_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,

	//wishbone master (for arbitrator)
	a_we_o,
	a_stb_o,
	a_cyc_o,
	a_sel_o,
	a_adr_o,
	a_dat_o,
	a_dat_i,
	a_ack_i,
	a_int_i


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

//master control signal for memory arbitration
output reg			a_we_o;
output reg			a_stb_o;
output reg			a_cyc_o;
output reg	[3:0]	a_sel_o;
output reg	[31:0]	a_adr_o;
output reg	[31:0]	a_dat_o;
input		[31:0]	a_dat_i;
input				a_ack_i;
input				a_int_i;


input		[15:0]	fsmc_adr;
inout		[15:0]	fsmc_dat;
input				fsmc_ce_n;
input				fsmc_we_n;
input				fsmc_oe_n;
input				fsmc_ub_n;
input				fsmc_lb_n;


parameter			ADDR_0	=	32'h00000000;
parameter			ADDR_1	=	32'h00000001;
parameter			ADDR_2	=	32'h00000002;
parameter			ADDR_3	=	32'h00000003;


reg			[31:0]	flags;
wire				manual_control;

//flag meaning
assign				manual_control	= flags[0];

reg			[31:0]	manual_tx_data;
reg			[31:0]	manual_rx_data;

wire				received;
wire				transmitted;
wire				transmit_request;
reg					transmit_ready;
wire				upper_word;
reg			[31:0]	tx_data;
wire		[31:0]	rx_data;	


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

	.received(received),
	.transmitted(transmitted),
	.transmit_request(transmit_request),
	.transmit_ready(transmit_ready),
	.upper_word(upper_word),
	.tx_data(tx_data),
	.rx_data(rx_data)

);

//blocks
always @ (posedge clk) begin
	if (rst) begin
		wbs_dat_o	<= 32'h0;
		wbs_ack_o	<= 0;
		wbs_int_o	<= 0;
		flags		<= 0;
		manual_tx_data	<= 0;
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
						flags	<= wbs_dat_i;
					end
					ADDR_1: begin
						//writing something to address 1
						//do something
	
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						manual_tx_data	<= wbs_dat_i;
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
						wbs_dat_o <= flags;
					end
					ADDR_1: begin
						//reading something from address 1
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user read %h", ADDR_1);
						wbs_dat_o <= manual_tx_data;
					end
					ADDR_2: begin
						//reading soething from address 2
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user read %h", ADDR_2);
						wbs_dat_o <= manual_rx_data;
					end
					ADDR_3: begin
						wbs_dat_o	<=	{16'h0000, fsmc_adr};
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


//wishbone master module
always @ (posedge clk) begin
	if (transmit_ready) begin
		transmit_ready	<= 0;
	end

	if (rst) begin
		a_we_o		<= 0;
		a_stb_o 	<= 0;
		a_cyc_o 	<= 0;
		a_sel_o 	<= 4'h0;
		a_adr_o		<= 32'h00000000;
		a_dat_o		<= 32'h00000000;
		transmit_ready	<= 0;
		manual_rx_data	<= 0;
	end
	else begin
		if (manual_control == 0) begin
			//need to wait to get data back from the wishbone mem device
			if (a_ack_i) begin
				$display ("got an ack!");
				a_stb_o	<= 0;
				a_cyc_o	<= 0;
				if (a_we_o == 0) begin
					tx_data	<= a_dat_i;
					transmit_ready <= 1;
				end
			end
			if (received) begin
				//received data from fsmc, now write this to the memory
				$display("enable a host write! at address %h of %h", fsmc_adr, rx_data);
				a_stb_o <= 1;
				a_cyc_o <= 1;
				if(upper_word) begin
					a_sel_o	<= 4'b1100;
				end
				else begin
					a_sel_o	<= 4'b0011;
				end
				a_we_o	<= 1;
				a_adr_o <= {16'h0000, fsmc_adr};
				a_dat_o <= rx_data;  
			end
			if(transmit_request) begin
				//fsmc is getting a request for data, get this data out of the memory
				$display("enable a host read at address %h", fsmc_adr);
				a_stb_o <= 1;
				a_cyc_o <= 1;
				if(upper_word) begin
					a_sel_o	<= 4'b1100;
				end
				else begin
					a_sel_o	<= 4'b0011;
				end
				a_we_o	<= 0;
				a_adr_o <= {16'h0000, fsmc_adr};
			end
		end
		else begin
			//transmitter is always ready to send data
			transmit_ready	<= 1;
			if (received) begin
				manual_rx_data	<= rx_data;
			end
		end
	end
end


endmodule
