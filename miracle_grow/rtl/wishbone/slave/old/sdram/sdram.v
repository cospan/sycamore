//sdram.v

/*
 * 8/29/2011
 *	Generated Generic Slave
 *
 * 9/02/2011
 *	Attaching to ddr_controller.v
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

`define MEM_READ 0
`define MEM_WRITE 1

module sdram (
	clk,
	rst,

	wbs_we_i,
	wbs_cyc_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_i,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,

	mem_clk,
	mem_clk_n,
	mem_clk_fb,
	mem_cke,
	mem_cs,
	mem_ras,
	mem_cas,
	mem_we,
	mem_dm,
	mem_dqs,
	mem_ba,
	mem_addr,
	mem_data,

	debug_ddr_ready,
	debug
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

output				mem_clk;
output				mem_clk_n;
input				mem_clk_fb;
output				mem_cke;
output				mem_cs;
output				mem_ras;
output				mem_cas;
output				mem_we;
output [1:0]		mem_dm;
output [1:0]		mem_dqs;
output [1:0]		mem_ba;
output [22:0]		mem_addr;
inout [15:0]		mem_data;

output				debug_ddr_ready;
output	[7:0]		debug;

reg	[3:0]			user_cmd;
reg					user_cmd_vld;
reg	[23:0]			user_addr;
reg [31:0]			user_data_in;
reg					user_confirm;
wire [31:0]			user_data_out;
wire				user_data_out_vld;
wire				ddr_busy;
wire				ddr_ack;
wire				ddr_ready;

wire				dcm1_lock;
wire				dcm2_lock;


//debug signals
wire	ddr_2x_clk;
reg	ddr_clock_correct;
reg	ddr_2x_clock_correct;
reg	ddr_ack_correct;
reg	ddr_data_valid_correct;
reg	write_data_test;
reg	read_data_test;
reg	awesome;

assign	debug_ddr_ready	= ddr_ready;
assign	debug[0]	=	ddr_ready;
assign	debug[1]	=	write_data_test;
assign	debug[2]	=	read_data_test;
assign	debug[3]	=	ddr_ack_correct;
assign	debug[4]	=	ddr_data_valid_correct;
assign	debug[5]	=	dcm1_lock;
assign	debug[6]	=	dcm2_lock;
assign	debug[7]	=	awesome;

always @ (posedge ddr_2x_clk) begin
	if (rst) begin
		ddr_clock_correct		<= 0;
		ddr_2x_clock_correct	<= 0;
			end
	else begin
		//test whether the ddr_clock is 2X the normal clock rate (I don't have an oscilloscope that can handle that speed :(
		//test whether the ddr_2x_clock is 4x the normal clock rate

	end
end



ddr_controller ddr (
	.clk(clk),
	.rst(rst),

	.user_cmd(user_cmd),
	.user_cmd_vld(user_cmd_vld),
	.user_addr(user_addr),
	.user_data_in(user_data_in),
	.user_data_out(user_data_out),
	.user_data_out_vld(user_data_out_vld),
	.ddr_user_confirm(user_confirm),

	.ddr_busy(ddr_busy),
	.ddr_ack(ddr_ack),
	.ddr_ready(ddr_ready),
	
	.mem_clk(mem_clk),
	.mem_clk_n(mem_clk_n),
	.mem_cke(mem_cke),
	.mem_cs(mem_cs),
	.mem_ras(mem_ras),
	.mem_cas(mem_cas),
	.mem_we(mem_we),
	.mem_dm(mem_dm),
	.mem_dqs(mem_dqs),
	.mem_ba(mem_ba),
	.mem_addr(mem_addr),
	.mem_clk_fb(mem_clk_fb),
	.mem_data(mem_data),

	.ddr_2x_clk(ddr_2x_clk),
	.dcm1_lock(dcm1_lock),
	.dcm2_lock(dcm2_lock)
);

//this is an odd number and usually wont be called
parameter	ADDR_STATUS = 32'h00FFFFFF;
//blocks
always @ (posedge clk) begin
	user_cmd_vld	<= 0;
	user_confirm	<= 0;
	if (ddr_ack) begin
		//user_cmd		<= 0;
	end
	if (rst) begin
		wbs_dat_o	<= 32'h0;
		wbs_ack_o	<= 0;
		wbs_int_o	<= 0;

		user_cmd		<= 0;
		user_cmd_vld	<= 0;

		user_addr	<= 24'h0;
		user_data_in	<= 31'h0;
		ddr_ack_correct			<= 0;
		ddr_data_valid_correct	<= 0;
		read_data_test			<=	0;
		write_data_test			<= 0;

	end

	//when the master acks our ack, then put our ack down
	if (wbs_ack_o & ~ wbs_stb_i)begin
		wbs_ack_o <= 0;
	end

	//Initiating an interaction with the ddr_controller
	if (wbs_stb_i & wbs_cyc_i) begin
		user_addr	<= wbs_adr_i;	
		//master is requesting somethign
		if (wbs_we_i) begin
			//write request
			if (~ddr_ready) begin
				wbs_dat_o	<= 32'hFFFFFFFF;
				wbs_ack_o		<= 1;
			end
			else begin
				user_data_in	<= wbs_dat_i;
				if (wbs_dat_i == 32'h00001EAF) begin
					write_data_test <= ~write_data_test;	
				end
				user_cmd		<= `MEM_WRITE;
				user_cmd_vld	<= 1;
			end
		end

		else begin 
			if (wbs_adr_i == ADDR_STATUS) begin
				wbs_dat_o		<= 0;
				wbs_dat_o[0]	<= ddr_ready;
				wbs_dat_o[1]	<= ddr_ack;
				wbs_dat_o[2]	<= ddr_busy;
			end
			else begin
				//read request
				if (ddr_ready) begin
					user_cmd		<= `MEM_READ;
					user_cmd_vld	<= 1;
				end
			end
		end
	end

	//response from the ddr_controller
	if ((user_cmd	== `MEM_WRITE) && (ddr_ack)) begin
		wbs_ack_o	<= 1;	
		ddr_ack_correct	<= ~ddr_ack_correct;
		user_confirm	<= 1;
	end
	else if ((user_cmd == `MEM_READ) && (user_data_out_vld)) begin
		wbs_ack_o	<= 1;
		ddr_data_valid_correct	<= ~ddr_data_valid_correct;
		wbs_dat_o	<= user_data_out;
		user_confirm	<= 1;
		if (user_data_out == 32'h0000000) begin
			read_data_test	<= ~read_data_test;
		end
		if (user_data_out == 32'h00001EAF) begin
			awesome			<= ~awesome;
		end
	end
end

endmodule
