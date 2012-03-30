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


`timescale 1 ns/100 ps
`include "sdram_include.v"

module sdram_write (
	rst,
	clk,

	command,	
	addr,
	bank,
	data_out,
	data_mask,

	//sdram controller
	en,
	ready,
	address,
	auto_refresh,

	//FIFO in
	fifo_data,
	fifo_empty,
	fifo_rd
);

input				rst;
input				clk;

//RAM control
output	reg	[2:0]	command;
output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
output	reg	[15:0]	data_out;
output	reg	[1:0]	data_mask;

//sdram controller
input				en;
output				ready;
input		[21:0]	address;
input				auto_refresh;

//FIFO
input		[35:0]	fifo_data;
input				fifo_empty;
output	reg			fifo_rd;


parameter	IDLE				=	8'h0;
parameter	ACTIVE				=	8'h1;
parameter	WRITE_CMD			=	8'h2;
parameter	WRITE_TOP_WORD		=	8'h3;
parameter	WRITE_BOTTOM_WORD	=	8'h4;
parameter	PRECHARGE			=	8'h5;
parameter	FIFO_EMPTY_WAIT		=	8'h6;	
parameter	RESTART				=	8'h7;

reg		[7:0]			state;
reg		[15:0]			delay;


reg						lfifo_empty;
reg						lauto_refresh;
reg		[21:0]			laddress;

wire	[1:0]			w_bank;
wire	[11:0]			row;
wire	[7:0]			column;

assign	ready		=	((delay == 0) & (state == IDLE));
assign	w_bank		=	laddress[21:20];
assign	row			=	laddress[19:8];
assign	column		=	laddress[7:0];

always @ (negedge clk) begin
	if (rst) begin
		command			<=	`SDRAM_CMD_NOP; 
		addr			<=	12'h0;
		data_mask		<=	2'h0;

		state			<=	IDLE;

		lauto_refresh	<=	0;
		laddress		<=	0;
		lfifo_empty		<=	1;
		delay			<=	10;
		fifo_rd			<=	0;
		bank			<=	0;
	end
	else begin
		//auto refresh only goes high for one clock cycle
		//so capture it
//		data_out	<=	16'hZZZZ;
data_out	<=	16'h0000; 
		if (auto_refresh & en) begin
			//because en is high it is my responsibility
			lauto_refresh	<= 1;
		end
		fifo_rd		<= 0;

		if (delay > 0) begin
			delay	<= delay - 1;
			command	<= `SDRAM_CMD_NOP;
		end
		else begin
			case (state)
				IDLE: begin
					if (en & !fifo_empty) begin
						laddress		<= address;
						state			<= ACTIVE;
					end
					else if (lauto_refresh) begin
						state		<=	IDLE;	
						command		<=	`SDRAM_CMD_AR;
						delay		<=	`T_RFC - 1;
						lauto_refresh	<=	0;
					end
				end
				ACTIVE: begin
					$display ("sdram_write: ACTIVE");
					command 		<=	`SDRAM_CMD_ACT;
					delay			<=	`T_RCD - 1;
//addr	<=	12'h0;
//bank	<=	2'h0;

					addr			<=	row;
					bank			<=	w_bank;
					state			<=	WRITE_CMD;
					fifo_rd			<=	1;
				end
				WRITE_CMD: begin
					$display ("sdram_write: WRITE_CMD");
					command			<=	`SDRAM_CMD_WRITE;
//addr	<=	12'h0;
					addr			<=	{4'b0000, column};
					laddress		<=	laddress + 2;
					//disable auto precharge
					addr[10]		<=	0;

					lfifo_empty		<=	fifo_empty;
					state			<=	WRITE_BOTTOM_WORD;
//					data_mask		<=	fifo_data[35:34];
					data_out		<= 	fifo_data[31:16];
data_mask	<=	2'b00;
//data_out	<=	16'h1234;
					delay			<=	0;

				end
//				WRITE_TOP_WORD: begin
//					$display ("sdram_write: WRITE_TOP_WORD");
//					laddress		<=	laddress + 2;
//					lfifo_empty		<=	fifo_empty;
//					state			<=	WRITE_BOTTOM_WORD;
//					data_mask		<=	fifo_data[35:34];
//					data_out		<= 	fifo_data[31:16];
//					delay			<=	0;
//				end
				WRITE_BOTTOM_WORD: begin
					command			<= `SDRAM_CMD_NOP;
					$display ("sdram_write: WRITE_BOTTOM_WORD");
					data_out		<=	fifo_data[15:0];
//					data_mask		<=	fifo_data[33:32];
data_mask	<=	2'b00;
//data_out	<=	16'h5678;
					state			<=	PRECHARGE;
					delay			<=	0;
//					if (!lfifo_empty & !lauto_refresh) begin
//						state	<=	PRECHARGE;
		//				if (column	==	8'h00) begin
//							if (row == 8'h00) begin
		//						state	<=	PRECHARGE;
//							end
//							else begin
//								state	<= PRECHARGE;
//							end
		//				end
		//				else begin
		//					state	<= WRITE_TOP_WORD;
		//					fifo_rd	<=	1;
		//				end
//					end
//					else begin
						//go into a holding
//						state	<=	PRECHARGE;
//					end
				end
				PRECHARGE:	 begin
					command		<=	`SDRAM_CMD_PRE;
					delay		<=	`T_RP - 1;
					//precharge all banks (just for the first version)
					addr[10]	<=	1;
					if (!fifo_empty) begin
						state	<=	ACTIVE;
					end
					else begin
						state	<=	FIFO_EMPTY_WAIT;
						$display("sdram_write: go to FIFO_EMPTY_WAIT");
					end
				end
				FIFO_EMPTY_WAIT: begin
//					lfifo_empty	<= fifo_empty;
					if (lauto_refresh) begin
						$display("sdram_write: auto refresh");
						//state	<=	RESTART;
						command	<=	`SDRAM_CMD_AR;
						delay	<=	`T_RFC - 1;
						lauto_refresh	<=	0;
					end
					else if (!fifo_empty) begin
						$display ("\tdone waiting for the FIFO");
						$display ("\tstart a new write cycle");
						state	<= ACTIVE;	
					end
					else if (!en) begin
						$display("sdram_write: finished write state machine");
						state	<= IDLE;
					end

				end
/*
				RESTART: begin
					if (!fifo_empty & !lauto_refresh) begin
						state	<= ACTIVE;
					end
					else if (fifo_empty) begin
						//go into a holding
						state	<=	FIFO_EMPTY_WAIT;
					end
					else begin
						//execute the auto refresh and then
						//go to the RESTART state
						state	<=	RESTART;
						command	<=	`SDRAM_CMD_AR;
						delay	<=	`T_RFC - 1;
					end
	
				end
*/
				default: begin
					$display ("sdram_write: got to an unknown state");
					state	<= IDLE;
				end
			endcase
		end
	end
end

endmodule
