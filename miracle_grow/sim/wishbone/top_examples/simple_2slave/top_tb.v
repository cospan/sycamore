//simple 2 port interconnect top example
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
 * 	excersize the wishbone master by executing all the commands and observing
 *	the output
*/

`define TIMEOUT_COUNT 20
`define INPUT_FILE "top_input_test_data.txt"  
`define OUTPUT_FILE "top_output_test_data.txt"

module top_tb (
);

//test signals
reg			clk	= 0;
reg			rst = 0;
wire		master_ready;


reg         stimulus_rx_en;
reg [7:0]   stimulus_in_byte;
wire [31:0]	in_command;
wire [31:0] in_address;
wire [31:0] in_data;

uart_input_handler uih (
    .clk(clk),
    .rst(rst),
    .byte_available(stimulus_rx_en),
    .byte(stimulus_in_byte),
    .command(in_command),
    .address(in_address),
    .data(in_data),
    .ready(in_ready)
);

wire [7:0]  out_byte;
wire [31:0] out_status;
wire [31:0] out_address;
wire [31:0] out_data;
wire        out_en;
wire [15:0] out_data_count;
wire 		out_ready;

reg         stimulus_uart_ready;
wire        uart_byte_en;
wire        finished;

uart_output_handler uoh (
    .clk(clk),
    .rst(rst),
    .byte(out_byte),
    .status(out_status),
    .address(out_address),
    .data(out_data),
    .send_en(out_en),
    .uart_ready(stimulus_uart_ready),
    .handler_ready(out_ready),
    .uart_byte_en(uart_byte_en),
    .data_count(out_data_count),
    .finished(oh_finished)
);


//reg 		in_ready;

//wishbone signals
wire		wbm_we_o;
wire		wbm_cyc_o;
wire		wbm_stb_o;
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
//DRT
wire		wbs0_we_i;
wire		wbs0_cyc_i;
wire[31:0]	wbs0_dat_i;
wire		wbs0_stb_i;
wire		wbs0_ack_o;
wire [31:0]	wbs0_dat_o;
wire [31:0]	wbs0_adr_o;
wire		wbs0_int_o;


//wishbone slave 1 signals
//GPIO
wire		wbs1_we_i;
wire		wbs1_cyc_i;
wire[31:0]	wbs1_dat_i;
wire		wbs1_stb_i;
wire		wbs1_ack_o;
wire [31:0]	wbs1_dat_o;
wire [31:0]	wbs1_adr_o;
wire		wbs1_int_o;

reg [31:0]  gpio1_in;
wire [31:0] gpio1_out;

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
//slave 1
simple_gpio sg1 (

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

	.gpio_in(gpio1_in),
	.gpio_out(gpio1_out)
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

reg[27:0] local_data_count;

integer fd_in;
integer fd_out;
//integer read_count;
integer timeout_count;
integer ch;

integer data_count;


always #2 clk = ~clk;


initial begin
    $monitor ("%t: gpio1_out: %h", $time, gpio1_out); 
end

initial begin
	fd_out			=	0;
    ch              =   0;
	//read_count		= 	0;
	timeout_count	=	0;
    local_data_count =  0;

	$dumpfile ("design.vcd");
	$dumpvars (0, top_tb);
	$dumpvars (0, wm);
	fd_in = $fopen(`INPUT_FILE, "r");
	fd_out = $fopen(`OUTPUT_FILE, "w");

	rst				<= 0;
	#4
		rst				<= 1;
		//clear wishbone signals
        gpio1_in        <= 32'h01234567;
        stimulus_rx_en  <= 0;
        stimulus_in_byte <= 8'h0;
	
	#20
	rst				<= 0;
        

	if (fd_in == 0) begin
		$display ("input stimulus file was not found");
	end
	else begin
		while (!$feof(fd_in)) begin
			//read in a command
            ch  = $fgetc(fd_in);
            while (ch != -1) begin
//                $display ("%c", ch);
                stimulus_in_byte    <= ch;  
                stimulus_rx_en      <= 1;
                #2
                stimulus_rx_en      <= 0;
                #10
                ch = $fgetc(fd_in);
            end
		end
	end
	$fclose (fd_in);
	$fclose (fd_out);
	$finish();
end

integer test;
initial begin
    stimulus_uart_ready             <=1;    
    test                            <= 0;

    #1
    while (1) begin
        #1
        if (uart_byte_en) begin
            $display ("%c", out_byte);
            stimulus_uart_ready <= 0;
            #19
            stimulus_uart_ready <= 1;
        end

    end
end
/*
always @ (posedge clk) begin
    if (rst) begin
        stimulus_uart_ready         <= 1;
        test = 0;
    end
    else begin
        if (uart_byte_en) begin
            //test = $fputc (fd_out, out_byte);
            $display("%c", out_byte);

            stimulus_uart_ready     <= 0;
            #10
            stimulus_uart_ready     <= 1;
        end
    end
end
*/
initial begin
//    $monitor ("%t: in_byte: %c out_byte: %c ih_ready: %h oh_en: %h, uart_out_en: %h", $time, stimulus_in_byte, out_byte, in_ready, out_en, uart_byte_en);

//    $monitor ("%t: uart_out_ready: %h", $time, stimulus_uart_ready);
end

endmodule
