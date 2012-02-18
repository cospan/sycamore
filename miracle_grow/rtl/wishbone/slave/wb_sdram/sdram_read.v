`include "sdram_include.v"


module read_sdram (
	rst,
	//sdram clock
	clk,
	ras_n,
	cas_n,
	we_n,

	addr,
	bank,
	data_out,
	data_in,
	data_str,

	//sdram controller
	en,
	finished,
	read_address,
	read_count,
	fifo_data,
	fifo_full,
	fifo_wr
);

input				rst;
input				clk;
output				ras_n;
output				cas_n;
output				we_n;
output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
output	reg	[15:0]	data_out;
input		[15:0]	data_in;
output	reg	[1:0]	data_str;

//sdram controller
input				en;
output	reg			finished;
input		[23:0]	read_count;

//21:20 = Bank		(2)
//19:08 = Row		(12)
//07:00 = Column	(8)

input		[21:0]	read_address;

//FIFO
output	reg	[31:0]	fifo_data;
input				fifo_full;
output	reg			fifo_wr;

//states
parameter	IDLE			=	8'h0;
parameter	ACTIVE			=	8'h1;
parameter	READ_COMMAND	=	8'h2;
parameter	READ			=	8'h3;
parameter	PRECHARGE		=	8'h4;

reg	[7:0]			state;

reg	[2:0]			command;
reg	[23:0]			lread_count;

reg	[1:0]			lbank;
reg	[11:0]			lrow;
reg	[7:0]			lcoloumn;

reg	[7:0]			delay;


assign	ras_n			=	command[0];
assign	cas_n			=	command[1];
assign	we_n			=	command[2];

always @ (posedge clk) begin
	if (rst) begin
		command		<=	`SDRAM_CMD_NOP; 
		addr		<= 12'h0;
		bank		<= 2'h0;
		data_out	<= 16'h0;
		data_str	<= 2'h0;

		fifo_data	<= 32'h0;
		fifo_wr		<= 0;

		state		<= IDLE;
		lread_count	<= 24'h0;
		lbank		<= 2'h0;
		laddress	<= 12'h0;

		delay		<= 8'h0;

		finished	<= 0;

	end
	else begin
		fifo_wr		<= 1;
		finished	<= 0;
		if (delay > 0) begin
			delay <= delay - 1;
			//set the NOP command
			command	<=	`SDRAM_CMD_NOP;
		end
		else begin
			case (state)
				IDLE: begin
					if (en) begin
						//initiate a read cycle by calling ACTIVE function here,
						//normally this would be issued in the ACTIVE state but that would waste a clock cycle

						//store variables into local registers so I can modify them
//XXX: read_count cannot be 0
						lread_count	<= read_count - 1;	

						lcolumn		<= read_address[7:0];
						lrow		<= read_address[19:8] + 1;
						lbank		<= read_address[21:20] + 1;

						bank		<= read_address[21:20];


						//address 7 - 0 contains the ROW address for 16bit data
						addr		<= read_address[19:8];

						command		<= `SDRAM_CMD_ACT;
						state		<= READ_COMMAND;

						delay		<= `T_RCD; 

					end
				end
				ACTIVE: begin
					$display ("sdram_read: ACTIVE");
					command			<=	`SDRAM_CMD_ACT;
					delay			<=	`T_RCD;
					addr			<=	lrow; 
					//have rolled over the row?
					if (lrow == 12'hFFF) begin
						//only if we roll over a row do we need to update the bank
						bank		<=	lbank;
						lbank 		<=	lbank + 1;
					end

					lrow			<=	lrow + 1;
					delay			<=	`T_RCD; 
				end
				READ_COMMAND: begin
					$display ("sdram_read: READ_COMMAND");
					command			<=	`SDRAM_CMD_READ;
					state			<=	READ_TOP_WORD;
					addr			<=	{4'b0000, lcolumn};
					lcolumn			<=	lcolumn + 1;
					delay			<=	`T_CAS;
				end
				READ_TOP_WORD: begin
					$display ("sdram_read: READ");
					//here is where I can issue the next READ_COMMAND for consecutive reads
					fifo_data[31:16]	<= data;
					//check if this is the end of a column, if so I need to activate a new ROW
					state				<= READ_BOTTOM_WORD;
					if (lread_count > 0) begin
						//check if this is the end of a column
						if (lcolumn	== 8'hFF) begin
							//need to activate a new row to start reading from there
							//close this row, then call ACTIVE
							command	<= `SDRAM_CMD_PRE;
							//next state will activate a new ROW
							state	<= ACTIVE;
							delay	<= `T_RP;
						end
						else begin
							command		<= `SDRAM_CMD_READ;
						end
					end
					else begin
						//issue the precharge command here
						//after reading the next word and then to  
						command		<= `SDRAM_CMD_PRE;
						state		<= FINIHSED;
					end
					else begin
						lread_count	<= lread_count - 1;
						lcolumn		<= lcolumn + 1;
					end
				end
				READ_BOTTOM_WORD: begin
					$display ("read bottom word");
					fifo_data[15:0]	<=	data;
				end
				default: begin
					$display ("sdram_read: got to an unknown state");
					state	<= IDLE;
				end
				FINISHED: begin
					finished	<= 1;
				end
			endcase
		end
	end
end
endmodule
