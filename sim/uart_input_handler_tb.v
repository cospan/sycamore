module uart_input_handler_tb;
	//make a reset that pulses once
	reg rst = 0;
	reg clk = 0;

	//input handler specific registers
	reg 			byte_available 	= 0;
	reg  [7:0] 		byte			= 0;
	wire [31:0]		command;
	wire [31:0]		address_in;
	wire [31:0] 	data_in;
	wire 			ready;

	uart_input_handler ih (
		.clk(clk),
		.rst(rst),
		.byte_available(byte_available),
		.byte(byte),
		.command(command),
		.address(address_in),
		.data(data_in),
		.ready(ready));

	initial begin
		$dumpfile("design.vcd");
		$dumpvars(0, uart_input_handler_tb);
		$dumpvars(0, ih);

		#5
					rst = 1;
		#5 		
					rst = 0;
		#5		
//SEND ID as ASCII 'L'
					byte = 16'h4C;
					byte_available = 1;
		#5		
					byte_available = 0;

//Send command "10000009"

//Send command '0' as ASCII '0'
		#5
					byte = 16'h31;
					byte_available = 1;
		#5
					byte_available = 0;

		#5
					byte = 16'h30;
					byte_available = 1;
		#5
					byte_available = 0;

		#5
					byte = 16'h30;
					byte_available = 1;
		#5
					byte_available = 0;

		#5
					byte = 16'h30;
					byte_available = 1;
		#5
					byte_available = 0;
		
		#5		
					byte = 16'h30;
					byte_available = 1;
		#5		
					byte_available = 0;

		#5
					byte = 16'h30;
					byte_available = 1;
		#5	
					byte_available = 0;

		#5
					byte = 16'h30;
					byte_available = 1;
		#5	
					byte_available = 0;

		#5
					byte = 16'h39;
					byte_available = 1;
		#5	
					byte_available = 0;

//Send data 0x0123456789ABCDEF
		#5	
					byte = 16'h30;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5	
					byte = 16'h31;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5	
					byte = 16'h32;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5	
					byte = 16'h33;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5	
					byte = 16'h34;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5	
					byte = 16'h35;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5
					byte = 16'h36;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5	
					byte = 16'h37;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5
					byte = 16'h38;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		

					byte = 16'h39;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		
	
					byte = 16'h41;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		

					byte = 16'h42;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		
	
					byte = 16'h43;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		

					byte = 16'h44;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		

					byte = 16'h45;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		

					byte = 16'h46;
					byte_available = 1;
		#5		
					byte_available = 0;
		#5		
	

//finished
		#5		
					byte = 16'h30;
					byte_available = 1;
		#5
					byte_available = 0;

		#5 	
					$finish;

	end

	always #1 clk = ~clk;

	initial $monitor ("%t: byte:%h, control:%H, address:%H, ready:%H, data in:%H", $time, byte, command, address_in, ready, data_in);
endmodule

