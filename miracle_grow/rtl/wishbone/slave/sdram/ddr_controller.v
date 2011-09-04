//ddr_controller.v

/*
 * 8/29/2011
 *	initial
 *
 * 9/01/2011
 *	core is compiling
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
`define DDR_DATA_SIZE 16

module ddr_controller (
	clk,
	rst,

	//ddr control
	user_cmd,
	user_cmd_vld,

	user_addr,
	user_data_in,
	user_data_out,
	user_data_out_vld,

	ddr_busy,
	ddr_ack,
	ddr_ready,

	//physical connections
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
	mem_data

);

//parameter 	`DDR_DATA_SIZE 			= 16;
parameter	DDR_ROW_SIZE 			= 13;
parameter	DDR_COLUMN_SIZE			= 10;
parameter	DDR_BANK_SIZE 			= 2; 	//NOTE: THIS IS A HARD VALUE! HERE FOR OTHER MACROS
										//IF THE NUMBER OF BANKS CHANGE CMD_ACTIVE MUST CHANGE TOO
parameter	DDR_MASK_SIZE			= 2;
parameter	DDR_DQS_SIZE			= 2;
parameter	BURST_LENGTH 			= 2; 	//16 x 2 = 32 bits

parameter	USR_ADDR_SIZE			= DDR_ROW_SIZE + DDR_COLUMN_SIZE + (DDR_BANK_SIZE - 1);
parameter	DDR_ADDR_SIZE			= DDR_ROW_SIZE + DDR_COLUMN_SIZE;

//parameter 	REFRESH_TIMEOUT_INT		= 1560;	//tREFI = 5ns * 1560	= 7.8uS
parameter	REFRESH_TIMEOUT_CYC		= 14000;	//tREFC = 5ns * 		= 70uS 
parameter	DLL_EN_DELAY			= 40000; 	//200us * 2 clock cycles whenever the DLL is enabled (the state machine is at 2x ddr_clk)
parameter	LMR_DELAY				= 3; 	//tMRD 	= 5nS * 3 	= 15ns
parameter	AUTO_REFRESH_DELAY		= 15; 	//trFC 	= 5ns * 15 	= 75ns
parameter	SRFSH_NON_READ			= 15;	//tXSNR	= 5ns * 15	= 75ns
parameter	SRFSH_READ				= 400;	//txSRD = 200 Cycles * 2 = 400
parameter	WRITE_RECOVERY_DELAY	= 3;	//tWR	= 5nS * 3		= 15ns
parameter	PRECHARGE_DELAY			= 4;	//tRP	= 5nS * 4		= 20ns
parameter	ACTIVE_TO_RW			= 4;	//tRCD	= 5ns * 4		= 20ns
//parameter	ACTIVE_TO_PRECHARGE		= 8;	//tRAS	= 5ns * 8		= 40ns
//parameter	ACTIVE_TO_ACTIVE		= 13;	//tRC	= 5ns * 13		= 65ns
parameter	ACTIVE_BANK_BANK		= 3;	//tRRD  = 5ns * 3 		= 15ns
parameter	WRITE_CMD_TO_STROBE		= 2;	//TDQSS	= 1 Cycle * 2	= 2


//speed grade -5B	= 	CAS Latency = 3
//speed grade -6	=	CAS Latency = 2.5
//speed grade -6T	=	CAS Latency	= 2.5
//speed grade -75E	=	CAS Latency = 2
//speed grade -75Z	=	CAS Latency = 2

//** speed grade -75	=	CAS Latency = 2.5 @ 133MHz***
//** speed grade -75	=	CAS Latency = 2 @ 100MHz***

//Default setup for -75 chip
//Clock rate = 100 MHz
//CAS Latency = 2

parameter	CAS_LATENCY 			= 3'h2; //speed grade -75

parameter INIT_200US_DELAY = 50 * 200;
parameter OPTIONAL_LMR = 0;

input 								rst;
input 								clk;

input [3:0] 						user_cmd;
input 								user_cmd_vld;

input [(USR_ADDR_SIZE - 1):0] 		user_addr;
input [31:0]						user_data_in;
output reg [31:0]					user_data_out;
output reg							user_data_out_vld;

output reg							ddr_busy;
output reg							ddr_ack;
output								ddr_ready;

output								mem_clk;
output								mem_clk_n;
output reg							mem_cke;
output reg							mem_cs; 
output reg							mem_ras;
output reg							mem_cas;
output reg							mem_we;
output reg [(DDR_MASK_SIZE - 1): 0]	mem_dm;
output reg [(DDR_DQS_SIZE - 1): 0]	mem_dqs;
output reg [(DDR_BANK_SIZE - 1):0]	mem_ba;
output reg [(DDR_ADDR_SIZE - 1):0]	mem_addr;
inout [(`DDR_DATA_SIZE - 1):0]	mem_data;

input 								mem_clk_fb;

assign mem_clk_n			=		mem_clk;
wire								ddr_2x_clk;
wire								dcm_lock;

ddr_dcm dcm (
   	.clk(clk),
	.rst(rst),
	
	.ddr_clk(mem_clk),
	.ddr_2x_clk(ddr_2x_clk),
	.dcm_lock(dcm_lock),

	.ddr_fb_clk_in(mem_clk_fb)
);
 
//Initialization sequence
reg	[7:0]		init_state;

//INIT_0: Reset
//INIT_00: CKE goes LVCMOS Low
parameter		INIT_00	=	8'h00;
//INIT_01: Apply stable clocks, wait for 200uS
parameter		INIT_01	=	8'h01;
//INIT_04: CKE goes high with NOP
parameter		INIT_02	=	8'h02;
//INIT_05: Precharge All, wait for tRP
parameter		INIT_03	=	8'h03;
//INIT_07: Configure Extended mode register wait for tMRD
parameter		INIT_04	=	8'h04;
//INIT_09: Configure load mode register and reset DLL, wait for tMRD
parameter		INIT_05	=	8'h05;
//INIT_0B: Precharge All, wait for tRP
parameter		INIT_06	=	8'h06;
//INIT_0D: Issue Auto Refresh command, wait for tRFC
parameter		INIT_07	=	8'h07;
//INIT_0F: Issue Auto Refresh command, wait for tRFC
parameter		INIT_08	=	8'h08;
//INIT_11: Optional LMR command to clear DLL bit, wait for tMRD
parameter		INIT_09	=	8'h09;

//INIT_DDR_READY
parameter		RAM_READY	=	8'h0A;

assign ddr_ready	= init_state == (RAM_READY);


//SIMULATION HOOKS
`ifdef SIM
	reg				user_clk;
	parameter		SIM_DELAY =	16;
	reg	[15:0]		sim_count;
	//the user clock needs to be slower than the DDR clock
always @ (posedge clk) begin
	if (rst) begin
		sim_count	<= 16'h00;
		user_clk		<= 0;
	end
	else begin
		if (sim_count >= SIM_DELAY) begin
			sim_count	<= 0;
			user_clk		<= ~user_clk;
		end
		else begin
			sim_count	<= sim_count + 1;
		end
	end
end
`else
	//real thing
	wire			user_clk;
	assign	user_clk	=	clk;
`endif


//this should be controlled by user to initialize the RAM again
reg	[31:0]	count;
reg			user_cke;
reg			en_dll;
reg			user_str_reduced;
reg			reset_dll;


parameter	USER_CMD_READ			= 0;
parameter	USER_CMD_WRITE			= 1;



//Crossing clock domains YUCK!

//IN
wire l_user_cmd_vld;
reg	user_cmd_vld_prev;
reg	vld_pos_edge;


always @ (posedge ddr_2x_clk) begin
	user_cmd_vld_prev	<= user_cmd_vld;
end
assign l_user_cmd_vld	= (user_cmd_vld & ~user_cmd_vld_prev);


//OUT
reg user_clk_prev;
wire pos_edge_user_clock;
always @ (posedge ddr_2x_clk) begin
	user_clk_prev	<= clk;
end
assign pos_edge_user_clock	= (clk & ~user_clk_prev);


//Main State Machine
reg	[7:0] 	ddr_cmd_state;
reg			ddr_cmd_ack;
reg	[31:0]	ddr_cmd_count;
reg	[15:0]	ddr_refresh_timeout;
reg	[3:0]	data_rw_count;

reg	[(USR_ADDR_SIZE - 1):0]	l_user_addr;
reg	[31:0]	l_user_data_in;
reg			l_write;

//memory bi-directional bus
reg	[(`DDR_DATA_SIZE - 1):0]	mem_data_out;
assign		mem_data [(`DDR_DATA_SIZE - 1): 0]	= (l_write) ? mem_data_out: `DDR_DATA_SIZE'hz; 

//detect slow clock edge
reg			prev_user_clk;
wire		pos_edge_user_clk;
assign		pos_edge_user_clk	=	~prev_user_clk & user_clk;


//reg			test	=	0;
//refresh timeout
reg	[15:0]	refresh_timeout;

parameter 	CMD_IDLE		=	8'h00;
parameter 	CMD_DESELECT	=	8'h01;
parameter	CMD_NOP			=	8'h02;
parameter	CMD_ACTIVE		=	8'h03;
parameter	CMD_READ_PRE	=	8'h04;
parameter	CMD_READ		=	8'h05;
parameter	CMD_READ_DATA	=	8'h06;
parameter	CMD_WRITE_PR	=	8'h07;
parameter	CMD_WRITE		=	8'h08;
parameter	CMD_WRITE_PRE	=	8'h09;
parameter	CMD_WRITE_DATA	=	8'h0A;
parameter	CMD_BST			=	8'h0B;
parameter	CMD_AUTO_RFSH	=	8'h0C;
parameter	CMD_LMR			=	8'h0D;
parameter	CMD_LBASE_REG	=	8'h0E;
parameter	CMD_LEXT_REG	=	8'h0F;
parameter	CMD_PRECHARGE	=	8'h10;
parameter	CMD_SELF_RFSH	=	8'h11;
parameter	CMD_SR_IDLE		=	8'h12;

//DDR Control
always @ (posedge ddr_2x_clk) begin
	if (pos_edge_user_clk) begin
		//put the ack down since the user should have gotten this by now
		ddr_ack	<= 0;
		user_data_out_vld 	<= 1;	
		vld_pos_edge		<= user_cmd_vld;
	end
	if (l_user_cmd_vld) begin
		vld_pos_edge	<= 1;
	end
	if (ddr_cmd_count > 0) begin
		ddr_cmd_count <= ddr_cmd_count - 1;
		//NOP command
		mem_cs			<= 0;
		mem_ras			<= 1;
		mem_cas			<= 1;
		mem_we			<= 1;
		ddr_cmd_ack		<= 1;
		l_user_addr	<= 0;
		l_user_data_in	<= 0;
	
	end

	//refresh timeout, this is disabled during initialization
	if (init_state	!= RAM_READY) begin
			refresh_timeout	<= 0;	
	end
	else begin
			refresh_timeout	<= refresh_timeout + 1;
	end

	if (rst) begin
		ddr_cmd_state	<=	CMD_IDLE;
		ddr_cmd_ack		<= 	0;
		ddr_cmd_count	<= 	0;

		mem_cke			<=	0;
		mem_cs			<=	1;
		mem_ras			<=	1;
		mem_cas			<=	1;
		mem_we			<=	1;
		mem_dm			<= 	0;	//not going to use the data masks
		mem_dqs			<= 	0;
		mem_data_out	<=	0;
		mem_ba			<= 	0;
		mem_addr		<= 	0;
		refresh_timeout	<= 	0;
		init_state		<= INIT_00;
		en_dll			<= 0;
		user_data_out_vld<= 0;	
		data_rw_count	<= 0;
		reset_dll		<= 0;	
		//test			<= 0;
	end
	else begin
		case (ddr_cmd_state)
			CMD_IDLE: begin
				if (pos_edge_user_clk) begin
					ddr_cmd_ack		<=	0;
				end
				if (ddr_cmd_count == 0) begin
					ddr_busy	<= 0;
					l_write		<= 0;
					if (init_state == RAM_READY) begin
//NOT REALLY SURE WHERE TO PUT mem_cke
						mem_cke	<= 1;
						if (mem_clk && (refresh_timeout >= REFRESH_TIMEOUT_CYC)) begin
							$display ("REFRESH!!");
							ddr_cmd_state	<= CMD_AUTO_RFSH;
							refresh_timeout	<= 0;
						end

						//we are not in the intialization sequence
						if (vld_pos_edge & ~mem_clk) begin
							vld_pos_edge	<= 0;
							ddr_busy		<= 1;	
							l_user_addr	<= user_addr;
							l_user_data_in	<= user_data_in;
					
							//set the active row, and active bank
							if (user_addr[DDR_ADDR_SIZE - 1]) begin
							//high bank was selected
								mem_ba[1:0]	<= 2'h2;
							end
							else begin
								//low bank was selected
								mem_ba[1:0]	<= 2'h1;
							end
							mem_addr[DDR_ROW_SIZE - 1: 0]	<= user_addr[(USR_ADDR_SIZE - 2):DDR_COLUMN_SIZE];
	
							mem_cs			<= 0;
							mem_ras			<= 0;
							mem_cas			<= 1;
							mem_we			<= 1;

							ddr_cmd_count	<= ACTIVE_TO_RW;
/*WERE NOT REALLY DONE HERE, but this will help out with pipelining 
this state maching will not accept new commands until it is IDLE
and that wont happen until a read or write is finished
*/
							ddr_ack	<= 1;



							//ACTIVATE COMMAND
							//READ
							if (user_cmd == USER_CMD_READ) begin
