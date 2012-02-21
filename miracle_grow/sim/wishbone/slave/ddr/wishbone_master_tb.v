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


/**
 * Exercise the user slave core by 

*/
`timescale 1ns/1ps
`include "ddr_include.v"
`define TIMEOUT_COUNT 200
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
	.wb_sel_o(wbm_sel_o),
	.wb_stb_o(wbm_stb_o),
	.wb_cyc_o(wbm_cyc_o),
	.wb_we_o(wbm_we_o),
	.wb_msk_o(wbm_msk_o),
	.wb_ack_i(wbm_ack_i)
);

//wishbone slave 0 signals
wire		wbs0_we_o;
wire		wbs0_cyc_o;
wire [3:0]	wbs0_sel_o;
wire[31:0]	wbs0_dat_o;
wire		wbs0_stb_o;
wire		wbs0_ack_i;
wire [31:0]	wbs0_dat_i;
wire [31:0]	wbs0_adr_o;
wire		wbs0_int_i;



//wishbone slave 1 signals
wire		wbs1_we_o;
wire		wbs1_cyc_o;
wire [3:0]	wbs1_sel_o;
wire[31:0]	wbs1_dat_o;
wire		wbs1_stb_o;
wire		wbs1_ack_i;
wire [31:0]	wbs1_dat_i;
wire [31:0]	wbs1_adr_o;
wire		wbs1_int_i;

//slave 0
device_rom_table drt (
    .clk(clk),
    .rst(rst),

    .wbs_we_i(wbs0_we_o),
    .wbs_cyc_i(wbs0_cyc_o),
	.wbs_sel_i(wbs0_sel_o),
    .wbs_dat_i(wbs0_dat_o),
    .wbs_stb_i(wbs0_stb_o),
    .wbs_ack_o(wbs0_ack_i),
    .wbs_dat_o(wbs0_dat_i),
    .wbs_adr_i(wbs0_adr_o),
    .wbs_int_o(wbs0_int_i)
);



//this is a good place to declare some registers, and wires in order to exercise your slave
wire			ddr_clk;
wire			ddr_clk_n;
wire			ddr_clk_fb;
wire			ddr_ras_n;
wire			ddr_cas_n;
wire			ddr_we_n;
wire			ddr_cke;
wire			ddr_cs_n;
wire [`A_RNG]	ddr_a;
wire [`BA_RNG]	ddr_ba;
wire [`DQ_RNG]	ddr_dq;
wire [`DQS_RNG]	ddr_dqs;
wire [`DM_RNG]	ddr_dm;

wire [2:0]	rot	=	3'h0;

parameter		phase_shift		=	100;
parameter		wait200_init 	= 	1;
parameter		clk_multiply	=	13;
parameter		clk_divide		=	5;
//parameter		wait200_init	=	26;

//virtual ddr device
ddr	mt46v16m16 (
	.Dq(	ddr_dq		),
	.Dqs(	ddr_dqs		),
	.Addr(	ddr_a		),
	.Ba(	ddr_ba		),
	.Clk(	ddr_clk		),
	.Clk_n(	ddr_clk_n	),
	.Cke(	ddr_cke		),
	.Cs_n(	ddr_cs_n	),
	.Ras_n(	ddr_ras_n	),
	.Cas_n(	ddr_cas_n	),
	.We_n(	ddr_we_n	),
	.Dm(	ddr_dm		)
);

assign 			ddr_clk_fb	=	ddr_clk;
wire			init_done;

