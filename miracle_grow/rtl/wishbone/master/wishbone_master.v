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

	parameter 			IDLE				= 32'h00000000;
	parameter			STREAM_WRITE_C		= 32'h00000001;
	parameter			STREAM_WRITE		= 32'h00000002;
	parameter			STREAM_READ_C		= 32'h00000003;
	parameter			STREAM_READ			= 32'h00000004;

	parameter			S_PING_RESP			= 32'h00001EAF;
	//private registers

	reg [31:0]			state			= IDLE;
	reg [31:0]			local_command	= 32'h0;
	reg [31:0]			local_address	= 32'h0;
	reg [31:0]			local_data		= 32'h0;

	reg [31:0]			master_flags	= 32'h0;
	reg [31:0]			rw_count		= 32'h0;
	//private wires
	

	//private assigns

	//blocks
	always @ (posedge clk) begin
		
		out_en		<= 0;

//master ready should be used as a flow control, for now its being reset every
//clock cycle, but in the future this should be used to regulate data comming in so that the master can send data to the slaves without overflowing any buffers
		master_ready	<= 1;

		if (rst) begin
			out_status		<= 32'h0;
			out_address 	<= 32'h0;
			out_data		<= 32'h0;
			local_command	<= 32'h0;
			local_address	<= 32'h0;
			local_data		<= 32'h0;
			master_flags	<= 32'h0;
			master_ready	<= 1;
			rw_count		<= 0;
			state			<= IDLE;
		end


		//handle input
		if (in_ready) begin
			local_command	<= in_command;
			local_address	<= in_address;
			local_data		<= in_data;


			case(state)
				IDLE: begin
					$display ("in IDLE state");
					case (in_command)

					`COMMAND_PING: begin
						$display("ping");
						out_status	<= ~in_command;
						out_address	<= 32'h00000000;
						out_data	<= S_PING_RESP;
						out_en		<= 1;
						state 		<= IDLE;
					end
					`COMMAND_WRITE:	begin
						$display ("write");
						out_status	<= ~in_command;
						out_en		<= 1;
						state		<= IDLE;
					end
					`COMMAND_READ: 	begin
						$display ("read");
						out_status	<= ~in_command;
						out_en		<= 1;
						state		<= IDLE;
					end
					`COMMAND_WSTREAM_C: begin
						$display ("write stream consective");
						out_status	<= ~in_command;
						out_en		<= 1;
						master_ready<= 0;
						$display ("in_data == %d", in_data);
						rw_count	<= in_data;
						state		<= STREAM_WRITE_C;
					end
					`COMMAND_WSTREAM: begin
						$display ("write stream");
						out_status	<= ~in_command;
						out_en		<= 1;
						$display ("in_data == %d", in_data);
						master_ready	<= 0;
						rw_count	<= in_data;
						state		<= STREAM_WRITE;
					end
					`COMMAND_RSTREAM_C: begin
						$display ("read stream consecutive");
						out_status	<= ~in_command;
						out_en		<= 1;
						$display ("in_data == %d", in_data);
						rw_count	<= in_data;
						master_ready <= 0;
						state		<= STREAM_READ_C;
					end
					`COMMAND_RSTREAM: begin
						$display ("read stream");
						out_status	<= ~in_command;
						out_en		<= 1;
						master_ready <= 0;
						$display ("in_data == %d", in_data);
						rw_count	<= in_data;
						state		<= STREAM_READ;
					end
					`COMMAND_RW_FLAGS: begin
						$display ("rw flags");
						out_status	<= ~in_command;
						out_en		<= 1;
						state		<= IDLE;
					end
					`COMMAND_INTERRUPT: begin
						$display ("interrupts");
						out_status	<= ~in_command;
						out_en		<= 1;
						state		<= IDLE;
					end
					default: 		begin
						state		<= IDLE;
					end
					endcase
				end
				STREAM_WRITE_C: begin
					if (in_ready) begin
						$display("in state STREAM_WRITE_C");
						master_ready	<= 0;
						//local data is only used for simulation
						//we should be really writing to the address
						local_data	<= in_data;
						out_data	<= in_data;
						$display("read data: %h", in_data);
						rw_count	<= rw_count - 1;
						$display ("rw_count: %d\n", rw_count);
						if (rw_count <= 1)begin
							$display ("return to IDLE");
							state	<= IDLE;
							out_en	<= 1;
						end
					end
				end
				STREAM_WRITE: begin
					if (in_ready) begin
						$display("in state STREAM_WRITE");
						master_ready	<= 0;
						//local data is only used for simulation
						//we should be really writing to the address
						local_data	<= in_data;
						out_data	<= in_data;
						$display("read data: %h", in_data);
						rw_count	<= rw_count - 1;
						$display ("rw_count: %d\n", rw_count);
						if (rw_count <= 1)begin
							$display ("return to IDLE");
							state	<= IDLE;
							out_en	<= 1;
						end
					end
				end
				STREAM_READ_C: begin
					if (out_ready) begin
						$display("in state STREAM_READ_C");
						out_en			<= 1;	
						out_data		<= 32'h55555555;
						rw_count	<= rw_count - 1;
						$display ("rw_count: %d\n", rw_count);
						if (rw_count <= 1)begin
							$display ("return to IDLE");
							state	<= IDLE;
						end
					end
				end
				STREAM_READ: begin
					if (out_ready) begin
						$display("in state STREAM_READ");
						out_en			<= 1;	
						out_data		<= 32'h55555555;
						rw_count	<= rw_count - 1;
						$display ("rw_count: %d\n", rw_count);
						if (rw_count <= 1)begin
							$display ("return to IDLE");
							state	<= IDLE;
						end
					end
				end
				default: begin
				end
			endcase


		end
		//handle output
	end

endmodule
