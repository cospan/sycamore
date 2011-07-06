//wishbone_master
module wishbone_master (
	clk,
	rst,

	//indicate to the input that we are ready
	master_ready,

	//input handler interface
	in_ready,
	in_command,
	in_address,
	in_data,

	//output handler interface
	out_ready,
	out_en,
	out_status,
	out_address,
	out_data,

	//wishbone signals
	wb_addr_o,
	wb_dat_o,
	wb_dat_i,
	wb_str_o,
	wb_cyc_o,
	wb_we_o,
	wb_msk_o,
	wb_sel_o,
	wb_ack_i,
	);

	input 				clk;
	input 				rst;

	output reg			master_ready;
	input 				in_ready;
	input [31:0]		in_command;
	input [31:0] 		in_address;
	input [31:0]		in_data;

	input				out_ready;
	output reg			out_en			= 0;
	output reg [31:0]	out_status		= 32'h0;
	output reg [31:0]	out_address		= 32'h0;
	output reg [31:0]	out_data		= 32'h0;
	
	//wishbone
	output reg [31:0]	wb_addr_o;
	output reg [31:0]	wb_dat_o;
	input [31:0]		wb_dat_i;
	output reg 			wb_str_o;
	output reg			wb_cyc_o;
	output reg			wb_we_o;
	output reg			wb_msk_o;
	output reg			wb_sel_o;
	input				wb_ack_i;

	//parameters
//	parameter 			COMMAND_PING		= 32'h00000000;
//	parameter			COMMAND_WRITE		= 32'h00000001;
//	parameter			COMMAND_READ		= 32'h00000002;
//	parameter			COMMAND_WSTREAM_C 	= 32'h00000003;
//	parameter			COMMAND_WSTREAM		= 32'h00000004;
//	parameter			COMMAND_RSTREAM_C	= 32'h00000005;
//	parameter			COMMAND_RSTREAM		= 32'h00000006;
//	parameter			COMMAND_RW_FLAGS	= 32'h00000007;
//	parameter			COMMAND_INTERRUPT	= 32'h00000008;

	parameter			S_PING_RESP			= 32'h00001EAF;
	//private registers

	reg [31:0]			local_command	= 32'h0;
	reg [31:0]			local_address	= 32'h0;
	reg [31:0]			local_data		= 32'h0;

	reg [31:0]			master_flags	= 32'h0;
	//private wires
	

	//private assigns

	//blocks
	always @ (posedge clk) begin
		
		out_en		<= 0;

		if (rst) begin
			out_status		<= 32'h0;
			out_address 	<= 32'h0;
			out_data		<= 32'h0;
			local_command	<= 32'h0;
			local_address	<= 32'h0;
			local_data		<= 32'h0;
			master_flags	<= 32'h0;
		end


		//handle input
		if (in_ready) begin
			local_command	<= in_command;
			local_address	<= in_address;
			local_data		<= in_data;


			case (in_command)

				`COMMAND_PING: begin
					out_status	<= ~in_command;
					out_address	<= 32'h00000000;
					out_data	<= S_PING_RESP;
					out_en		<= 1;
				end
				`COMMAND_WRITE:	begin
					out_status	<= ~in_command;
				end
				`COMMAND_READ: 	begin
					out_status	<= ~in_command;
				end
				`COMMAND_WSTREAM_C: begin
					out_status	<= ~in_command;
				end
				`COMMAND_WSTREAM: begin
					out_status	<= ~in_command;
				end
				`COMMAND_RSTREAM_C: begin
					out_status	<= ~in_command;
				end
				`COMMAND_RSTREAM: begin
					out_status	<= ~in_command;
				end
				`COMMAND_RW_FLAGS: begin
					out_status	<= ~in_command;
				end
				`COMMAND_INTERRUPT: begin
					out_status	<= ~in_command;
				end
				default: 		begin
				end
			endcase

		end
		//handle output
	end

endmodule
