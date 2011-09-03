//wishbone master interconnect testbench
/*
Distributed under the MIT licesnse.
Copyright (c) 2011 Dave McCoy (dave.mccoy@leaflabs.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/


/**
 * Exercise the sdram core by 

*/
`timescale 100ps/1ps
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
wire [27:0] out_data_count;

//wishbone signals
wire		wbm_we_o;
wire		wbm_cyc_o;
wire		wbm_stb_o;
wire [31:0]	wbm_adr_o;
wire [31:0]	wbm_dat_i;
wire [31:0]	wbm_dat_o;
wire		wbm_ack_o;
wire		wbm_int_o;



//sdram stimulus signals
parameter DEMO_DATA = 16'h1EAF;
wire	[15:0]	sdram_data_in;
wire	ddr_write_en;
wire	ddr_ready;

assign sdram_data_in	= (wbs1_we_o) ? 16'hZ : DEMO_DATA; 

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
    .out_data_count(out_data_count),
	.master_ready(master_ready),

	.wb_adr_o(wbm_adr_o),
	.wb_dat_o(wbm_dat_o),
	.wb_dat_i(wbm_dat_i),
	.wb_stb_o(wbm_stb_o),
	.wb_cyc_o(wbm_cyc_o),
	.wb_we_o(wbm_we_o),
	.wb_msk_o(wbm_msk_o),
	.wb_sel_o(wbm_sel_o),
	.wb_ack_i(wbm_ack_i)
);

//wishbone slave 0 signals
wire		wbs0_we_i;
wire		wbs0_cyc_i;
wire[31:0]	wbs0_dat_i;
wire		wbs0_stb_i;
wire		wbs0_ack_o;
wire [31:0]	wbs0_dat_o;
wire [31:0]	wbs0_adr_o;
wire		wbs0_int_o;



//wishbone slave 1 signals
wire		wbs1_we_i;
wire		wbs1_cyc_i;
wire[31:0]	wbs1_dat_i;
wire		wbs1_stb_i;
wire		wbs1_ack_o;
wire [31:0]	wbs1_dat_o;
wire [31:0]	wbs1_adr_o;
wire		wbs1_int_o;

//slave 0
device_rom_table drt (
    .clk(clk),
    .rst(rst),

    .wbs_we_i(wbs0_we_o),
    .wbs_cyc_i(wbs0_cyc_o),
    .wbs_dat_i(wbs0_dat_o),
    .wbs_stb_i(wbs0_stb_o),
    .wbs_ack_o(wbs0_ack_i),
    .wbs_dat_o(wbs0_dat_i),
    .wbs_adr_i(wbs0_adr_o),
    .wbs_int_o(wbs0_int_i)
);

//slave 0
sdram ram (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(wbs1_we_o),
	.wbs_cyc_i(wbs1_cyc_o),
	.wbs_dat_i(wbs1_dat_o),
	.wbs_stb_i(wbs1_stb_o),
	.wbs_ack_o(wbs1_ack_i),
	.wbs_dat_o(wbs1_dat_i),
	.wbs_adr_i(wbs1_adr_o),
	.wbs_int_o(wbs1_int_i),

		
	.mem_data(sdram_data_in),
	.mem_we(ddr_write_en),
	.debug_ddr_ready(ddr_ready)
);

wishbone_interconnect wi (
    .clk(clk),
    .rst(rst),

    .m_we_i(wbm_we_o),
    .m_cyc_i(wbm_cyc_o),
    .m_stb_i(wbm_stb_o),
    .m_ack_o(wbm_ack_i),
    .m_dat_i(wbm_dat_o),
    .m_dat_o(wbm_dat_i),
    .m_adr_i(wbm_adr_o),
    .m_int_o(wbm_int_i),

    .s0_we_o(wbs0_we_o),
    .s0_cyc_o(wbs0_cyc_o),
    .s0_stb_o(wbs0_stb_o),
    .s0_ack_i(wbs0_ack_i),
    .s0_dat_o(wbs0_dat_o),
    .s0_dat_i(wbs0_dat_i),
    .s0_adr_o(wbs0_adr_o),
    .s0_int_i(wbs0_int_i),

    .s1_we_o(wbs1_we_o),
    .s1_cyc_o(wbs1_cyc_o),
    .s1_stb_o(wbs1_stb_o),
    .s1_ack_i(wbs1_ack_i),
    .s1_dat_o(wbs1_dat_o),
    .s1_dat_i(wbs1_dat_i),
    .s1_adr_o(wbs1_adr_o),
    .s1_int_i(wbs1_int_i)


);

integer fd_in;
integer fd_out;
integer read_count;
integer timeout_count;
integer ch;

reg waiting;

integer data_count;


always #100 clk = ~clk;


initial begin
	fd_out			=	0;
	read_count		= 	0;
	data_count		=	0;
	timeout_count	=	0;

	$dumpfile ("design.vcd");
	$dumpvars (0, wishbone_master_tb);
	fd_in = $fopen(`INPUT_FILE, "r");
	fd_out = $fopen(`OUTPUT_FILE, "w");

		rst				<= 0;
	#800
		rst				<= 1;

		//clear the handler signals
		in_ready		<= 0;
		in_command		<= 0;
		in_address		<= 32'h0;
		in_data			<= 32'h0;
		out_ready		<= 32'h0;
		//clear wishbone signals

		//sim data signals
	#4000
		rst				<= 0;
		out_ready 		<= 1;

	#50000
	if (fd_in == 0) begin
		$display ("input stimulus file was not found");
	end
	else begin
		while (waiting == 1) begin
			#1000
			$display();
		end

		while (!$feof(fd_in)) begin
			//read in a command
			read_count = $fscanf (fd_in, "%h:%h:%h\n", in_command, in_address, in_data);
			$display ("read %d items", read_count);
			$display ("read: C:A:D = %h:%h:%h", in_command, in_address, in_data);
			#800
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
					#400
					in_ready		<= 0;
					#800
					while (data_count > 0 && timeout_count > 0) begin
						$display ("in stream loop data_count: %d, timeout_count %d", data_count, timeout_count);
						if (master_ready) begin
							$display ("master ready");
							timeout_count 	<= `TIMEOUT_COUNT;
							data_count		<= data_count	- 1;
							read_count = $fscanf(fd_in, ":%h", in_data);
							$display ("read %d items", read_count);
							$display ("sending data: %h", in_data); 
							#800
							in_ready		<= 1;
							#800
							in_ready		<= 0;
							if (data_count == 0) begin
								timeout_count <= -1;
							end
						end
						else begin
							#400
							timeout_count	<= timeout_count - 1;

						end
					end
					if (timeout_count == 0) begin
						$display ("failed to send all the data to the master");
					end

					timeout_count 	<= `TIMEOUT_COUNT;
					$fwrite (fd_out, "command: %h:%h:%h response: %h:%h:%h\n", in_command, in_address, in_data, out_status, out_address, out_data);
					while (timeout_count > 0) begin
						$display ("in final timeout timeout_count: %d", timeout_count);
						if (out_en) begin
							//got a response before timeout
							$display ("read: S:A:D = %h:%h:%h", out_status, out_address, out_data);
							$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
							timeout_count	= -1;
						end
						else begin
							#400
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
					data_count		= in_data;
					in_ready 		<= 1;
					timeout_count	=	`TIMEOUT_COUNT;
					#400
					in_ready		<= 0;
					#800
					while (data_count > 0 && timeout_count > 0) begin
						$display ("in stream loop data_count: %d, timeout_count %d", data_count, timeout_count);
						if (master_ready) begin
							$display ("master ready");
							timeout_count 	<= `TIMEOUT_COUNT;
							data_count		<= data_count	- 1;
							read_count = $fscanf(fd_in, ":%h", in_data);
							$display ("read %d items", read_count);
							$display ("sending data: %h", in_data); 
							#800
							in_ready		<= 1;
							#800
							in_ready		<= 0;
							if (data_count == 0) begin
								timeout_count <= -1;
							end
						end
						else begin
							#400
							timeout_count	<= timeout_count - 1;

						end
					end
					if (timeout_count == 0) begin
						$display ("failed to send all the data to the master");
					end

					timeout_count 	<= `TIMEOUT_COUNT;
					$fwrite (fd_out, "command: %h:%h:%h response: %h:%h:%h\n", in_command, in_address, in_data, out_status, out_address, out_data);
					while (timeout_count > 0) begin
						$display ("in final timeout timeout_count: %d", timeout_count);
						if (out_en) begin
							//got a response before timeout
							$display ("read: S:A:D = %h:%h:%h", out_status, out_address, out_data);
							$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
							timeout_count	= -1;
						end
						else begin
							#400
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

				`COMMAND_RSTREAM_C: begin

					$display("COMMAND_RSTREAM_C");
					//read data from the master in_data (the count) number of tiems
					data_count		= in_data;
					in_ready 		<= 1;
					timeout_count	=	`TIMEOUT_COUNT;
					#400
					in_ready		<= 1;
					#400
					$fwrite (fd_out, "command: %h:%h:%h response:", in_command, in_address, in_data);
					while (data_count > 0 && timeout_count > 0) begin
						if (out_en) begin
							data_count = data_count - 1;	
							$display ("read %h", out_data);
							$fwrite (fd_out, ":%h", out_data);
							timeout_count = `TIMEOUT_COUNT;
						end
						else begin
							#400
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
					#400
					in_ready		<= 1;
					#400
					$fwrite (fd_out, "%h:%h:%h response:", in_command, in_address, in_data);
					while (data_count > 0 && timeout_count > 0) begin
						if (out_en) begin
							data_count = data_count - 1;	
							$display ("read %h", out_data);
							$fwrite (fd_out, ":%h", out_data);
							timeout_count = `TIMEOUT_COUNT;
						end
						else begin
							#400
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
					#400
					in_ready		<= 0;
					out_ready 		<= 1;
					#400
					$fwrite (fd_out, "command: %h:%h:%h response: ", in_command, in_address, in_data);
					while (timeout_count > 0) begin
						if (out_en) begin
							//got a response before timeout
							$display ("read: S:A:D = %h:%h:%h\n", out_status, out_address, out_data);
							$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
							timeout_count	= -1;
						end
						else begin
							#400
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
	#1000000
	$fclose (fd_in);
	$fclose (fd_out);
	$finish();
end

always @ (posedge clk) begin
	if (rst) begin
		waiting			<=	1;
	end
	else begin
		if (ddr_ready) begin
			waiting 		<= 	0;
		end
	end

end

endmodule