//ddr wishbone slave
wb_ddr #(
	.phase_shift(phase_shift),
	.clk_multiply(clk_multiply),
	.clk_divide(clk_divide),
	.wait200_init(wait200_init)
)ddr0(

	.clk(clk),
	.rst(rst),

	//wishbone slave device
	.wbs_we_i(wbs1_we_o),
	.wbs_cyc_i(wbs1_cyc_o),
	.wbs_dat_i(wbs1_dat_o),
	.wbs_stb_i(wbs1_stb_o),
	.wbs_sel_i(wbs1_sel_o),
	.wbs_ack_o(wbs1_ack_i),
	.wbs_dat_o(wbs1_dat_i),
	.wbs_adr_i(wbs1_adr_o),

	//DDR Ports
	.ddr_clk(		ddr_clk		),
	.ddr_clk_n(		ddr_clk_n	),
	.ddr_clk_fb(	ddr_clk_fb	),
	.ddr_ras_n(		ddr_ras_n	),
	.ddr_cas_n(		ddr_cas_n	),
	.ddr_we_n(		ddr_we_n	),
	.ddr_cke(		ddr_cke		),
	.ddr_cs_n(		ddr_cs_n	),
	.ddr_a(			ddr_a		),
	.ddr_ba(		ddr_ba		),
	.ddr_dq(		ddr_dq		),
	.ddr_dqs(		ddr_dqs		),
	.ddr_dm(		ddr_dm		),
	
	
	//phase shifting
	.rot(			rot			),

	.init_done (	init_done	)
);

