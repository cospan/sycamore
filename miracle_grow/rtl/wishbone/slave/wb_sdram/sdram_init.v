`include "sdram_include.v"

module sdram_init (
	rst,
	clk,

	en_clk,

	cke,
	cs_n,
	command,
	addr,
	bank,
	data_out,
	data_mask,


	//sdram control
	en,
	ready

);


input				rst;
input				clk;
//enable clock to outside of FPGA
output	reg			en_clk;

output	reg			cke;
output	reg			cs_n;
output	reg	[2:0]	command;
output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
output	reg	[15:0]	data_out;
output	reg	[1:0]	data_mask;	

input				en;
output	reg			ready;



parameter	START			=	8'h0;
parameter	ASSERT_CKE		=	8'h1;
parameter	ENABLE_CLK		=	8'h2;
parameter	WAIT_FOR_100US	=	8'h3;
parameter	CKE_HIGH		=	8'h5;
parameter	PRECHARGE		=	8'h4;
parameter	WAIT_TRP
parameter	AUTO_RFRSH_1
parameter	WAIT_TRFC_1
parameter	AUTO_RFRSH_2
parameter	WAIT_TRFC_2
parameter	PROGRAM_LMR
parameter	WAIT_TMRD

parameter	READY;

reg	[7:0]			state;
reg	[15:0]			delay;

always @ (posedge clk) begin
	if (rst) begin
		cke			<= 	0;
		cs_n		<=	1;
		command		<=	`SDRAM_CMD_NOP;
		state		<=	START;
		addr		<=	12'h0;
		bank		<=	2'h0;
		data_out	<=	16'h0;
		data_mask	<=	2'h0;
		en_clk		<=	0;
		ready		<=	0;
		delay		<= 	0;
	end
	else begin
		//except during reset chip select is always enabled
		cs_n		<= 0;
		if (delay > 0) begin
			delay <= delay - 1;
			command	<= `SDRAM_CMD_NOP;
		end
		else begin
			case (state):
				START: begin
					if (en) begin
						cke	<=	1;
//XXX: I may just be able to supply this clock all the time
						en_clk	<=	1;
						delay	<=	`T_PLL;
					
					end
				end
				READY: begin
					ready	<=	1;
				end
			endcase
		end
	end
end

endmodule
