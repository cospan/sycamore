//ddr_controller.v

/*
 * 8/29/2011
 *	initial
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

module ddr_controller (
	clk,
	rst,

	cmd,
	cmd_vld,

	addr,
	busy,

	data_in,
	data_req,
	data_out,
	data_valid,

	mem_clk,
	mem_clk_n,
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

	ddr_ready
);

parameter DDR_DATA_SIZE = 16;
parameter DDR_ADDR_SIZE = 23;


parameter INIT_200US_DELAY = 50 * 200;
parameter OPTIONAL_LMR = 0;

input 			rst;
input 			clk;

input [4:0] 	cmd;
input 			cmd_vld;

input [31:0] 	addr;
output			busy;

input [31:0] 	data_in;
output 			data_req;
output [31:0] 	data_out;
output 			data_vld;

output			mem_clk;
output			mem_clk_n;
output			mem_cke;
output			mem_cs;
output			mem_ras;
output			mem_cas;
output			mem_we;
output			mem_dm;
output			mem_dqs;
output			mem_ba;
output [23:0]	mem_addr;
output [15:0]	mem_data;

output reg		ddr_ready;


parameter 		CMD_DSEL	=	4'h0;
parameter 		CMD_NOP		=	4'h1;
parameter 		CMD_LMR		=	4'h2;
parameter 		CMD_ACT		=	4'h3;
parameter 		CMD_READ	=	4'h4;
parameter		CMD_WRITE	=	4'h5;
parameter		CMD_PRE		=	4'h6;
parameter		CMD_BST		=	4'h7;
parameter		CMD_AR		=	4'h8;
parameter		CMD_SREF	=	4'h9;


parameter		OP_INIT		=	4'h0;
parameter		OP_REG_DEF	=	4'h1;
parameter		OP_ACT		=	4'h2;
parameter		OP_READ		=	4'h3;
parameter		OP_WRITE	=	4'h4;
parameter		OP_PRE		=	4'h5;
parameter		OP_AR		=	4'h6;
parameter		OP_SREF		=	4'h7;
parameter		OP_PWR_DN	=	4'h8;


//Initialization sequence
reg	[7:0]		state;

//STATE_0: Reset
parameter		STATE_00	=	8'h00;
//STATE_01: CKE goes LVCMOS Low
parameter		STATE_01	=	8'h01;
//STATE_02: Apply stable clocks
parameter		STATE_02	=	8'h02;
//STATE_03: Wait 200uS
parameter		STATE_03	=	8'h03;
//STATE_04: CKE goes high with NOP
parameter		STATE_04	=	8'h04;
//STATE_05: Precharge All
parameter		STATE_05	=	8'h05;
//STATE_06: Assert NOP or Deselect for tRP time
parameter		STATE_06	=	8'h06;
//STATE_07: Configure Extended mode register
parameter		STATE_07	=	8'h07;
//STATE_08: Assert NOP or Deselect tMRD time
parameter		STATE_08	=	8'h08;
//STATE_09: Configure load mode register and reset DLL
parameter		STATE_09	=	8'h09;
//STATE_0A: Assert NOP or Deselect for tMRD time
parameter		STATE_0A	=	8'h0A;
//STATE_0B: Precharge All
parameter		STATE_0B	=	8'h0B;
//STATE_0C: Assert NOP or Deselect for tRP time
parameter		STATE_0C	=	8'h0C;
//STATE_0D: Issue Auto Refresh command
parameter		STATE_0D	=	8'h0D;
//STATE_0E: Assert NOP or Deselect commands for tRFC
parameter		STATE_0E	=	8'h0E;
//STATE_0F: Issue Auto Refresh command
parameter		STATE_0F	=	8'h0F;
//STATE_10: Assert NOP or Deselect for tRFC time
parameter		STATE_10	=	8'h10;
//STATE_11: Optional LMR command to clear DLL bit
parameter		STATE_11	=	8'h11;
//STATE_12: Assert NOP or Deselect for tMRD time
parameter		STATE_12	=	8'h12;

//STATE_DDR_READY
parameter		STATE_RDY	=	8'h14;

//this should be controlled by user to initialize the RAM again
reg			init;
reg	[31:0]	count;

//50 MHz Clocks
always @ (posedge clk) begin
	if (rst) begin
		state		<=	STATE_0;
		init		<=	1;

		mem_cke		<=	0;
		mem_cs		<=	1;
		mem_ras		<= 	0;
		mem_cas		<=	0;
		mem_we		<=	0;
		mem_dm		<= 	0;
		mem_dqs		<= 	0;
		mem_ba		<= 	0;	
		mem_addr 	<= 	0;
		mem_data 	<= 	0;
		ddr_ready	<=	0;
	end
	else begin
		case (state) begin
			STATE_00: begin
				//keep the system in reset
				if (init) begin
					state	<= STATE_01;
				end
			end
			STATE_01: begin
				//CKE goes LVCMOS low

				//Transition:
					//when CKE goes low then
					//state	<= STATE_02;
			end
			STATE_02: begin
				//Apply stable clocks
				//wait for DCM clocks to lock
				count	<= 0;	
				//Transition
					//if (dcm_lock) begin
					//state		<= STATE_3;
					//end
			end
			STATE_03:
				//Wait 200uS
				if (count >= INIT_200US_DELAY) begin
					//Transition
						//waited 200uS
					state	<= STATE_04;
				end
				else begin
					count	<= count + 1;
				end
			end
			STATE_04: begin
				//CKE goes up with NOP
				//mem_cke		<= 1;
				//Transition
					//CKE is high
					//state	<= STATE_O5;
			end
			STATE_05: begin
				//Precharge command
				//Transition
					//once precharge is done
					//state	<= STATE_06;
			end
			STATE_06: begin
				//Assert NOP
				//wait for tRP
				//Transition
					//once the NOP is done
					//state	<= STATE_07;
			end
			STATE_07: begin
				//Configure Extended Mode Register
				//Transition
					//once the configuration is done
					//state <= STATE_08;
			end
			STATE_08: begin
				//Assert NOP
				//wait for tMRD
				//once the NOP is done
				//Transition
					//finished NOP
					//state	<= STATE_09;
			end
			STATE_09: begin
				//Configure load mode register
				//reset DLL
				//Transition
					//finished command
					//state	<= STATE_0A;
			end
			STATE_0A: begin
				//Assert NOP
				//wait for tMRD
				//Transition
					//finished command
					//state	<= STATE_0B;
			end
			STATE_0B: begin
				//Precharge All
				//Transition
					//Finish command
					//state <= STATE_0C;
			end
			STATE_0C: begin
				//Assert NOP
				//wait for tRP
				//Transition
					//finish command
					//state	<= STATE_0D;
			end
			STATE_0D: begin
				//Issue Auto Refresh command
				//Transition
					//finish command
					//state	<= STATE_0E;
			end
			STATE_0E: begin
				//Assert NOP
				//wait for tRFC
				//Transition
					//finish count
					//state	<= STATE_0F;
			end
			STATE_0F: begin
				//Assert NOP
				//wait for tRFC time
				//Transition
					//finish count
					//state <= STATE_10;
			end
			STATE_10: begin
				//optional LMR comman to clear DLL bit
				//wait for command to finish
			end
			STATE_11: begin
				if (OPTIONAL_LMR) begin
				end
				state	<= STATE_12;

			end
			STATE_12: begin
				//Assert NOP
				//wait for tMRD time
				//Transition
					//finish count
					//state <= STATE_READY;
			end
			STATE_RDY: begin
				//if reset command send back to STATE_0
				//now issue user commands, and tell the user that we are ready
				ddr_ready	<= 1;
			end

			default: begin
			end
		endcase
	end
end
endmodule
