//wishbone master interconnect testbench
/*
Distributed under the MIT licesnse.
Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

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

/*
	11/12/2011
		-overhauled the design to behave more similar to a real I/O handler
		-changed the timeout to 40 seconds to allow the wishbone master to catch
		nacks
	11/08/2011
		-added interrupt support
*/

`timescale 1 ns/100 ps

`define TIMEOUT_COUNT 30000
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
reg [27:0]	in_data_count = 0;
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
wire [3:0]	wbm_sel_o;
wire [31:0]	wbm_adr_o;
wire [31:0]	wbm_dat_i;
wire [31:0]	wbm_dat_o;
wire		wbm_ack_o;
wire		wbm_int_o;


wishbone_master wm (
	.clk(clk),
	.rst(rst),
	.in_ready(in_ready),
	.in_command(in_command),
	.in_address(in_address),
	.in_data(in_data),
	.in_data_count(in_data_count),
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
wire		wbs0_we_o;
wire		wbs0_cyc_o;
wire[31:0]	wbs0_dat_o;
wire		wbs0_stb_o;
wire [3:0]	wbs0_sel_o;
wire		wbs0_ack_i;
wire [31:0]	wbs0_dat_i;
wire [31:0]	wbs0_adr_o;
wire		wbs0_int_i;


//wishbone slave 1 signals
wire		wbs1_we_o;
wire		wbs1_cyc_o;
wire[31:0]	wbs1_dat_o;
wire		wbs1_stb_o;
wire [3:0]	wbs1_sel_o;
wire		wbs1_ack_i;
wire [31:0]	wbs1_dat_i;
wire [31:0]	wbs1_adr_o;
wire		wbs1_int_i;


wire		sdram_clk;
wire		sdram_cke;
wire		sdram_cs_n;
wire		sdram_ras_n;
wire		sdram_cas_n;
wire		sdram_we_n;

wire	[11:0]	sdram_addr;
wire	[1:0]	sdram_bank;
wire	[15:0]	sdram_data;
wire	[1:0]	sdram_data_mask;

wire		sdram_ready;

reg		[15:0]	sdram_in_data;
//assign		sdram_data = (in_command == 2) ? sdram_in_data : 16'hZZZZ;


mt48lc4m16 
//#(
//	tdevice_TRCD = 10
//)
ram (
				.A11	(sdram_addr[11]),
				.A10	(sdram_addr[10]),
				.A9		(sdram_addr[9]),
				.A8		(sdram_addr[8]),
				.A7		(sdram_addr[7]),
				.A6		(sdram_addr[6]),
				.A5		(sdram_addr[5]),
				.A4		(sdram_addr[4]),
				.A3		(sdram_addr[3]),
				.A2		(sdram_addr[2]),
				.A1		(sdram_addr[1]),
				.A0		(sdram_addr[0]),

				.DQ15	(sdram_data[15]),
				.DQ14	(sdram_data[14])  ,
				.DQ13	(sdram_data[13]),
				.DQ12	(sdram_data[12]),
				.DQ11	(sdram_data[11]),
				.DQ10	(sdram_data[10]),
				.DQ9	(sdram_data[9]),
				.DQ8	(sdram_data[8]),
				.DQ7	(sdram_data[7]),
				.DQ6	(sdram_data[6]),
				.DQ5	(sdram_data[5]),
				.DQ4	(sdram_data[4]),
				.DQ3	(sdram_data[3]),
				.DQ2	(sdram_data[2]),
				.DQ1	(sdram_data[1]),
				.DQ0	(sdram_data[0]),

				.BA0	(sdram_bank[0]),
				.BA1	(sdram_bank[1]),
				.DQMH	(sdram_data_mask[1]),
				.DQML	(sdram_data_mask[0]),
				.CLK	(sdram_clk),
				.CKE	(sdram_cke),
				.WENeg	(sdram_we_n),
				.RASNeg	(sdram_ras_n),
				.CSNeg	(sdram_cs_n),
				.CASNeg (sdram_cas_n)
);

//slave 1
wb_sdram s1 (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(wbs1_we_o),
	.wbs_cyc_i(wbs1_cyc_o),
	.wbs_dat_i(wbs1_dat_o),
	.wbs_stb_i(wbs1_stb_o),
	.wbs_sel_i(wbs1_sel_o),
	.wbs_ack_o(wbs1_ack_i),
	.wbs_dat_o(wbs1_dat_i),
	.wbs_adr_i(wbs1_adr_o),
	.wbs_int_o(wbs1_int_i),

	.sdram_clk(sdram_clk ),
	.sdram_cke(sdram_cke ),
	.sdram_cs_n(sdram_cs_n ),
	.sdram_ras_n(sdram_ras_n ),
	.sdram_cas_n(sdram_cas_n ),
	.sdram_we_n(sdram_we_n ),

	.sdram_addr(sdram_addr ),
	.sdram_bank(sdram_bank ),
	.sdram_data(sdram_data ),
	.sdram_data_mask(sdram_data_mask ),
	.sdram_ready(sdram_ready)

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
	.m_sel_i(wbm_sel_o),
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
	.s1_sel_o(wbs1_sel_o),
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

integer data_count;

always #10 clk = ~clk;


reg		execute_command;
reg		command_finished;
reg		read_data;
reg		data_read;

initial begin
	fd_out			=	0;
	read_count		= 	0;
	data_count		=	0;
	data_read		<= 	0;
	timeout_count	=	0;
	execute_command	<=	0;

	$dumpfile ("design.vcd");
	$dumpvars (0, wishbone_master_tb);
	//$dumpvars (0, wm);
	fd_in = $fopen(`INPUT_FILE, "r");
	fd_out = $fopen(`OUTPUT_FILE, "w");

	rst				<= 0;
	#20
	rst				<= 1;

	//clear the handler signals
	in_ready		<= 0;
	in_command		<= 0;
	in_address		<= 32'h0;
	in_data			<= 32'h0;
	in_data_count	<= 0;
	out_ready		<= 32'h0;
	//clear wishbone signals
	#100
	rst				<= 0;
	out_ready 		<= 1;

	#1000
	while (!sdram_ready) begin
		#100
		execute_command <= 0;
	end

	$display ("SDRAM Ready");

	if (fd_in == 0) begin
		$display ("TB: input stimulus file was not found");
	end
	else begin
		while (!$feof(fd_in)) begin
			//read in a command
			read_count = $fscanf (fd_in, "%h:%h:%h:%h\n", in_data_count, in_command, in_address, in_data);

			if (read_count != 4) begin
				ch = $fgetc(fd_in);
				$display ("Error: read_count = %h", read_count);
				$display ("Character: %h", ch);
			end
			else begin
				$display ("TB: executing command");
				execute_command	<= 1;
				while (~command_finished) begin
					data_read	<= 0;

					if ((in_command & 32'h0000FFFF) == 1) begin
						if (read_data && ~data_read) begin
							read_count = $fscanf(fd_in, "%h\n", in_data);	
							$display ("TB: reading a new double word: %h", in_data);
							data_read	<= 1;
						end
					end

					//so time porgresses wait a tick
					#4
					//this doesn't need to be here, but there is a bug with iverilog that wont allow me to put a delay in right before an 'end' statement
					execute_command	<= 1;
				end //while command is not finished
				while (command_finished) begin
					#100
					execute_command <= 0;
				end
				#500
				$display ("TB: finished command");
				//if (!$feof(fd_in)) begin
				//	ch = $fgetc(fd_in);
					//$display("ch: %h", ch);
				//end
			end //end read_count == 4
		end //end while ! eof
	end //end not reset
	#100
	$display("TB: Closing Files");
	$fclose (fd_in);
	$fclose (fd_out);
	$finish();
end

parameter TB_IDLE		=	4'h0;
parameter TB_EXECUTE	=	4'h1;
parameter TB_WRITE		=	4'h2;
parameter TB_READ		=	4'h3;

reg	[3:0]	state = TB_IDLE;

reg	reading_multiple	= 0;
reg	prev_int			= 0;

//initial begin
//    $monitor("%t, state: %h", $time, state);
//end

always @ (negedge sdram_clk, rst) begin
	if (rst) begin
		sdram_in_data	<=	16'h0000;
	end
	else begin
		if (in_command == 2) begin
			//sdram_in_data[15:8]	<=	sdram_in_data[15:8] - 1;
			//sdram_in_data[7:0]	<=	sdram_in_data[7:0] + 1;
			sdram_in_data	<=	sdram_in_data + 1;
		end
	end
end

always @ (posedge clk) begin
	in_ready			<= 0;
	out_ready			<= 1;
	command_finished	<= 0;

	if (rst) begin
		state				<= TB_IDLE;
		read_data			<= 0;
		reading_multiple	<= 0;
		timeout_count		<= 0;
		prev_int			<= 0;
	end
	else begin
		if (timeout_count > 0) begin
			timeout_count	<= timeout_count - 1;
		end
		if (execute_command && timeout_count == 0) begin
			$display ("TB: Master timed out while executing command: %h", in_command);
			state	<= TB_IDLE;
			command_finished <= 1;

		end //end reached the end of a timeout

		case (state)
			TB_IDLE: begin
				if (out_en) begin
					state	<= TB_READ;
					out_ready	<= 0;
				end
				if (execute_command & ~command_finished) begin
					$display ("TB: #:C:A:D = %h:%h:%h:%h", in_data_count, in_command, in_address, in_data);
					timeout_count	<= `TIMEOUT_COUNT;
					state			<= TB_EXECUTE;
				end
			end
			TB_EXECUTE: begin
				if (master_ready) begin
					//send the command over	
					in_ready	<= 1;
					if ((in_command & 32'h0000FFFF) == 1) begin
						//write command
						//in_commands are read from the above initial statement
						//in_data count
						//in_command
						//in_address
						//in_data
						if (in_data_count > 0) begin
							in_data_count = in_data_count - 1;
						end
						state	<= TB_WRITE;
					end
					else begin
						//read command
						state	<= TB_READ;
					end
				end
			end
			TB_WRITE: begin
				//write data to the master
				if (out_en) begin
					//got a response
					$display ("TB: read: S:A:D = %h:%h:%h\n", out_status, out_address, out_data);
				end
				else if (master_ready && ~in_ready) begin
					if (in_data_count == 0) begin
						$display("TB: finished write");
						//wrote last double word of data
						command_finished	<= 1;
						state	<= TB_IDLE;
					end
					else begin
						//need to write more data, ask the read block to read more
						if (data_read) begin
							$display ("TB: send new data: %h", in_data);
							read_data	<= 0;
							in_ready	<= 1;
							in_data_count	<= in_data_count -1;
							//the in data is set by the initial
						end
						else begin
							$display("TB: (burst mode) get another double word");
							timeout_count <= `TIMEOUT_COUNT;
							read_data	<= 1;
						end//send another data
					end
				end
			end //write command
			TB_READ: begin
				//read data from the master
				if (out_en) begin
					$display ("TB: read: S:A:D = %h:%h:%h", out_status, out_address, out_data);
					out_ready	<= 0;
					if (out_data_count == 0) begin
						if (reading_multiple) begin
							reading_multiple	<= 0;
						end
						else begin
							command_finished	<= 1;
							state	<= TB_IDLE;
						end
					end
					else begin
						reading_multiple	<= 1;
						timeout_count <= `TIMEOUT_COUNT;
					end
				end //enable an write to the output handler
			end //read or other commands
			default: begin
				$display ("TB: state is wrong");
				state	<= TB_IDLE;
			end //somethine wrong here
		endcase //state machine
		if (out_en && out_status == `PERIPH_INTERRUPT) begin
			$display("TB: Output Handler Recieved interrupt");
			$display("TB:\tcommand: %h", out_status);
			$display("TB:\taddress: %h", out_address);
			$display("TB:\tdata: %h", out_data);
		end
	end//not reset
end

endmodule
