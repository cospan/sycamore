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



`include "sdram_include.v"


module sdram (
	clk,
	rst,

	wr_fifo_wr,
	wr_fifo_data,
	wr_fifo_mask,
	wr_fifo_full,


	rd_fifo_rd,
	rd_fifo_data,
	rd_fifo_empty,
	rd_fifo_reset,

	//Wishbone command
	write_en,
	read_en,
	sdram_ready,
	address,

	sd_clk,
	cs_n,
	cke,
	ras_n,
	cas_n,
	we_n,

	addr,
	bank,
	data,
	data_mask
);

input 				clk;
input 				rst;

input				wr_fifo_wr;
input	[31:0]		wr_fifo_data;
input	[3:0]		wr_fifo_mask;
output				wr_fifo_full;

input				rd_fifo_rd;
output	[31:0]		rd_fifo_data;
output				rd_fifo_empty;
input				rd_fifo_reset;

//XXX: is this implemented inside the state machine?
input				write_en;
input				read_en;
input	[21:0]		address;
output				sdram_ready;

output				sd_clk;
output				cke;
output 				cs_n;
output				ras_n;
output				cas_n;
output				we_n;

output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
inout		[15:0]	data;
output	reg	[1:0]	data_mask;

wire		[15:0]	data_out;
reg					sdram_reset;
reg					init_cke;
reg					init_cs_n;



reg					wr_en;
reg					rd_en;

wire				sdram_clk;

assign 	data	=	(!write_ready) ? data_out:16'hZZZZ;
assign	cke		=	(sdram_reset) ? 0 : init_cke;	
assign	cs_n	=	(sdram_reset) ? 1 : init_cs_n;



parameter			RESET		=	8'h0;
parameter			INIT		=	8'h1;
parameter			CKE_HIGH	=	8'h2;
parameter			PRECHARGE	=	8'h3;
parameter			AUTO_RFRSH1	=	8'h4;
parameter			AUTO_RFRSH2	=	8'h5;
parameter			LMR			=	8'h6;
parameter			READY		=	8'h7;
parameter			READ		=	8'h8;
parameter			WRITE		=	8'h9;

reg		[7:0]		state;
reg		[24:0]		delay;

reg		[2:0]		init_command;
reg		[2:0]		command;

assign	ras_n		=	command[2];
assign	cas_n		=	command[1];
assign	we_n		=	command[0];


//INIT State Machine variables
reg		[11:0]		init_addr;
reg		[1:0]		init_bank;

//asynchronous
//assign the command to the correct state machine (init, read, write)
always @ (
	sdram_ready, 
	read_ready, 
	write_ready, 
	init_command, 
	read_command, 
	write_command) begin

	if (!sdram_ready) begin
		command		<=	init_command;
	end
	else begin
		if (!read_ready) begin
			command	<=	read_command;
		end
		else if (!write_ready) begin
			command	<= write_command;
		end
		else begin
			command	<= init_command;
		end
	end
end

always @ (
	sdram_ready, 
	read_en, 
	write_en, 
	read_phy_addr, 
	read_phy_bank,
	write_phy_addr, 
	write_phy_bank, 
	init_addr, 
	init_bank,
	read_data_mask,
	write_data_mask) begin

	if (!sdram_ready) begin
		addr		<=	init_addr;
		bank		<=	init_bank;
		data_mask	<=	write_data_mask;
	end
	else begin
		if (read_en) begin
			addr		<=	read_phy_addr;
			bank		<=	read_phy_bank;
			data_mask	<=	read_data_mask;
		end
		else if (write_en) begin
			addr		<=	write_phy_addr;
			bank		<=	write_phy_bank;
			data_mask	<=	write_data_mask;
		end
		else begin
			addr		<=	init_addr;
			bank		<=	init_bank;
			data_mask	<=	write_data_mask;
		end
	end
end




wire					clock_ready;

//instantiate the digital clock manager
sdram_clkgen clkgen (
	.rst(rst),
	.clk(clk),

	.locked(clock_ready),
	.out_clk(sdram_clk),
	.phy_out_clk(sd_clk)
);

//instantiate the write fifo (36 bits)
wire	[35:0]		wr_data;
wire				wr_fifo_rd;
wire				wr_fifo_empty;

wire	[31:0]		rd_data;
wire	[35:0]		wr_data_in;
assign	wr_data_in	=	{(wr_fifo_mask), (wr_fifo_data)};

afifo 
	#(		.DATA_WIDTH(36),
			.ADDRESS_WIDTH(8)
	)
fifo_wr (
	.rst(sdram_reset),

	.din_clk(clk),
	.dout_clk(sdram_clk),

	.data_in(wr_data_in),
	.data_out(wr_data),
	.full(wr_fifo_full),
	.empty(wr_fifo_empty),

	.wr_en(wr_fifo_wr),
	.rd_en(wr_fifo_rd)

);

//instantiate the read fifo (32 bits)
afifo 
	#(		.DATA_WIDTH(32),
			.ADDRESS_WIDTH(8)
	)
fifo_rd (
	.rst(sdram_reset || rd_fifo_reset),

	.din_clk(sdram_clk),
	.dout_clk(clk),

	.data_in(rd_data),
	.data_out(rd_fifo_data),
	.full(rd_fifo_full),
	.empty(rd_fifo_empty),

	.wr_en(rd_fifo_wr),
	.rd_en(rd_fifo_rd)

);

reg					auto_refresh;
wire	[2:0]		write_command;
wire	[11:0]		write_phy_addr;
wire	[1:0]		write_phy_bank;
wire	[1:0]		write_data_mask;

//instantiate the write state machine
sdram_write sdram_wr (
	.rst(sdram_reset),
	.clk(sdram_clk),

	//SDRAM PHY I/O
	.command(write_command),
	.addr(write_phy_addr),
	.bank(write_phy_bank),
	.data_out(data_out),

	.data_mask(write_data_mask),

	//sdram_controller
	.en(wr_en),
	.ready(write_ready),
	.address(address),
	.auto_refresh(auto_refresh),

	//FIFO Out
	.fifo_data(wr_data),
	.fifo_empty(wr_fifo_empty),
	.fifo_rd(wr_fifo_rd)
);
//instantiate the read state machine
wire	[2:0]		read_command;
wire	[11:0]		read_phy_addr;
wire	[1:0]		read_phy_bank;
wire	[1:0]		read_data_mask;

wire				read_ready;
wire	[1:0]		read_bank;

sdram_read sdram_rd (
	.rst(sdram_reset),
	.clk(sdram_clk),

	//SDRAM PHY I/O
	.command(read_command),
	.addr(read_phy_addr),
	.bank(read_phy_bank),
	.data_in(data),
	.data_mask(read_data_mask),

	//READ State Machine interface
	.en(rd_en),
	.ready(read_ready),
	.auto_refresh(auto_refresh),
	.address(address),

	//RD FIFO
	.fifo_data(rd_data),
	.fifo_full(rd_fifo_full),
	.fifo_wr(rd_fifo_wr)
);

//XXX: ATTACH THIS TO THE DCM!!

assign	sdram_ready	=	(!sdram_reset & (delay == 0) & (state == READY || state == READ || state == WRITE));



always @ (posedge clk) begin
	if (rst) begin
		sdram_reset	<=	1;
	end
	else begin
		//wait till the DCM has stabalized
		if (clock_ready) begin
			//when it does then keep SDRAM_reset high for one more clock cycle
			sdram_reset	<=	0;
		end
	end
end



always @ (negedge sdram_clk, posedge rst) begin
	if (sdram_reset || rst) begin
		$display ("sdram: resetting variables");
		init_cke		<= 0;
		init_cs_n		<= 1;
		init_command	<= `SDRAM_CMD_NOP;
		init_addr		<= 12'h0;
		init_bank		<= 2'h0;
		state			<= RESET;
		delay			<= 	10;
		wr_en			<=	0;
		rd_en			<=	0;
	end
	else begin
		if (delay > 0) begin
			delay <= delay - 1;
			init_command	<= `SDRAM_CMD_NOP;
		end
		else begin
			case (state)
				RESET: begin
					$display ("sdram: RESET");
//					init_cke			<=	0;
					init_cs_n			<=	1;
					//wait for the digital clock manager to settle
					//once settled then kick off an INIT
					state				<=	INIT;

				end
				INIT: begin
					$display ("sdram: INIT");
					init_cke			<=	1;
					delay				<=	`T_PLL;
					state				<=	CKE_HIGH;
				end
				CKE_HIGH: begin
					$display ("sdram: CKE_HIGH");
