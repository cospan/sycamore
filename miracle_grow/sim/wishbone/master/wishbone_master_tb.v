//wishbone master testbench

/**
 * 	excersize the wishbone master by executing all the commands and observing
 *	the output
 *
 *	Commands to test
 *
 *	COMMAND_PING
 *		-send a ping request, and observe the response
 *			-response
 *				- S: 0xFFFFFFFF
 *				- A: 0x00000000
 *				- D: 0x00001EAF
 *	COMMAND_WRITE
 *		-send a request to write to address 0x00000000, the output wb 
 *		signals should correspond to a the wirte... 
 *		I might need a simulated slave for this to work
 *			-response
 *				- S: 0xFFFFFFFE
 *				- A: 0x00000000
 *	COMMAND_READ
 *		-send a reqeust to read from address 0x00000000, the output wb signals
 *		should correspond to a read. a simulated slave might be required for 
 *		this
 *		to work
 *			-response
 * 				- S: 0xFFFFFFFD
 *				- A: 0x00000000
 *	COMMAND_WSTREAM_C
 *		-send a request to write to consecutive address starting 
 *		from 0x00000000,
 *		write to 4 consecutive address and observe the wb signals
 *			0x00, 0x01, 0x02, 0x03
 *			-respone
 *				- S: 0XFFFFFFFC
 *				
 *	COMMAND_WSTREAM
 *		-send a request to write to a specific address a specified number of times
 *		0x00000000 4 times and observe the signals
 *			-response
 *				- S: 0xFFFFFFFB
 *	COMMAND_RSTREAM_C
 *		-send a request to read from consecutive addresses starting from 0x00000000
 *		and the next 4 addresses 0x00, 0x01, 0x02, 0x03
 *			-respone
 *				- S: 0xFFFFFFFA
 *	COMMAND_RSTREAM
 *		-send a request to read from the same address starting from 0x00000000
 *		for 4 times, and observe the wishbone signals and the output
 *			-response
 *				- S: 0xFFFFFFF9
 *	COMMAND_RW_FLAGS
 *		-send a request to write all flags to 0x00000000
 *		-sned a request to read all the flags (confirm 0x00000000)
 *		-send a request to write all the flags, but mask half of them
 *		-send a request to read all the flags, and verify that only half of
 *		the flags were written to
 *	COMMAND_INTERRUPTS
 *		-send a request to write all interrupt to 0x00000000
 *		-send a request to read all the flags (confirm 0x00000000)
 *		-send a request to write all the flags, but mask half of them
 *		-send a request to reall all the flags, and verify that only half of
 *		the flags were written to
 */
