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

reg	[31:0]	gpio0_in;
wire [31:0]	gpio0_out;


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

//arbitrator
wire 			arb_we_o;
wire 			arb_cyc_o;
wire 			arb_stb_o;
wire	[3:0]	arb_sel_o;
wire 			arb_ack_i;
wire 	[31:0]	arb_dat_o;
wire 	[31:0]	arb_dat_i;
wire	[31:0]	arb_adr_o;
wire 			arb_int_i;
//arbitrator
arbitrator_2_masters arb (
	.clk(clk),
	.rst(rst),

	.m0_we_i(wbs0_we_o),
	.m0_cyc_i(wbs0_cyc_o),
	.m0_stb_i(wbs0_stb_o),
	.m0_sel_i(wbs0_sel_o),
	.m0_ack_o(wbs0_ack_i),
	.m0_dat_i(wbs0_dat_o),
	.m0_dat_o(wbs0_dat_i),
	.m0_adr_i(wbs0_adr_o),
	.m0_int_o(wbs0_int_i),

	.m1_we_i(wbs1_we_o),
	.m1_cyc_i(wbs1_cyc_o),
	.m1_stb_i(wbs1_stb_o),
	.m1_sel_i(wbs1_sel_o),
	.m1_ack_o(wbs1_ack_i),
	.m1_dat_i(wbs1_dat_o),
	.m1_dat_o(wbs1_dat_i),
	.m1_adr_i(wbs1_adr_o),
	.m1_int_o(wbs1_int_1),

	.s_we_o(arb_we_o),
	.s_cyc_o(arb_cyc_o),
	.s_stb_o(arb_stb_o),
	.s_sel_o(arb_sel_o),
	.s_ack_i(arb_ack_i),
	.s_dat_o(arb_dat_o),
	.s_dat_i(arb_dat_i),
	.s_adr_o(arb_adr_o),
	.s_int_i(arb_int_i)
);

//slave 0
simple_gpio sg0 (

	.clk(clk),
	.rst(rst),
	
	.wbs_we_i(arb_we_o),
	.wbs_cyc_i(arb_cyc_o),
	.wbs_dat_i(arb_dat_o),
	.wbs_stb_i(arb_stb_o),
	.wbs_ack_o(arb_ack_i),
	.wbs_dat_o(arb_dat_i),
	.wbs_adr_i(arb_adr_o),
	.wbs_int_o(arb_int_i),

	.gpio_in(gpio0_in),
	.gpio_out(gpio0_out)
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

integer data_count;

always #2 clk = ~clk;


//initial begin
//    $monitor ("%t: gpio0_out: %h", $time, gpio0_out); 
//end

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
	#20
		rst				<= 0;
		out_ready 		<= 1;

	if (fd_in == 0) begin
		$display ("input stimulus file was not found");
	end
	else begin
		while (!$feof(fd_in)) begin
			#20
			//read in a command
			read_count = $fscanf (fd_in, "%h:%h:%h\n", in_command, in_address, in_data);
			$display ("read %d items", read_count);
			$display ("read: C:A:D = %h:%h:%h", in_command, in_address, in_data);
			#4
			//just send the command normally
			in_ready 		<= 1;
			timeout_count	= `TIMEOUT_COUNT;
			#2
			in_ready		<= 0;
			out_ready 		<= 1;
			#2
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
	end
	$fclose (fd_in);
	$fclose (fd_out);
	$finish();
end

always @ (posedge clk) begin
	if (rst) begin
		gpio0_in <= 32'h0;
	end
	else begin
		if (gpio0_in != gpio0_out) begin
			$display ("gpio value: %h", gpio0_out);
			gpio0_in <= gpio0_out;
		end
	end
end


endmodule