//this could be changed later in order to turn off precharge for faster busert mode
								l_write		<= 0;
								ddr_cmd_state	<= CMD_READ_PRE;
							end
							else begin
//this could be changed later in order to turn off precharge for faster busert mode
								ddr_cmd_state	<= CMD_WRITE_PRE;
								l_write		<= 1;
							end //user command
						end//user command is valid
						else begin
							//NOP this bitch!
							mem_cs			<= 0;
							mem_ras			<= 1;
							mem_cas			<= 1;
							mem_we			<= 1;
							ddr_cmd_ack		<= 1;
						end	//user command is not valid
	
					end //system is ready
					else begin
						
//we are in the INIT
						case (init_state)
							INIT_00: begin
								//this should probably be removed

								if (mem_clk == 0) begin
									mem_cke		<= 0;
									init_state	<= INIT_01;
								end
							end
							INIT_01: begin
								//apply stable clocks and wait 200uS
								if (mem_clk == 1) begin
									en_dll	<= 1;
									user_str_reduced	<= 0;
									ddr_cmd_state	<= CMD_LEXT_REG;
									init_state	<= INIT_02;
								end
							end
							INIT_02: begin
								if (mem_clk == 0) begin
									mem_cs		<= 0;
									mem_ras		<= 1;
									mem_cas		<= 1;
									mem_we		<= 1;
									mem_cke		<= 1;
									init_state	<= INIT_03;
								end
							end	
							INIT_03: begin
								if (mem_clk == 1) begin
									ddr_cmd_state	<= CMD_PRECHARGE;	
									init_state	<= INIT_04;
								end
							end
							INIT_04: begin
								if (mem_clk == 1) begin
									en_dll	<= 1;
									user_str_reduced	<= 0;
									ddr_cmd_state	<= CMD_LEXT_REG;
									init_state	<= INIT_05;
								end
							end
							INIT_05: begin
								//configure register
								if (mem_clk == 1) begin
									ddr_cmd_state	<= CMD_LBASE_REG;
									init_state		<= INIT_06;
								end
							end
							INIT_06: begin
								if (mem_clk == 1) begin
									ddr_cmd_state	<= CMD_PRECHARGE;
									init_state	<= INIT_07;
								end
							end
							INIT_07: begin
								if (mem_clk == 1) begin
									ddr_cmd_state	<= CMD_AUTO_RFSH;
									init_state	<=	INIT_08;
								end
							end
							INIT_08: begin
								if (mem_clk == 1) begin
									ddr_cmd_state	<= CMD_AUTO_RFSH;
									init_state	<=	INIT_09;
								end
							end
							INIT_09: begin
								if (mem_clk == 1) begin
									reset_dll	<= 1;
									ddr_cmd_state	<=	CMD_LBASE_REG;
									init_state	<=	RAM_READY;
								end
							end
							RAM_READY: begin
							//do nothing, were inited!
							end
							default: begin
								init_state	<= INIT_00;
							end
						endcase
					end //in the init state
				end
			end
			CMD_DESELECT: begin
			//prevents new commands from beign executed by the DDR SDRAM
				mem_cs			<= 1;		
				ddr_cmd_ack		<= 1;
				ddr_cmd_state	<= CMD_IDLE;
			end
			CMD_NOP: begin
				//used to prevent unwanted commands from being registerd during idle or wait states
				mem_cs			<= 0;
				mem_ras			<= 1;
				mem_cas			<= 1;
				mem_we			<= 1;
				ddr_cmd_ack		<= 1;
				ddr_cmd_state	<= CMD_IDLE;
			end
