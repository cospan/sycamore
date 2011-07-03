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

			//temporarily if in_command bit 0 == 1 then reflect back
			if (in_command & 1 != 0)begin
				out_status	<= in_command;
				out_address <= in_address;
				out_data	<= in_data;
				//out_status	<= 32'hAAAAAAAA;
				//out_address <= 32'hBBBBBBBB;
				//out_data	<= 32'hCCCCCCCC;
				out_en		<= 1;
			end
		end
		//handle output
	end

endmodule
