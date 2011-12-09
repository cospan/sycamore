//uart_top_tb.v
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

`include "project_defines.v"
`define BAUD_RATE 9600
`define PRESCALER 8 

`define CLOCK_DIVIDE `CLOCK_RATE / (`BAUD_RATE * `PRESCALER)

`define HALF_PERIOD (`PRESCALER / 2 * `CLOCK_DIVIDE)
`define FULL_PERIOD (`PRESCALER * `CLOCK_DIVIDE)


module uart_top_tb; 


	reg clk = 0;
	reg rst = 0;

	reg [15:0]	delay		= 0;
	reg			delay_finished = 0;
	reg			hp_delay	= 0;
	reg			fp_delay	= 0;

	reg 		rx 			= 1;
	wire 		tx;
	reg			transmit	= 0;
	reg	[7:0]	tx_byte		= 0;
	wire 		received;
	wire [7:0]	rx_byte;
	wire 		is_receiving;
	wire 		is_transmitting;
	wire 		rx_error;



	//instantiate the uart
	uart urt(
		.clk(clk),
		.rst(rst),
		.rx(rx),
		.tx(tx),
		.transmit(transmit),
		.tx_byte(tx_byte),
		.received(received),
		.rx_byte(rx_byte),
		.is_receiving(is_receiving),
		.is_transmitting(is_transmitting),
		.rx_error(rx_error)
	);

	integer fd_in;
	integer fd_out;
	reg [7:0] ch = 0;
	reg [3:0]	bit_index =0;

	always #1 clk = ~clk;
	
initial begin

	ch 		= 0;

	$dumpfile ("design.vcd");
	$dumpvars (0, uart_top_tb);
	fd_in = $fopen ("uart_input_data.txt", "r");
	//fd_out = $fopen ("uart/uart_output_data.txt", "r");

	rst 					<= 0;	
	#5
	rst 					<= 1;
	rx						<= 1;
	transmit				<= 0;
	tx_byte					<= 8'h00;
	hp_delay				<= 0;
	fp_delay				<= 0;
	bit_index				<= 0;
	#5
	rst 					<= 0;
	#10000

	//testing input
	if (fd_in == 0) begin
		$display("uart_input_data.txt was not found");
	end	
	else begin
//		ch = $fgetc(fd_in);
//		while (ch != -1) begin
//			#10
			fp_delay	<= 1;
			wait(delay_finished == 0);

			$display("Start bit goes low");
//			ch = $fgetc(fd_in);				
			ch = 8'hAA;
			bit_index <= 0;
			//set the rx line low
			rx <= 0;
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			wait(delay_finished);

			//send seventh bit
			$display ("7th....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//send sixth bit
			$display ("6th....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//send fifth bit
			$display ("5th....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//send fourth bit
			$display ("4th....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//send third bit
			$display ("3rd....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//send second bit
			$display ("2nd....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//send first bit
			$display ("1st....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//send zeroith bit
			$display ("0th....");
			rx <= ch[bit_index];
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			bit_index	<= bit_index + 1;
			wait(delay_finished);

			//wait 1 stop bit
			$display ("stop bit");
			rx <= 1;
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			wait(delay_finished);
			rx	<= 1;

			wait(received == 0);


			//test a transmit

			tx_byte 	<= 8'hAA;
			transmit	<= 1;

			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			wait(delay_finished);
			fp_delay	<= 1;
			wait(delay_finished == 0);
			fp_delay	<= 0;
			wait(delay_finished);

			transmit 	<= 0;


			wait (is_transmitting == 0);

//		end
	end
	#10000
	$finish;
end

always @ (posedge clk) begin
	if (rst) begin
		delay <= 16'h0;
		delay_finished	<= 0;
	end
	else begin
		if (delay > 0) begin
			delay <= delay - 1;
			delay_finished	<= 0;
		end
		else begin
			delay_finished	<= 1;
			if (fp_delay) begin
				$display ("full period wait");
				delay	<= `FULL_PERIOD;
			end
			else if (hp_delay) begin
				$display ("half period wait");
				delay	<= `HALF_PERIOD;
			end
		end
	end
end

endmodule
