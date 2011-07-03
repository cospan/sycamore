//wishbone_master

module wishbone_master (
	clk,
	rst,

	in_ready,
	in_command,
	in_address,
	in_data,

	out_ready,
	out_en,
	out_status,
	out_address,
	out_data
	);

	input 				clk;
	input 				rst;

	input 				in_ready;
	input [31:0]		in_command;
	input [31:0] 		in_address;
	input [31:0]		in_data;

	input				out_ready;
	output reg			out_en			= 0;
	output reg [31:0]	out_status		= 32'h0;
	output reg [31:0]	out_address		= 32'h0;
	output reg [31:0]	out_data		= 32'h0;
	
	//parameters
	parameter 			COMMAND_PING	= 32'h00000000;
	parameter			COMMAND_WRITE	= 32'h00000001;
	parameter			COMMAND_READ	= 32'h00000002;

	parameter			S_PING_RESP		= 32'h00001EAF;
	//private registers

	reg [31:0]			local_command	= 32'h0;
	reg [31:0]			local_address	= 32'h0;
	reg [31:0]			local_data		= 32'h0;
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
		end


		//handle input
		if (in_ready) begin
			local_command	<= in_command;
			local_address	<= in_address;
			local_data		<= in_data;


			case (in_command)

				COMMAND_PING: begin
					out_status	<= S_PING_RESP;
					out_address	<= 32'h00000000;
					out_data	<= 32'h00000000;
					out_en		<= 1;
				end
				COMMAND_WRITE:	begin
			
				end
				COMMAND_READ: 	begin
				end
				default: 		begin
				end
			endcase

		end
		//handle output
	end

endmodule