wishbone_interconnect wi (
    .clk(clk),
    .rst(rst),

    .m_we_i(wbm_we_o),
    .m_cyc_i(wbm_cyc_o),
    .m_stb_i(wbm_stb_o),
	.m_sel_i(wbm_sel_o),
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


always #10 clk = ~clk;


initial begin
	fd_out			=	0;
	read_count		= 	0;
	data_count		=	0;
	timeout_count	=	0;

	$monitor (out_en);

	$dumpfile ("design.vcd");
	$dumpvars (0, wishbone_master_tb);
	fd_in = $fopen(`INPUT_FILE, "r");
	fd_out = $fopen(`OUTPUT_FILE, "w");

		rst				<= 0;
	#40
		rst				<= 1;

		//clear the handler signals
		in_ready		<= 0;
		in_command		<= 0;
		in_address		<= 32'h0;
		in_data			<= 32'h0;
		out_ready		<= 32'h0;
		//clear wishbone signals

		//sim data signals
	#80
	rst				<= 0;
	out_ready 		<= 1;


	if (fd_in == 0) begin
		$display ("input stimulus file was not found");
	end
	
end


reg ready;

parameter CMD_IDLE = 4'h0;
parameter CMD_READ_COUNT = 4'h1;
parameter CMD_READ_COMMAND = 4'h2;
parameter CMD_IN_PROGRESS = 4'h3; 
parameter CMD_FINISHED = 4'h4;
reg [3:0] cmd_state;


reg [3:0] wishbone_state;

always @ (posedge clk) begin
	if (rst) begin
		cmd_state <= CMD_IDLE;
	end
	else if (ready) begin
		case (cmd_state)
			CMD_IDLE: begin
				$display ("init_done");
				if (!$feof(fd_in)) begin
					read_count = $fscanf (fd_in, "%h:%h:%h\n", in_command, in_address, in_data);
					$display ("read %d items", read_count);
					$display ("read: C:A:D = %h:%h:%h", in_command, in_address, in_data);
					cmd_state <= CMD_IN_PROGRESS;

				end
				else begin
					cmd_state <= CMD_FINISHED;
				end

			end
			CMD_IN_PROGRESS: begin
				if ((wishbone_state == WB_FINISHED) && (flush_line == 0)) begin

					cmd_state <= CMD_IDLE;
				end
			end
			CMD_FINISHED: begin
				$fclose (fd_in);
				$fclose (fd_out);
				$finish();
			end
			default: begin
				cmd_state <= CMD_IDLE;
			end
		endcase
	end
end

parameter WB_IDLE = 4'h0;
parameter WB_SEND = 4'h1;
parameter WB_RESPONSE = 4'h3;
parameter WB_FINISHED = 4'h5;

reg flush_line;

always @ (posedge clk) begin
	in_ready <= 0;
	if (rst) begin
		wishbone_state <= WB_IDLE;
		timeout_count <= 0;
		flush_line <= 0;
	end
	else begin
		if (timeout_count > 0) begin
			timeout_count <= timeout_count - 1;
		end
		if (cmd_state == CMD_IN_PROGRESS) begin
			case (wishbone_state)
				WB_IDLE: begin
					if (cmd_state == CMD_IN_PROGRESS) begin
						wishbone_state <= WB_SEND;
						timeout_count <= `TIMEOUT_COUNT;
					end
				end
				WB_SEND: begin
					//if in_command == write, or write stream count the data out
					if (in_command == `COMMAND_WRITE) begin 
						$display ("write");
						if (data_count > 0 && timeout_count > 0) begin
							if (master_ready) begin
								$display ("master ready");
								timeout_count <= `TIMEOUT_COUNT;
								data_count <= data_count - 1;
								read_count = $fscanf(fd_in, ":%h", in_data);
								in_ready 	<= 1;
							end
						end
						else if (data_count == 0) begin
							$display ("finished sending data to master");
							timeout_count <= `TIMEOUT_COUNT;
							wishbone_state <= WB_RESPONSE; 
						end
						else if (timeout_count == 0) begin
							$display ("Timed out while sending data to master");
							wishbone_state <= WB_FINISHED;
							flush_line <= 1;
						end
					end
					else begin
						//sending one item
						if (timeout_count > 0) begin
							$display ("read");
							if (master_ready) begin
								$display ("master ready");
								in_ready 	<= 1;
								timeout_count <= `TIMEOUT_COUNT;
								wishbone_state <= WB_RESPONSE;
							end
						end
						else begin
							//timeout
							$display ("timeout while sending one item");
							wishbone_state <= WB_FINISHED;
							flush_line <= 1;
						end
					end
				end
				WB_RESPONSE: begin
					//waiting for a response from the master
					if (in_command == `COMMAND_READ) begin
						//reading multiple data
						if (data_count > 0 && timeout_count > 0) begin
							if (out_en) begin
								$display ("read: S:A:D = %h:%h:%h", out_status, out_address, out_data);
								$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
								timeout_count <= `TIMEOUT_COUNT;
								wishbone_state <= WB_FINISHED;
								data_count <= data_count - 1;
							end
						end
						else begin
							$display ("timed out waiting for response 1");
							wishbone_state <= WB_FINISHED;
							flush_line <= 1;

						end
	
					end
					else begin
						$display ("reading data");
						if (timeout_count > 0) begin
							if (out_en) begin
								$display ("read: S:A:D = %h:%h:%h", out_status, out_address, out_data);
								$fwrite (fd_out, "%h:%h:%h\n", out_status, out_address, out_data);
								wishbone_state <= WB_FINISHED;
							end
						end
						else begin
							$display ("timed out waiting for response 2");
							wishbone_state <= WB_FINISHED;
							flush_line <= 1;

						end
	
					end
				end
				WB_FINISHED: begin
					if (flush_line == 0) begin
						$display("go to IDLE");
						wishbone_state <= WB_IDLE;
					end
				end
	
			endcase
		end
	end

	if (flush_line) begin
		$display ("flush: %d", ch);
		if (!$feof(fd_in) && ch != "\n") begin
			$display("flush line");
			ch = $fgetc(fd_in);
			$display ("%c", ch);
		end
		if (ch == "\n") begin
			flush_line <= 0;
			$display ("finished line");
		end
	end

end

parameter INIT_WAIT  = 32'h0400;
reg [31:0]init_timeout;

always @ (posedge clk) begin
	if (rst) begin
		ready <= 0;
		init_timeout <= INIT_WAIT;
	end
	else begin
/*
		if (init_done) begin
			ready <= 1;
		end
*/
		if (init_timeout == 0) begin
			ready <= 1;
		end
		else begin
			//$display ("%d", init_timeout);
			init_timeout <= init_timeout - 1;
		end
	end
end

endmodule
