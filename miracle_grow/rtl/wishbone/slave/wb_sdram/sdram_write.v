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
output		[1:0]	bank;
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
parameter	FIFO_EMPTY_WAIT		=	8'h5;	
parameter	RESTART				=	8'h6;

reg	[7:0]			state;
reg	[15:0]			delay;

reg					len;
reg					lfifo_empty;
reg					lauto_refresh;
reg	[21:0]			laddress;

assign	ready		=	((delay == 0) & (state == IDLE));
assign	bank		=	laddress[21:20];
assign	row			=	laddress[19:12];
assign	column		=	laddress[11:0];



always @ (posedge clk) begin
	if (rst) begin
		command			<=	`SDRAM_CMD_NOP; 
		addr			<=	12'h0;
		data_out		<=	16'h0;
		data_mask		<=	2'h0;

		state			<=	IDLE;

		lauto_refresh	<=	0;
		laddress		<=	0;
		len				<=	0;
		lfifo_empty		<=	1;
		delay			<=	0;
	end
	else begin
		//auto refresh only goes high for one clock cycle
		//so capture it

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
						laddress	<= laddress;
						state			<= ACTIVE;
					end
					else if (lauto_refresh) begin
						state		<=	IDLE;	
						command		<=	`SDRAM_CMD_AR;
						delay		<=	`T_RFC;
					end
				end
				ACTIVE: begin
					$display ("sdram_write: ACTIVE");
					command 		<=	`SDRAM_CMD_ACT;
					delay			<=	`T_RCD;
					addr			<=	row;
				end
				WRITE_CMD: begin
					$display ("sdram_write: WRITE_CMD");
					command			<=	`SDRAM_CMD_WRITE;
					addr			<=	{4'b0000, column};
					laddress		<=	laddress;
					delay			<=	`T_CAS;
					state			<=	WRITE_TOP_WORD;
					//great! two wait states to read the data!
					fifo_rd			<=	1;
				end
				WRITE_TOP_WORD: begin
					$display ("sdram_write: WRITE_TOP_WORD");
					len				<=	en;
					lfifo_empty		<=	fifo_empty;

					state			<=	WRITE_BOTTOM_WORD;
					data_out		<=	fifo_data[31:16];
					data_mask		<=	fifo_data[33:32];
					if (en & !fifo_empty & !auto_refresh) begin
						if (column	==	8'h00) begin
							command	<=	`SDRAM_CMD_PRE;
						end
						else begin
							command	<=	`SDRAM_CMD_WRITE;
						end
					end
					else begin
						command	<= `SDRAM_CMD_PRE;
					end
				end
				WRITE_BOTTOM_WORD: begin
					$display ("sdram_write: WRITE_BOTTOM_WORD");
					data_out		<=	fifo_data[15:0];
					data_mask		<=	fifo_data[35:34];
					if (len & !lfifo_empty & !lauto_refresh) begin
						if (column	==	8'h00) begin
							state	<= ACTIVE;
							delay	<= `T_RP;
						end
						else begin
							state	<= WRITE_TOP_WORD;
						end
					end
					else if (lfifo_empty) begin
						//go into a holding
						state	<=	FIFO_EMPTY_WAIT;
					end
					else if (lauto_refresh) begin
						//execute the auto refresh and then
						//go to the RESTART state
						state	<=	RESTART;
						command	<=	`SDRAM_CMD_AR;
						delay	<=	`T_RFC;
					end
					else begin //en low... were done!
						state	<= IDLE;
					end
				end
				FIFO_EMPTY_WAIT: begin
					$display("sdram_write: FIFO empty wating");
					lfifo_empty	<= fifo_empty;
					if (!en) begin
						state	<= IDLE;
					end
					else if (!fifo_empty) begin
						$display ("\tdone waiting for the FIFO");
						$display ("\tstart a new write cycle");
						state	<= ACTIVE;	
					end
				end
				RESTART: begin
					if (!en) begin
						state	<= IDLE;
					end
					else begin
						state	<= ACTIVE;
					end
				end
				default: begin
					$display ("sdram_write: got to an unknown state");
					state	<= IDLE;
				end
			endcase
		end
	end
end

endmodule