/*
			CMD_ACTIVE: begin
				//used to open (or activate) a row in a particular bank for a subsequent access
				//like a read or a write
				//the value on the BA0 BA1 inputs select the bank, and the address prvided on inputs A0-An
				//selects the row

				//set the active row, and active bank
				if (user_addr[DDR_ADDR_SIZE - 1]) begin
					//high bank was selected
					mem_ba[1:0]	<= 2'h2;
				end
				else begin
					//low bank was selected
					mem_ba[1:0]	<= 2'h1;
				end

				//set up the ROW
				//the row value is the second highest bit down to the DDR_COLUMN_SIZE
				//address size = 24
				//	bit 23		=	bank select
				//	bit 22 - 10	=	row address
				//	bit 9  - 0	=	column address
				//for this exmample the bank bit takes up 1 bit (top)_, the row address takes up 
				mem_addr[DDR_ROW_SIZE - 1: 0]	<= user_addr[(USR_ADDR_SIZE - 2):DDR_COLUMN_SIZE];

				mem_cs			<= 0;
				mem_ras			<= 0;
				mem_cas			<= 1;
				mem_we			<= 1;

				ddr_cmd_count	<= ACTIVE_TO_RW;
			end
*/
/*
			CMD_READ: begin
				//used to initiate a burst read access to an active row
				//the value on BA0, BA1 input selects the bank and the address provided on inputs
				//A0-Ai (Ai is the most significant column address bit for a given density and configuration)
				//selects starting column location
				if (ddr_cmd_count == 0) begin
					mem_cs			<= 0;
					mem_ras			<= 1;
					mem_cas			<= 0;
					mem_we			<= 1;

					mem_addr		<= user_addr[(DDR_COLUMN_SIZE - 1): 0];
					//no auto precharge
					mem_addr[10]	<= 0;
					ddr_cmd_count	<= (CAS_LATENCY * 2);
					data_rw_count	<= BURST_LENGTH - 1;
				end
			end
*/
			CMD_READ_PRE: begin
				if (ddr_cmd_count == 0) begin
					mem_cs			<= 0;
					mem_ras			<= 1;
					mem_cas			<= 0;
					mem_we			<= 1;

					mem_addr		<= l_user_addr[(DDR_COLUMN_SIZE - 1):0];
					mem_addr[10]	<= 1;
					ddr_cmd_count	<= (CAS_LATENCY * 2);
					data_rw_count	<= BURST_LENGTH - 1;
					ddr_cmd_state	<= CMD_READ_DATA;
				end
			end
			CMD_READ_DATA: begin
				//wait this amount of time and then read the data from the RAM
				if (ddr_cmd_count == 0) begin
					if (data_rw_count >= 1) begin
						$display ("Reading top word");
						user_data_out[31:16] <= mem_data[15:0]; 
						data_rw_count <= 0;	
						//test	<= ~test;
					end
					else begin
						$display ("Reading bottom word");
						user_data_out[15:0]	<= mem_data;	
