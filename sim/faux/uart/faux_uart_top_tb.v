//faux_uart_top_tb.v
module faux_uart_top_tb (
);

	reg clk;
	reg rst;
	reg rx_en;
	reg [7:0] sim_in_byte;
	wire [7:0] sim_out_byte;
	wire tx_ready;
	reg transmit;
	wire [7:0] to_uart_byte;
	wire recieved;
	wire rx_byte;
	wire is_receiving;
	wire is_transmitting;
	wire recv_error;

	
	faux_uart fu (
		.clk(clk),
		.rxt(rst),
		.rx_en(rx_en),
		.sim_in_byte(sim_in_byte),
		.sim_out_byte(sim_out_byte),
		.tx_ready (tx_ready),
		.transmit(transmit),
		.tx_byte(to_uart_byte),
		.received(received),
		.rx_byte(to_uart_byte),
		.is_receiving(is_receiving)
		.is_transmitting(is_transmitting),
		.recv_error(recv_error),
	);

	initial	begin
	$dumpvarsfile("uart_out.vcd");
	$dumpvars(0, faux_uart_top_tb);
	$dumpfars(0, fu);
	$readmemh("input_stimulus.txt", data);


	#5
		rst = 1;
	#5
		rst = 0;
	
	

	end

always clk = ~clk;

always @ (posedge clk) begin
	

end
endmodule