`define TIMEOUT_COUNT 20
`define INPUT_FILE "master_input_test_data.txt"  
`define OUTPUT_FILE "master_output_test_data.txt"

module wishbone_master_tb (
);

//test signals
reg			clk	= 0;
reg			rst = 0;
wire		master_ready;
reg 		in_ready;
reg [31:0]	in_command;
reg [31:0] 	in_address;
reg [31:0] 	in_data;
reg 		out_ready;
wire 		out_en;
wire [31:0] out_status;
wire [31:0] out_address;
wire [31:0]	out_data;

//wishbone signals
wire [31:0] wb_addr_o;
wire [31:0]	wb_dat_o;
reg [31:0]	wb_dat_i;
wire		wb_str_o;
wire		wb_cyc_o;
wire 		wb_we_o;
wire 		wb_msk_o;
wire 		wb_sel_o;
reg			wb_ack_i;



wishbone_master wm (
	.clk(clk),
	.rst(rst),
	.in_ready(in_ready),
	.in_command(in_command),
	.in_address(in_address),
	.in_data(in_data),
	.out_ready(out_ready),
	.out_en(out_en),
	.out_status(out_status),
	.out_address(out_address),
	.out_data(out_data),
	.master_ready(master_ready),

	.wb_addr_o(wb_addr_o),
	.wb_dat_o(wb_dat_o),
	.wb_dat_i(wb_dat_i),
	.wb_str_o(wb_str_o),
	.wb_cyc_o(wb_cyc_o),
	.wb_we_o(wb_we_o),
	.wb_msk_o(wb_msk_o),
	.wb_sel_o(wb_sel_o),
	.wb_ack_i(wb_ack_i)
);

integer fd_in;
integer fd_out;
integer read_count;
integer timeout_count;
integer ch;

integer data_count;

always #2 clk = ~clk;

initial begin
	fd_out			=	0;
	read_count		= 	0;
	data_count		=	0;
	timeout_count	=	0;

	$dumpfile ("design.vcd");
	$dumpvars (0, wishbone_master_tb);
	$dumpvars (0, wm);
	fd_in = $fopen(`INPUT_FILE, "r");
	fd_out = $fopen(`OUTPUT_FILE, "w");

		rst				<= 0;
	#4
		rst				<= 1;

		//clear the handler signals
		in_ready		<= 0;
		in_command		<= 0;
		in_address		<= 32'h0;
		in_data			<= 32'h0;
		out_ready		<= 32'h0;
		//clear wishbone signals
		wb_dat_i		<= 32'h0;
		wb_ack_i		<= 0;
	#20
		rst				<= 1;
		out_ready 		<= 1;

	if (fd_in == 0) begin
		$display ("input stimulus file was not found");
	end
	else begin
		while (!$feof(fd_in)) begin
			//read in a command
			read_count = $fscanf (fd_in, "%h:%h:%h\n", in_command, in_address, in_data);
			$display ("read %d items", read_count);
			$display ("read: C:A:D = %h:%h:%h", in_command, in_address, in_data);
			#4
			case (in_command)

				`COMMAND_WSTREAM_C: begin
					/*the data will hold the count of the number of bytes 
					I'll have to send to the host, so I don't have to keep any
					local arrays of integers I'll just send them to the host when I 
					read from a file, and count down locally the number of left (from
					in data)
					*/
					//save the count for the timeout
					$display ("COMMAND_WSTREAM_C");
					data_count		= in_data;
					in_ready 		<= 1;
					timeout_count	=	`TIMEOUT_COUNT;
					#2
					in_ready		<= 0;
					while (data_count > 0 && timeout_count > 0) begin
						if (master_ready) begin
							$display ("master ready");
							timeout_count 	<= `TIMEOUT_COUNT;
							data_count		<= data_count	- 1;
							read_count = $fscanf(fd_in, ":%h", in_data);
							$display ("read %d items", read_count);
							$display ("sending data: %h", in_data); 
							#2
							in_ready		<= 1;
							#2
							in_ready		<= 0;
							if (data_count == 0) begin
								timeout_count <= -1;
							end
						end
						else begin
							#2
							timeout_count	<= timeout_count - 1;

						end
					end
					if (timeout_count == 0) begin
						$display ("failed to send all the data to the master");
					end

					$fwrite (fd_out, "command: %h:%h:%h response: %h:%h:%h\n", in_command, in_address, in_data, out_status, out_address, out_data);
					while (timeout_count > 0) begin
						if (out_en) begin
							//got a response before timeout
							$display ("read: S:A:D = %h:%h:%h", out_status, out_address, out_data);
							$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
							timeout_count	= -1;
						end
						else begin
							#2
							timeout_count 	= timeout_count - 1;
						end
					end

					if (timeout_count == 0) begin
						$display ("Wishbone master timed out while executing command: %h", in_command);
						//flush out the end of the data read command
						ch = 1;
						while (!$feof(fd_in) && ch != "\n") begin
							ch	=	$fgetc(fd_in);
						end
					end					
				end
				`COMMAND_WSTREAM: begin
					$display ("COMMAND_WSTREAM");
					//same as prev
					data_count		= in_data;
					in_ready 		<= 1;
					timeout_count	=	`TIMEOUT_COUNT;
					#2
					in_ready		<= 1;
					while (data_count > 0 && timeout_count > 0) begin
						if (master_ready) begin
							timeout_count 	= `TIMEOUT_COUNT;
							data_count		= data_count	- 1;
							read_count = $fscanf(fd_in, ":%h", in_data);
							#2
							in_ready		<= 1;
							#2
							in_ready		<= 0;
							if (data_count == 0) begin
								timeout_count = -1;
							end
						end
						else begin
							timeout_count		<= timeout_count - 1;
						end
					end

					$fwrite (fd_out, "%h:%h:%h response: %h:%h:%h\n", in_command, in_address, in_data, out_status, out_address, out_data);
					while (timeout_count > 0) begin
						if (out_en) begin
							//got a response before timeout
							$display ("read: S:A:D = %h:%h:%h", out_status, out_address, out_data);
							$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
							timeout_count	= -1;
						end
						else begin
							#2
							timeout_count 	= timeout_count - 1;
						end
					end

					if (timeout_count == 0) begin
						$display ("Wishbone master timed out while executing command: %h", in_command);
					end

				end
				`COMMAND_RSTREAM_C: begin

					$display("COMMAND_RSTREAM_C");
					//read data from the master in_data (the count) number of tiems
					data_count		= in_data;
					in_ready 		<= 1;
					timeout_count	=	`TIMEOUT_COUNT;
					#2
					in_ready		<= 1;

					$fwrite (fd_out, "command: %h:%h:%h response:", in_command, in_address, in_data);
					while (data_count > 0 && timeout_count > 0) begin
						if (out_en) begin
							data_count = data_count - 1;	
							$display ("read %h", out_data);
							$fwrite (fd_out, ":%h", out_data);
							timeout_count = `TIMEOUT_COUNT;
						end
						else begin
							#2
							timeout_count = timeout_count - 1;
						end
					end
					if (timeout_count == 0) begin
						$display("timeout waiting for response");
					end
					$fwrite(fd_out, "\n");

				end
				`COMMAND_RSTREAM: begin
					$display("COMMAND_RSTREAM");
					//read data from the master in_data (the count) number of tiems
					data_count		= in_data;
					in_ready 		<= 1;
					timeout_count	=	`TIMEOUT_COUNT;
					#2
					in_ready		<= 1;

					$fwrite (fd_out, "%h:%h:%h response:", in_command, in_address, in_data);
					while (data_count > 0 && timeout_count > 0) begin
						if (out_en) begin
							data_count = data_count - 1;	
							$display ("read %h", out_data);
							$fwrite (fd_out, ":%h", out_data);
							timeout_count = `TIMEOUT_COUNT;
						end
						else begin
							#2
							timeout_count = timeout_count - 1;
						end
					end
					if (timeout_count == 0) begin
						$display("timeout waiting for response");
					end
					$fwrite(fd_out, "\n");
				end
				default: begin
					//just send the command normally
					in_ready 		<= 1;
					timeout_count	= `TIMEOUT_COUNT;
					#2
					in_ready		<= 0;
					out_ready 		<= 1;
					$fwrite (fd_out, "command: %h:%h:%h response: ", in_command, in_address, in_data);
					while (timeout_count > 0) begin
						if (out_en) begin
							//got a response before timeout
							$display ("read: S:A:D = %h:%h:%h\n", out_status, out_address, out_data);
							$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
							timeout_count	= -1;
						end
						else begin
							#2
							timeout_count 	= timeout_count - 1;
						end
					end

					if (timeout_count == 0) begin
						$display ("Wishbone master timed out while executing command: %h", in_command);
					end
				end
			endcase
		end
	end
	$fclose (fd_in);
	$fclose (fd_out);
	$finish();
end

endmodule
