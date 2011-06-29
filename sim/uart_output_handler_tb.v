//uart_output_handler_tb.v

module uart_output_handler_tb;
	//defines
	parameter	UART_DELAY_VALUE = 8'hA; 
	
	//make a reset that pulses once
	reg rst = 	0;
	reg clk	=	0;

	//output handler specification registers
	reg [31:0] 	output_status	= 0;
	reg [31:0]	output_address	= 0;
	reg [31:0]	output_data		= 0;
	reg			uart_ready		= 0;
	reg			send_en			= 0;

	//private registers
	reg [7:0] 	uart_delay 		= 0;
	reg 		initiate_tx		= 0;
	reg			wbm_send		= 0;

	//output from the uart_output_handler
	wire [7:0]	byte;
	wire 		handler_ready;
	wire		uart_byte_en;
	wire		output_finished;
	
	uart_output_handler oh (
		.clk(clk),
		.rst(rst),
		.byte(byte),
		.status(output_status),
		.address(output_address),
		.data(output_data),
		.send_en(send_en),
		.uart_ready(uart_ready),
		.handler_ready(handler_ready),
		.uart_byte_en(uart_byte_en),
		.finished(output_finished)
	);

	initial begin
		$dumpfile("output_handler.vcd");
		$dumpvars(0, uart_output_handler_tb);
		$dumpvars(0, oh);

		#5 
			rst	=	1;
		#5
			rst =	0;

		#5
		
			initiate_tx		<= 1;
		#5
			initiate_tx		<= 0;
	end

	always #1 clk	= ~clk;

	//UART Simulator
	always @ (posedge clk) begin
		if (rst == 1) begin
			uart_ready 		<= 1;
			uart_delay 		<= 0;
		end


		//if the output handler called to send data to the UART initiate the delay
		if (uart_byte_en == 1) begin
			uart_delay		<= UART_DELAY_VALUE;
			uart_ready		<= 0;
		end

		//delay the response of the UART to simulate UART behavior
		if (uart_delay == 0) begin
			uart_ready 		<= 1;
		end
		else begin
			uart_delay 		<= uart_delay - 1;
		end
	end

	//Wishbone Master Simulator
	always @ (posedge clk) begin

		if (!handler_ready) begin
			send_en <= 0;
		end
		if (rst == 1) begin
			wbm_send 		<= 0;	
		end
		if (initiate_tx == 1 && handler_ready == 1) begin
			wbm_send 		<= 1;
		end

		if (handler_ready == 1 && wbm_send == 1) begin
			output_status 	<= 32'h89ABCDEF;
			output_address 	<= 32'hFEDCBA98;
			output_data		<= 32'h01234567;
			send_en			<= 1;
			wbm_send		<= 0;
		end
		if (output_finished) begin
			$finish;
		end
	end


	initial $monitor ("%t: rst:%h, init: %h, s_en:%h, h_ready:%h, byte:%h, value:%c, status:%h, address:%h, data:%h", $time, rst, initiate_tx, send_en, handler_ready, byte, byte, output_status, output_address, output_data);

endmodule
