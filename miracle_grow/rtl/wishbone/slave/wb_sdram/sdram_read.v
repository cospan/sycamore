`include "sdram_include.v"


module sdram_read (
	rst,
	//sdram clock
	clk,

	command,
	addr,
	bank,
	data_in,


	//sdram controller
	en,
	read_address,
	ready,
	auto_rfrsh,

	//FIFO
	fifo_data,
	fifo_full,
	fifo_wr
);

input				rst;
input				clk;
output	reg [2:0]	command;
output	reg	[11:0]	addr;
output		[1:0]	bank;
input		[15:0]	data_in;
output	reg	[1:0]	data_str;
input				auto_refresh;

//sdram controller
input				en;
output				ready;

//21:20 = Bank		(2)
//19:08 = Row		(12)
//07:00 = Column	(8)

input		[21:0]	read_address;

//FIFO
output	reg	[31:0]	fifo_data;
input				fifo_full;
output	reg			fifo_wr;

//states
parameter	IDLE				=	8'h0;
parameter	ACTIVE				=	8'h1;
parameter	READ_COMMAND		=	8'h2;
parameter	READ_TOP_WORD		=	8'h3;
parameter	READ_BOTTOM_WORD	=	8'h4;
parameter	PRECHARGE			=	8'h5;

reg	[7:0]			state;

reg	[11:0]			row;
reg	[7:0]			coloumn;

reg	[7:0]			delay;

//temporary FIFO data when the FIFO is full
reg	[31:0]			tfifo_data;
reg					lauto_rfrsh;
reg					len;
reg	[21:0]			lread_address;

assign	ready		=	((delay == 0) & (state == IDLE));

assign	bank		=	lread_address[21:20];
assign	row			=	lread_address[19:12];
assign	column		=	lread_address[11:0];

//HOW DO i HANDLE A FULL FIFO??
	//introduce wait states, and don't write
	//till the FIFO is not full
//SHOULD THE AUTO_REFERESH be handled in here?
//or should the main interrupt me?
	//the auto refresh should happen in here cause
	//then I'll know exactly where it is

always @ (posedge clk) begin
	if (rst) begin
		command		<=	`SDRAM_CMD_NOP; 
		addr		<= 12'h0;
		bank		<= 2'h0;
		data_str	<= 2'h0;

		fifo_data	<= 32'h0;
		fifo_wr		<= 0;

		state		<= IDLE;
		lbank		<= 2'h0;
		laddress	<= 12'h0;

		delay		<= 8'h0;

		lfifo_full	<= 0;
		tfifo_data	<= 31'h0;
		lauto_rfrsh	<= 0;
		len			<= 0;
	end
	else begin
		//auto refresh only goes high for one clock cycle,
		//so capture it
		if (auto_rfrsh & en) begin
			//because en is high it is my responsibility
			lauto_rfrsh	<= 1;
		end
		fifo_wr		<= 0;
		if (delay > 0) begin
			delay <= delay - 1;
			//during delays always send NOP's
			command	<=	`SDRAM_CMD_NOP;
		end
		else begin
			case (state)
				IDLE: begin
					len	<= en;
					if (en & ~fifo_full) begin
						//initiate a read cycle by calling
						//ACTIVE function here,
						//normally this would be issued in the
						//ACTIVE state but that would waste a 
						//clock cycle

						//store variables into local registers so
						//I can modify them
						lread_address	<= read_address;
						state		<= ACTIVE;
					end
					else if (lauto_rfrsh) begin
					end
				end
				ACTIVE: begin
					$display ("sdram_read: ACTIVE");
					command			<=	`SDRAM_CMD_ACT;
					addr			<=	row; 
					//have rolled over the row?
					//the bank will automatically be updated too
					delay			<=	`T_RCD; 
				end
				READ_COMMAND: begin
					$display ("sdram_read: READ_COMMAND");
					command			<=	`SDRAM_CMD_READ;
					state			<=	READ_TOP_WORD;
					addr			<=	{4'b0000, column};
					delay			<=	`T_CAS;
					lread_address	<= lread_address + 1;
				end
				READ_TOP_WORD: begin
					$display ("sdram_read: READ");
					//because the enable can switch inbetween the
					//read of the top and the bottom I need to remember
					//the state of the system here
					len	<= en;
					state				<= READ_BOTTOM_WORD;
					//here is where I can issue the next
					//READ_COMMAND for consecutive reads
					fifo_data[31:16]	<= data_in;
					lfifo_full	<= fifo_full;
					//check if this is the end of a column, 
					//if so I need to activate a new ROW
					if (en & !fifo_full & !auto_rfrsh) begin
						//check if this is the end of a column
						if (column	== 8'h00) begin
							//need to activate a new row to 
							//start reading from there
							//close this row with a precharge
							command	<= `SDRAM_CMD_PRE;

							//next state will activate a new row
							//but that's gonna wait until
							//READ_BOTTOM_WORD is done
						end
						else begin
							//don't need to activate a new row, 
							//just continue reading
							command		<= `SDRAM_CMD_READ;
						end
					end
					else begin
						//issue the precharge command here
						//after reading the next word and then to  
						command		<= `SDRAM_CMD_PRE;
					end
				end
				READ_BOTTOM_WORD: begin
					$display ("read bottom word");
					fifo_data[15:0]	<=	data_in;
					//tell the FIFO that we have new data
					//if were not waiting for the fifo then
					//write the data to the FIFO immediately
					if (!lfifo_full) begin
						fifo_wr	<= 1;
					end
					//if the FIFO isn't full and were 
					//not done continue on with our reading
					if (len & !lfifo_full & !lauto_rfrsh) begin
						//check if this is the end of a column
						if (column	== 8'h00) begin
							//next state will activate a new row
							state	<= ACTIVE;
							delay	<= `T_RP;
						end
						else begin
							//the command for read has already
							//been issued by the time I reach
							//READ_TOP_WORD we'll be ready for
							//the next incomming word
							state	<= READ_TOP_WORD;
						end
					else if (lfifo_full) begin
						//the fifo was full, 
						//wait for until we see the all clear
						//from the FIFO
						state		<= FIFO_FULL_WAIT; 
					end
					else if (lauto_rfrsh) begin
						state		<= 	RESTART;
						command		<=	`SDRAM_CMD_AR;
						delay		<=	`T_RFC;
					end
					else begin
						state		<= IDLE;
					end

				end
				FIFO_FULL_WAIT: begin
					$display ("sdram_read: FIFO full waiting...");
					lfifo_full	<= fifo_full;
					if (!en) begin
						state	<= IDLE;
					end
					else if (!fifo_full) begin
						$display ("\tdone waiting for the FIFO");
						$display ("\tstart a new read cycle");
						fifo_wr		<= 1;
						state		<= ACTIVATE;
					end
				end
				RESTART: begin
					if (!en) begin
						state	<= IDLE;
					end
					else
						state	<= ACTIVE;
					end
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
