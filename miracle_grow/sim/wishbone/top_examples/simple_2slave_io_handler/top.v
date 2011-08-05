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



module top (
    clk,
    rst,
    TX,
    RX,
    led,
    switch,
    btn_north,
    btn_south,
    btn_east,
    btn_west
);

input    clk;
input    rst;
output   TX;
input    RX;
output   [7:0] led;
input    [3:0] switch;
input    btn_north;
input    btn_south;
input    btn_east;
input    btn_west;

wire		master_ready;

wire        uart_rx_en;
wire [7:0]  uart_in_byte;

wire		uart_tx_en;
wire [7:0]  out_byte;
wire 		uart_is_transmitting;
wire        is_receiving;
wire        recv_error;

reg			read_command;
reg			write_command;
reg			interconnect_ack;

assign led[7] = is_receiving;
assign led[6] = write_command;
assign led[5] = read_command;
assign led[4] = interconnect_ack;

//uart input handler
wire [31:0]	in_command;
wire [31:0] in_address;
wire [31:0] in_data;
wire [27:0] in_data_count;
wire        ih_ready;

//uart output handler
wire [31:0]  out_status;
wire [31:0]  out_address;
wire [31:0]  out_data;
wire [27:0]  out_data_count;
wire		oh_ready;
wire        oh_en;


uart_io_handler uioh (
    .clk(clk),
    .rst(rst),
    .ih_ready(ih_ready),
    .in_command(in_command),
    .in_address(in_address),
    .in_data(in_data),
    .in_data_count(in_data_count),
    .oh_ready(oh_ready),
    .oh_en(oh_en),
    .out_status(out_status),
    .out_address(out_address),
    .out_data(out_data),
    .out_data_count(out_data_count),
    .phy_uart_in(RX),
    .phy_uart_out(TX)
);


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
	.in_ready(ih_ready),

	.in_command(in_command),
	.in_address(in_address),
	.in_data(in_data),
    .out_ready(oh_ready),
	.out_en(oh_en),
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

wire [31:0]  gpio1_in;
wire [31:0] gpio1_out;

assign gpio1_in[3:0] = switch[3:0];
assign gpio1_in[4] = btn_north;
assign gpio1_in[5] = btn_east;
assign gpio1_in[6] = btn_west;
assign gpio1_in[7] = btn_south;

//the rest
assign gpio1_in[31:8] = 0;

assign led[3:0]    = gpio1_out[3:0];



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

always @ (posedge clk) begin
	if (rst) begin
		read_command	<= 0;
		write_command	<= 0;
	end
	else begin
		if (ih_ready) begin
			read_command <= ~read_command;
		end
		if (oh_en) begin
			write_command <= ~write_command;
		end

	end
end

always @ (posedge wbm_ack_i) begin
	if (wbm_ack_i) begin
		interconnect_ack <= ~interconnect_ack;
	end
end
endmodule