//IF CONSECUTIVE READS ARE DESIRED CODE CAN BE ISERTED HERE TO JUMP BACK TO THE CMD_READ or CMD_READ_PRE command
						ddr_cmd_count	<= PRECHARGE_DELAY; 
						ddr_cmd_state	<= CMD_IDLE;
						user_data_out_vld	<= 1;
						//test	<= ~test;
					end
				end
			end
/*
			CMD_WRITE: begin
				//used to initiate a burst wirte access to an active row the value on the BA0, BA1 input selects the bank
				//and the address provided on the input A0-AI (where Ai is the most significant column address bit for a
				//a given density and configuration
				if (ddr_cmd_count == 0) begin
					mem_cs			<= 0;
					mem_ras			<= 1;
					mem_cas			<= 0;
					mem_we			<= 0;

					mem_addr		<= user_addr[(DDR_COLUMN_SIZE - 1): 0];
					//no auto precharge
					mem_addr[10]	<= 0;
					ddr_cmd_count 	<= WRITE_CMD_TO_STROBE;				
					data_rw_count	<= BURST_LENGTH - 1;
					ddr_cmd_state	<= CMD_WRITE_DATA;
				end
			end
*/
			CMD_WRITE_PRE: begin
				if (ddr_cmd_count	== 0) begin
					mem_cs			<= 0;
					mem_ras			<= 1;
					mem_cas			<= 0;
					mem_we			<= 0;
					mem_dqs			<= 0;

					mem_addr		<= l_user_addr[(DDR_COLUMN_SIZE - 1):0];
					//auto precharge
					mem_addr[10]	<= 1;
					ddr_cmd_count	<= WRITE_CMD_TO_STROBE;
					data_rw_count	<= BURST_LENGTH - 1;
					ddr_cmd_state	<= CMD_WRITE_DATA;

				end
			end
			CMD_WRITE_DATA: begin
				//wai this amount of time and then write the data to RAM
				if (ddr_cmd_count == 0) begin
