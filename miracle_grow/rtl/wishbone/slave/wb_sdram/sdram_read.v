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
	data_in,
	//do I ned the data stobe in read??
	data_str,


	//sdram controller
	en,
	finished,
	read_address,
	read_count,
	auto_rfrsh,

	//FIFO
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
input		[15:0]	data_in;
output	reg	[1:0]	data_str;
input				auto_refresh;

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

//temporary FIFO data when the FIFO is full
reg	[31:0]			tfifo_data;
reg					lauto_rfrsh;

assign	ras_n			=	command[0];
assign	cas_n			=	command[1];
assign	we_n			=	command[2];

//HOW DO i HANDLE A FULL FIFO??
//SHOULD THE AUTO_REFERESH be handled in here? or should the main interrupt me?
	//the auto refresh should happen in here cause then I'll know exactly where it is

always @ (posedge clk) begin
	if (rst) begin
		command		<=	`SDRAM_CMD_NOP; 
		addr		<= 12'h0;
		bank		<= 2'h0;
		data_str	<= 2'h0;

		fifo_data	<= 32'h0;
		fifo_wr		<= 0;

		state		<= IDLE;
		lread_count	<= 24'h0;
		lbank		<= 2'h0;
		laddress	<= 12'h0;

		delay		<= 8'h0;

		finished	<= 0;

		lfifo_full	<= 0;
		tfifo_data	<= 31'h0;
		lauto_rfrsh	<= 0;

	end
	else begin
		//auto refresh only goes high for one clock cycle, so capture it
		if (auto_rfrsh & en) begin
			//because en is high it is my responsibility
			lauto_rfrsh	<= 1;
		end
		fifo_wr		<= 1;
		finished	<= 0;
		if (delay > 0) begin
			delay <= delay - 1;
			//during delays always send NOP's
			command	<=	`SDRAM_CMD_NOP;
		end
		else begin
			case (state)
				IDLE: begin
					if (read_count > 0 & en & ~fifo_full) begin
						//initiate a read cycle by calling ACTIVE function here,
						//normally this would be issued in the ACTIVE state but that would waste a clock cycle

						//store variables into local registers so I can modify them
						lread_count	<= read_count - 1;	

						lcolumn		<= read_address[7:0];
						lrow		<= read_address[19:8] + 1;
						lbank		<= read_address[21:20] + 1;

						bank		<= read_address[21:20];


						//address 19 - 8 contains the ROW address for 16bit data
						addr		<= read_address[19:8];

						command		<= `SDRAM_CMD_ACT;
						state		<= READ_COMMAND;

						delay		<= `T_RCD; 

					end
					else if (read_count == 0) begin
						$display ("sdram_read: read_count == 0 in IDLE state");
						state		<= FINISHED;
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
					state				<= READ_BOTTOM_WORD;
					//here is where I can issue the next READ_COMMAND for consecutive reads
					fifo_data[31:16]	<= data_in;
					if (fifo_full) begin
						lfifo_full	<= fifo_full;
					end
					//check if this is the end of a column, if so I need to activate a new ROW
					if ((lread_count > 0) & !fifo_full) begin
						//check if this is the end of a column
						if (lcolumn	== 8'hFF) begin
							//need to activate a new row to start reading from there
							//close this row with a precharge
							command	<= `SDRAM_CMD_PRE;

							//next state will activate a new row
							//but that's gonna wait until READ_BOTTOM_WORD is done
						end
						else begin
							//don't need to activate a new row, just continue reading
							command		<= `SDRAM_CMD_READ;
						end
					end
					else begin
						//issue the precharge command here
						//after reading the next word and then to  
						command		<= `SDRAM_CMD_PRE;
						lread_count	<= lread_count - 1;
						lcolumn		<= lcolumn + 1;
					end
				end
				READ_BOTTOM_WORD: begin
					$display ("read bottom word");
					fifo_data[15:0]	<=	data_in;
					//tell the FIFO that we have new data

					//if were not waiting for the fifo then write the data to the FIFO immediately
					if (!lfifo_full) begin
						fifo_wr	<= 1;
					end
					//if the FIFO isn't full and were not done continue on with our reading
					if (lread_count > 0 & !lfifo_full & !lauto_rfrsh) begin
						//check if this is the end of a column
						if (lcolumn	== 8'hFF) begin
							//next state will activate a new row
							state	<= ACTIVE;
							delay	<= `T_RP;
						end
						else begin
							//the command for read has already been issued by the time I reach
							//READ_TOP_WORD we'll be ready for the next incomming word
							state	<= READ_TOP_WORD;
						end
					else if (lfifo_full) begin
						//the fifo was full, wait for until we see the all clear from the FIFO
						state		<= FIFO_FULL_WAIT; 
					end
					else if (lauto_rfrsh) begin
						state		<= 	RESTART;
						command		<=	`SDRAM_CMD_AR;
						delay		<=	`T_RFC;
					end
					else begin
						state		<= FINIHSED;
					end

				end
				FIFO_FULL_WAIT: begin
					$display ("sdram_read: FIFO full waiting...");
					lfifo_full	<= fifo_full;
					if (~fifo_full) begin
						$display ("\tdone waiting for the FIFO"
						$display ("\tstart a new read cycle");
						fifo_wr		<= 1;
						state		<= RESTART;
					end
				end
				RESTART: begin
					$display ("sdram_read: RESTART");
					//check to see if we need to read more data
					if (lread_count > 0) begin
						//I might to the ACTIVATE command in here
						//but there are a bunch of checks in there
						state		<= ACTIVATE;
					end
					else begin
						state		<= FINISHED;
					end
				end
				FINISHED: begin
					$display("sdram_read: FINISHED");
					finished	<= 1;
					state		<= IDLE;
				end
				default: begin
					$display ("sdram_read: got to an unknown state");
					state	<= IDLE;
				end
			endcase
		end
	end
end
endmodule