//					init_cke			<=	1;
					init_cs_n			<=	0;
					delay				<=	`T_PLL;
					state				<=	PRECHARGE;
				end
				PRECHARGE: begin
					$display ("sdram: PRECHARGE");
					init_command		<= `SDRAM_CMD_PRE;
					//precharge all
					init_addr[10]		<=	1;
					delay				<=	`T_RP;
					state				<=	AUTO_RFRSH1;
				end
				AUTO_RFRSH1: begin
					$display ("sdram: AUTO_RFRSH1");
					init_command		<=	`SDRAM_CMD_AR;
					delay				<=	`T_RFC;
					state				<=	AUTO_RFRSH2;
				end
				AUTO_RFRSH2: begin
					$display ("sdram: AUTO_RFRSH2");
					init_command		<=	`SDRAM_CMD_AR;
					delay				<=	`T_RFC;
					state				<=	LMR;
				end
				LMR: begin
					$display ("sdram: LMR");
					init_command		<=	`SDRAM_CMD_MRS;
					state				<=	READY;
					init_addr			<=	`SDRAM_INIT_LMR;
					delay				<=	`T_MRD;
				end
				READY: begin
					//listen from a init_command from the wishbone bus
					init_addr			<=	12'h00;
					if (auto_refresh) begin
						init_command	<=	`SDRAM_CMD_AR;
						delay			<=	`T_RFC;
					end
					if (write_en || !wr_fifo_empty) begin
						$display ("sdram: WRITE");
						wr_en	<=	1;
						state	<=	WRITE;
					end
					else if (read_en) begin
						$display ("sdram: READ");
						rd_en	<=	1;
						state	<=	READ;
					end
				end
				READ: begin
					//deassert the read state machine
					rd_en	<=	0;
					
					//continue reading if wishbone
					if (read_en) begin
						rd_en	<=	1;	
					end
					//wait for the ready from the read state machine
					if (~read_en & read_ready) begin
						//change back to ready
						state				<= READY;
					end
				end
				WRITE: begin
					wr_en	<=	0;
					if (write_en || !wr_fifo_empty) begin
						wr_en	<=	1;
					end
					//wait for wishbone to say it's finished
					//wait for the ready signal
					//wait for the write FIFO to be empty
					if (write_ready && wr_fifo_empty) begin
						//deassert the en
						//change back to READY state
						state	<= READY;
					end
				end
				default: begin
					$display ("sdram: in undefined state");
					state				<= INIT;
				end
			endcase
		end

	end
end

//auto refresh timeout
/*
	NOTE: this could have been
		in the above block but it is more readible here
		and conveys that it is independent of the main state
		machine
*/
reg	[31:0]			ar_timeout;
always @ (negedge sdram_clk) begin
	if (sdram_reset) begin
		ar_timeout		<= `T_AR_TIMEOUT;
	end
	else begin
		//auto refresh pulse
		auto_refresh		<= 0;	
		if (ar_timeout > 0) begin
			ar_timeout 	<=	ar_timeout - 1;
		end
		else begin
			ar_timeout	<=	`T_AR_TIMEOUT; 
			auto_refresh	<= 1;
		end
	end
end

endmodule 