//WILL THIS FLIP THE BITS ON ALL THE mem_dqs?
					mem_dqs	<= ~mem_dqs;
					if (data_rw_count >= 1) begin
//MAKE SURE TO ENABLE THE user_write VARIABLE TO SWITCH mem_data TRISTATE
						mem_data_out	<= l_user_data_in[31:16];	
						data_rw_count	<= data_rw_count - 1;
						
					end
					else begin
						mem_data_out	<= user_data_in[15:0];
						ddr_cmd_count	<= PRECHARGE_DELAY;
						ddr_cmd_state	<= CMD_IDLE;
					end
				end
			end
/*
//only using BURSTS of two, don't really need to terminate this
			CMD_BST: begin
				//used to truncate READ bursts (with auto prechage disabled)
				//the most recently registered READ command prior to the BURST TERMINATE command will be
				//truncated. the open page from whice the READ burst was terminated remains open
				mem_cs			<= 0;
				mem_ras			<= 1;
				mem_cas			<= 1;
				mem_we			<= 0;


				//always terminate both banks for now
				mem_addr[10]	<= 1;

				//if mem_addr[10] <= 1 then you can select BA[1] or BA[0] for precharge

//DO I NEED A DELAY?
			end
*/
			CMD_AUTO_RFSH: begin
				//used during normal operation of the DDR SDRAM and is analogos to CAS before RAS refresh
				//this command is nonpersistent, so it must be issued each time a refresh is requried
				//all banks msut be idle vefore an AUTO refreusn command is issued
				mem_cs			<= 0;
				mem_ras			<= 0;
				mem_cas			<= 0;
				mem_we			<= 1;
				ddr_cmd_count	<= AUTO_REFRESH_DELAY; 
				ddr_cmd_state	<= CMD_IDLE;

