`include "sdram_include.v"

module sdram_write (
	rst,
	clk,

	command,	
	addr,
	bank,
	data_out,
	data_str,


	//sdram controller
	en,
	finished,
	write_address,
	auto_rfrsh,

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
output	reg	[1:0]	data_str;

//sdram controller
input				en;
output	reg			finished;
input	reg	[21:0]	write_address;
input				auto_rfrsh;

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
parameter	FINISH				=	8'h7;

reg	[7:0]			state;

reg					lauto_rfrsh;

always @ (posedge clk) begin
	if (rst) begin
		command		<=	SDRAM_CMD_NOP; 
		addr		<=	12'h0;
		bank		<=	2'h0;
		data_out	<=	16'h0;
		data_str	<=	2'h0;

		state		<=	IDLE;

		laudo_rfrsh	<=	0;
	end
	else begin
		//auto refresh only goes high for one clock cycle
		//so capture it

		if (auto_rfrsh & en) begin
			//because en is high it is my responsibility
			lauto_rfrsh	<= 1;
		end
		fifo_rd		<= 0;
		finished	<= 0;

		if (delay > 0) begin
			delay	<= delay - 1;
			command	<= `SDRAM_CMD_NOP;
		end
		else begin
			case (state)
				IDLE: begin
					if (en & !fifo_empty) begin
						lwrite_address	<= lwrite_address;
						state			<= ACTIVE;
					end
					else if (lauto_rfrsh) begin
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
					lwrite_address	<=	lwrite_address;
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
					if (en & !fifo_empty & !auto_rfrsh) begin
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
					if (len & !lfifo_empty & !lauto_rfrsh) begin
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
					else if (lauto_rfrsh) begin
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
