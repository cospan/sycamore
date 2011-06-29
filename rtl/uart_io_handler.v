//uart_io_handler.v

//generalize the uart handler

module uart_io_handler (
	clk,
	rst,

	//input
	in_ready,
	in_command,
	in_address,
	in_data,

	//output
	out_ready,
	out_en,
	out_status,
	out_address,
	out_data,

	//phy
	phy_uart_in,
	phy_uart_out
);

//input/output signals
input				clk;
input				rst;

output				in_ready;
output [31:0]		in_command;
output [31:0]		in_address;
output [31:0]		in_data;

output				out_ready;
input				out_en;
input [31:0]		out_status;
input [31:0]		out_address;
input [31:0]		out_data;

//these are the only thing that are different between xxx_io_handler
input				phy_uart_in;
output				phy_uart_out;


//wires
wire 				uart_byte_en;
wire [7:0]			out_byte;
wire				byte_available;
wire [7:0]			in_byte;
wire				uart_in_busy;

//not used
wire				uart_out_busy;
wire				out_finished;

//REAL UART use this when actually implementing on a board
uart uart_dev (
	.clk(clk),
	.rst(rst),
	.rx(phy_uart_in),
	.tx(phy_uart_out),
	.transmit(uart_byte_en),
	.tx_byte(out_byte),
	.received(byte_available),
	.rx_byte(in_byte),
	.is_receiving(uart_in_busy),
	.is_transmitting(uart_out_busy)
//	.recv_error(),
);

/*
//FAKE UART use this when testing
uart_faux uart_dev (
	.clk(clk),
	.rst(rst),
	.rx(phy_uart_in),
	.tx(phy_uart_out),
	.transmit(uart_byte_en),
	.tx_byte(out_byte),
	.received(byte_available),
	.rx_byte(in_byte),
	.is_receiving(uart_in_busy),
	.is_transmitting(uart_out_busy),
//	.recv_error(),
);
*/

uart_input_handler uih(
	.clk(clk),
	.rst(rst),
	.byte_available(byte_available),
	.byte(in_byte),
	.command(in_command),
	.address(in_address),
	.data(in_data),
	.ready(in_ready));

uart_output_handler uoh(
	.clk(clk),
	.rst(rst),
	.byte(out_byte),
	.status(out_status),
	.address(out_address),
	.data(out_data),
	.send_en(out_en),
	.uart_ready(~uart_out_busy),
	.handler_ready(out_ready),
	.uart_byte_en(uart_byte_en),
	.finished(out_finished));

endmodule