//DO I NEED A DELAY?
			end
/*
			CMD_LMR: begin
				//mode register is laoded via input A0-An
				//LMR command can only be issued when all banks are idle, and subsequent command cannot
				//be issued until tMRD is met
				//BA1 BA0: Mode Register Definition
					//00: Base Mode Register
					//01: Extended Mode Register
					//10: Reserved
					//11: Reserved

				//A2 A1 A0: Burst Length
					//000: Reserved
					//001: 2
					//010: 4
					//011: 8
					//100: Reserved
					//101: Reserved
					//110: Reserved
					//111: Reserved

				//A3: Burst Type
					//0: Sequential
					//1: Interleaving

				//A6 A5 A4: CAS Latency
					//000: Reserved
					//001: Reserved
					//010: 2
					//011: 3(-5B only)
					//100: Reserved
					//101: Reserved
					//110: 2.5
					//111: Reserved

				//AN...A9 A8 A7 A6-A0: Operating Mode
					//AN -> A7 (0...000), A6 -> A0 (VALID): Normal Operation
					//AN -> A7 (0...010), A6 -> A0 (VALID): Normal Operation, Reset DLL
				mem_cs	<=	0;
				mem_ras	<=	0;
				mem_cas	<=	0;
				mem_we	<=	0;
			end
*/
			CMD_LBASE_REG: begin
				mem_addr	<= 0;
				if (ddr_cmd_count	== 0) begin
					mem_ba[1:0]		<= 2'h0;
					mem_addr[2:0]	<= BURST_LENGTH;
					mem_addr[3]		<= 0;	//sequential
					mem_addr[6:4]	<= CAS_LATENCY;
					if (reset_dll) begin
						mem_addr[8]	<= 1;
					end

					mem_cs			<= 0;
					mem_ras			<= 0;
					mem_cas			<= 0;
					mem_we			<= 0;

					ddr_cmd_count	<= LMR_DELAY;
					ddr_cmd_state	<= CMD_IDLE;
				end
