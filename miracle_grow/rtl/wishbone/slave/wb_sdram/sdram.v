`include "sdram_include.v"


module sdram (
	clk,
	rst,


	sdram_clk,
	cs_n,
	cke,
	ras_n,
	cas_n,
	we_n,

	addr,
	bank,
	data,
	data_str
);

input 				clk;
input 				rst;

output	wire		sdram_ready;

output				sdram_clk;
output	reg			cke;
output 	reg			cs_n;
output				ras_n;
output				cas_n;
output				we_n;

output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
inout	[15:0]		data;
output	reg	[1:0]	data_str;

reg		[15:0]		data_out;
assign data	=		(we_n) ? 16'hZ:data_out;



wire				read_cs_n;
wire				read_ras_n;
wire				read_cas_n;
wire				read_we_n;
wire	[11:0]		read_addr_n;
wire	[1:0]		read_bank;


wire				write_cs_n;
wire				write_ras_n;
wire				write_cas_n;
wire				write_we_n;
wire	[11:0]		write_addr_n;
wire	[1:0]		write_bank;


parameter			RESET		=	8'h0;
parameter			INIT		=	8'h1;
parameter			CKE_H		=	8'h3;
parameter			PRECHARGE	=	8'h4;
parameter			AUTO_PCHRG1	=	8'h5;
parameter			AUTO_PCHRG2	=	8'h6;
parameter			LMR			=	8'h7;
parameter			READY		=	8'h8;
parameter			READ		=	8'h9;
parameter			WRITE		=	8'hA;

reg		[7:0]		state;
reg		[15:0]		delay;

reg		[2:0]		command;

assign	ras_n		=	command[0];
assign	cas_n		=	command[1];
assign	we_n		=	command[2];

wire				clock_ready;


//need an enable clock buffer

//instantiate the digital clock manager

//instantiate the write fifo (36 bits)
//instantiate the read fifo (32 bits)

//instantiate the read state machine
//instantiate the write state machine

//XXX: ATTACH THIS TO THE DCM!!
	wire				dcm_locked;
reg					sdram_reset;

assign	sdram_ready	=	(!sdram_reset & (delay == 0) & (state == READY));

always @ (posedge clk) begin
	always @ (posedge rst) begin
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
		cke			<= 0;
		cs_n		<= 1;
		command		<= `SDRAM_CMD_NOP;
		ras_n		<= 0;
		cas_n		<= 0;
		we_n		<= 0;
		addr		<= 12'h0;
		bank		<= 2'h0;
		data_out	<= 16'h0;
		data_str	<= 2'h0;
	end
	else begin
		if (delay > 0) begin
			delay <= delay - 1;
			command	<= `SDRAM_CMD_NOP;
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
				cs_n	<=	0;
				cke		<=	0;
				delay	<=	`T_PLL;
				state	<=	CKE_HIGH;
			end
			CKE_HIGH: begin
				$display ("sdram: CKE_HIGH");
				cke		<=	1;
				delay	<=	5;
				state	<=	PRECHARGE;
			end
			PRECHARGE: begin
				$display ("sdram: PRECHARGE");
				command	<= `SDRAM_CMD_PRE;
				//precharge all
				addr[10]	<=	1;
				delay	<=	`T_RP;
				state	<=	AUTO_PCHRG1;
			end
			AUTO_PCHRG1: begin
				$display ("sdram: AUTO_PCHRG1");
				command	<=	`SDRAM_CMD_AR;
				delay	<=	`T_RFC;
				state	<=	AUTO_PCHRG2;
			end
			AUTO_PCHRG2: begin
				$display ("sdram: AUTO_PCHRG2");
				command	<=	`SCRAM_CMD_AR;
				delay	<=	`T_RFC;
				state	<=	LMR;
			end
			LMR: begin
				$display ("sdram: LMR");
				command	<=	`SDRAM_CMD_MRS;
				state	<=	READY;
				addr	<=	`SDRAM_INIT_LMR;
				delay	<=	`T_MRD;
			end
			READY: begin
				$display ("sdram: READY");
				//listen from a command from the wishbone bus
				if (auto_refresh) begin
					command	<=	`SDRAM_CMD_AR;
					delay	<=	`T_RFC;
				end
			end
			READ: begin
				$display ("sdram: READ");
				//enable read
				//wait for the wishbone host to say it's finished
				//deassert the read state machine
				//wait for the ready from the read state machine
				//change back to ready
			end
			WRITE: begin
				$display ("sdram: WRITE");
				//enable write
				//wait for wishbone to say it's finished
				//wait for the write FIFO to be empty
				//deassert the en
				//wait for the ready signal
				//change back to READY state
			end
			default: begin
				$display ("sdram: in undefined state");
			end
	end
end

endmodule 

