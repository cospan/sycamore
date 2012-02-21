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

	//Wishbone command
	write_en,
	read_en,
	sdram_ready,
	address,

	sdram_clk,
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

//XXX: is this implemented inside the state machine?
input				write_en;
input				read_en;
input	[21:0]		address;
output				sdram_ready;

output				sdram_clk;
output	reg			cke;
output 	reg			cs_n;
output				ras_n;
output				cas_n;
output				we_n;

output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
inout		[15:0]	data;
output		[1:0]	data_mask;

wire		[15:0]		data_out;
assign 	data	=		(we_n) ? 16'hZ:data_out;



parameter			RESET		=	8'h0;
parameter			INIT		=	8'h1;
parameter			CKE_HIGH	=	8'h3;
parameter			PRECHARGE	=	8'h4;
parameter			AUTO_PCHRG1	=	8'h5;
parameter			AUTO_PCHRG2	=	8'h6;
parameter			LMR			=	8'h7;
parameter			READY		=	8'h8;
parameter			READ		=	8'h9;
parameter			WRITE		=	8'hA;

reg		[7:0]		state;
reg		[15:0]		delay;

reg		[2:0]		init_command;
reg		[2:0]		command;

assign	ras_n		=	command[0];
assign	cas_n		=	command[1];
assign	we_n		=	command[2];


//INIT State Machine variables
reg		[11:0]		init_addr;

//asynchronous
//assign the command to the correct state machine (init, read, write)
always @ (sdram_ready, read_en, write_en) begin
	if (!sdram_ready) begin
		command		<=	init_command;
	end
	else begin
		if (read_en) begin
			command	<=	read_command;
		end
		else if (write_en) begin
			command	<= write_command;
		end
		else begin
			command	<= init_command;
		end
	end
end

always @ (sdram_ready, read_en, write_en) begin
	if (!sdram_ready) begin
		addr	<=	init_addr;
	end
	else begin
		if (read_en) begin
			addr	<=	read_phy_addr;
		end
		else if (write_en) begin
			addr	<= write_phy_addr;
		end
		else begin
			addr	<= init_addr;
		end
	end
end



wire				clock_ready;


//need an enable clock buffer

//instantiate the digital clock manager

//instantiate the write fifo (36 bits)
wire	[35:0]		wr_data;
wire				wr_fifo_rd;
wire				wr_fifo_empty;

wire	[35:0]		wr_data_in;
assign	wr_data_in	=	{(wr_fifo_mask), (wr_fifo_data)};

afifo 
	#(		.DATA_WIDTH(36),
			.ADDRESS_WIDTH(8)
	)
fifo_wr (
	.rst(rst),

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
	.rst(rst),

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

//instantiate the write state machine
sdram_write sdram_wr (
	.rst(rst),
	.clk(clk),

	//SDRAM PHY I/O
	.command(write_command),
	.addr(write_phy_addr),
	.bank(write_phy_bank),
	.data_out(data_out),

	.data_mask(data_mask),

	//sdram_controller
	.en(write_en),
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

wire				read_ready;
wire	[31:0]		rd_data;
wire	[1:0]		read_bank;

sdram_read sdram_rd (
	.rst(rst),
	.clk(clk),

	//SDRAM PHY I/O
	.command(read_command),
	.addr(read_phy_addr),
	.bank(read_phy_bank),
	.data_in(data),

	//READ State Machine interface
	.en(read_en),
	.ready(read_ready),
	.auto_refresh(auto_refresh),
	.address(address),

	//RD FIFO
	.fifo_data(rd_data),
	.fifo_full(rd_fifo_full),
	.fifo_wr(rd_fifo_wr)
);

//XXX: ATTACH THIS TO THE DCM!!
wire				dcm_locked;
reg					sdram_reset;

assign	sdram_ready	=	(!sdram_reset & (delay == 0) & (state == READY));



always @ (posedge clk) begin
	if (rst) begin
		sdram_reset	<=	1;
	end
	else begin
		//wait till the DCM has stabalized
		if (dcm_locked) begin
			//when it does then keep SDRAM_reset high for one more clock cycle
			sdram_reset	<=	0;
		end
	end
end



always @ (posedge sdram_clk) begin
	if (sdram_reset) begin
		cke				<= 0;
		cs_n			<= 1;
		init_command	<= `SDRAM_CMD_NOP;
		init_addr		<= 12'h0;
		bank			<= 2'h0;
	end
	else begin
		if (delay > 0) begin
			delay <= delay - 1;
			init_command	<= `SDRAM_CMD_NOP;
		end
		case (state)
			RESET: begin
				$display ("sdram: RESET");
				cke		<=	0;
				cs_n	<=	1;
				//wait for the digital clock manager to settle
				//once settled then kick off an INIT

			end
			INIT: begin
				$display ("sdram: INIT");
				cs_n				<=	0;
				cke					<=	0;
				delay				<=	`T_PLL;
				state				<=	CKE_HIGH;
			end
			CKE_HIGH: begin
				$display ("sdram: CKE_HIGH");
				cke					<=	1;
				delay				<=	5;
				state				<=	PRECHARGE;
			end
			PRECHARGE: begin
				$display ("sdram: PRECHARGE");
				init_command		<= `SDRAM_CMD_PRE;
				//precharge all
				init_addr[10]		<=	1;
				delay				<=	`T_RP;
				state				<=	AUTO_PCHRG1;
			end
			AUTO_PCHRG1: begin
				$display ("sdram: AUTO_PCHRG1");
				init_command		<=	`SDRAM_CMD_AR;
				delay				<=	`T_RFC;
				state				<=	AUTO_PCHRG2;
			end
			AUTO_PCHRG2: begin
				$display ("sdram: AUTO_PCHRG2");
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
				$display ("sdram: READY");
				//listen from a init_command from the wishbone bus
				if (auto_refresh) begin
					init_command	<=	`SDRAM_CMD_AR;
					delay			<=	`T_RFC;
				end
			end
			READ: begin
				$display ("sdram: READ");
				//enable read
				//wait for the wishbone host to say it's finished
				//deassert the read state machine
				//wait for the ready from the read state machine
				//change back to ready
//XXX: this is just a place holder!!
				state				<= INIT;
			end
			WRITE: begin
				$display ("sdram: WRITE");
				//enable write
				//wait for wishbone to say it's finished
				//wait for the write FIFO to be empty
				//deassert the en
				//wait for the ready signal
				//change back to READY state
//XXX: this is just a place holder!!
				state				<= INIT;
			end
			default: begin
				$display ("sdram: in undefined state");
				state				<= INIT;
			end
		endcase


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
always @ (posedge sdram_clk) begin
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