//DO I NEED A DELAY?
			end
			CMD_LEXT_REG: begin
				if (ddr_cmd_count	== 0) begin
					mem_ba[1:0]		<= 2'h1;
					mem_addr[0]		<= ~en_dll;
					mem_addr[1]		<= user_str_reduced;
					mem_addr[(DDR_ADDR_SIZE - 1):2]	<= 0;

					mem_cs			<= 0;
					mem_ras			<= 0;
					mem_cas			<= 0;
					mem_we			<= 0;
					if (en_dll) begin
						ddr_cmd_count	<= DLL_EN_DELAY;
					end
					else begin
						ddr_cmd_count		<= LMR_DELAY;
					end
						ddr_cmd_state		<= CMD_IDLE;
					end
//DO I NEED A DELAY??

			end

//DON'T NEED THIS RIGHT NOW CAUSE i'M USING AUTO_PRECHARGE
			CMD_PRECHARGE: begin
				if (ddr_cmd_count	== 0) begin
					//used to deactivate the open row in a particular bank or the open row in all banks.
					//the value on the BA0, BA1 input selects the bank and the A10 input selects whether a single
					//bank isrpecharged or whether al banks are precharged
					mem_cs			<= 0;
					mem_ras			<= 0;
					mem_cas			<= 1;
					mem_we			<= 0;

					//both banks will go to precharge
					mem_addr[10]		<= 1;
					ddr_cmd_state	<= CMD_IDLE;
					ddr_cmd_count	<= PRECHARGE_DELAY;
				end
//DO I NEED A DELAY?
			end


/*
//DON'T NEED THESE RIGHT NOW
			CMD_SELF_RFSH: begin
				//can be used to retain data in the DDR SDRAM, even if the rest of the system is powered down.
				// the SELF REFRESH command is initiated like an AUTO REFRESH commadn except CKE is low
				mem_cs			<= 0;
				mem_ras			<= 0;
				mem_cas			<= 0;
				mem_we			<= 0;
				ddr_cmd_state	<= user_cmd;
			end
			CMD_SR_IDLE: begin
				if (~user_cke) begin
					mem_cke			<= 0;
				end
				else begin
					mem_cke			<= 1;
					ddr_cmd_state	<= CMD_IDLE;
//in the datasheet it says I can put in a much lower delay if I'm not going to be reading anythign immediately, but I can't
//be sure of that so I've added the long delay
					ddr_cmd_count 	<= SRFSH_READ;
//DO I NEED A DELAY?
				end
			end
*/
			default: begin
				ddr_cmd_state	<= CMD_IDLE;
			end
		endcase

/*
		if (state != SELF_RFSH) begin
			mem_cke	<= user_cke;
		end
*/
	end
end
endmodule
