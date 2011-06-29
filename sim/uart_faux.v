//faux_uart.v

/**
 * used for testing out the uart_io handler independent of a FPGA
 *
 * HOW TO USE
 *	send a status out
 *		-if rx = 1 then faux_uart will generate a good incomming signal
 *		-if user sends a good output then tx will toggle
 */

module faux_uart(
    input clk, // The master clock for this module
    input rst, // Synchronous reset.
    input rx, // Incoming serial line
    output tx, // Outgoing serial line
    input transmit, // Signal to transmit
    input [7:0] tx_byte, // Byte to transmit
    output received, // Indicated that a byte has been received.
    output [7:0] rx_byte, // Byte received
    output is_receiving, // Low when receive line is idle.
    output is_transmitting, // Low when transmit line is idle.
    output recv_error // Indicates error in receiving packet.
    );

parameter INITIAL_COMMAND		= 32'h00000001;
parameter INITIAL_ADDRESS		= 32'h01234567;
parameter INITIAL_DATA			= 32'h89ABCDEF;

parameter FAUX_UART_DELAY		= 8'h0F;

//input/output signals
input 		clk;
input 		rst;
input 		rx;
output 		tx 					= 0;
input 		transmit;
input 		[7:0] tx_byte;
output reg 	received 			= 0;
output reg 	[7:0] rx_byte		= 8'h0;
output reg 	is_receiving 		= 0;
output reg 	is_transmitting 	= 0;
output reg 	recv_error 			= 0;

parameter 	CHAR_S				= 	8'h53;

//faux data
reg	[31:0]	r_command_in		= INITIAL_COMMAND;
reg [31:0]	r_address_in		= INITIAL_ADDRESS;
reg [31:0] 	r_data_in			= INITIAL_DATA;

//states
parameter	RX_IDLE				= 8'h0;
parameter	RX_SEND_ID			= 8'h1;
parameter	RX_SEND_COMMAND		= 8'h2;
parameter	RX_SEND_ADDRESS		= 8'h3;
parameter	RX_SEND_DATA		= 8'h4;

reg [7:0]	rx_state			= RX_IDLE;

parameter	TX_IDLE					= 8'h0;
parameter	TX_READ_ID				= 8'h1;
parameter	TX_READ_STATUS			= 8'h2;
parameter	TX_READ_ADDRESS			= 8'h3;
parameter	TX_READ_DATA			= 8'h4;


reg [7:0]	tx_state				= TX_IDLE;

//delay counter
reg [7:0]	tx_delay				= 0;
reg			en_tx_delay				= 0;

reg [7:0]	rx_delay				= 0;
reg			en_rx_delay				= 0;

//counter for bytes to receive and send
parameter	RX_TOTAL_BYTE_COUNT		= 8'h8;
reg [7:0]	rx_byte_count			= 0;

parameter 	TX_TOTAL_BYTE_COUNT		= 8'h8;
reg [7:0]	tx_byte_count			= 0;

//BLOCKS


//receive state machine
always @ (posedge clk) begin
	en_rx_delay				<= 0;
	if (rst) begin
		rx_byte				<= 8'0;
		received			<= 0;
		is_receiving		<= 0;
		recv_error			<= 0;
		rx_state			<= RX_IDLE;
	end
	else begin
		//real code
		case (rx_state) begin
			RX_IDLE: begin
			end
			RX_SEND_ID: begin 
			end
			RX_SEND_COMMAND: begin
			end
			RX_SEND_ADDRESS: begin
			end
			RX_SEND_DATA:	begin
			end
			default: begin
				rx_state	<= RX_IDLE;
			end
		endcase
		//check if the simulator is attempting to initiate a receive
		//check if the user is trying to send something
	end
end

//transmit state machine
always @ (posedge clk) begin
	en_tx_delay				<= 0;
	if (rst) begin
		tx 					<= 0;
		is_transmitting		<= 0;
		tx_state			<= TX_IDLE;
	end
	else begin
		//check if the user is trying to send something
		case (tx_state) begin
			TX_IDLE: begin
				if (transmit) begin
					is_transmitting	<=	1;
					tx_state		<=  TX_READ_ID;
					en_tx_delay		<= 	1;
				end;
				else begin
					is_transmitting	<= 0;
				end
			end
			TX_READ_ID: begin
				//send a delay
				if (tx_delay == 0) begin
					is_transmitting <= 0;
					//read the byte from the outgoing byte
					if (tx_byte != CHAR_S) begin
						tx_state		<= TX_IDLE;
					end
					else begin
						//the correct ID character was sent
						tx_state		<= TX_READ_STATUS;
						tx_byte_count	<= TX_TOTAL_BYTE_COUNT;  
					end
				end
			end
			TX_READ_STATUS: begin
				if (tx_byte_count > 0) begin
					if (tx_delay == 0) begin
						//check to see if the user has transmitted a new byte
					end
				end
				else begin
				end

			end
			TX_READ_ADDRESS: begin
			end
			TX_READ_DATA: begin
			end
			default: begin
				tx_state	<= TX_IDLE;
			end
		endcase
	end
end

//timer block
always @ (posedge clk) begin
	if (rst) begin
		tx_delay			<= 0;
		rx_delay			<= 0;
	end

	//count down
	if (rx_delay > 0) begin
		rx_delay = rx_delay - 1;
	end
	if (tx_delay > 0) begin
		tx_delay = tx_delay - 1;
	end
	
	//start a countdown
	if (en_rx_delay && rx_delay == 0) begin
		rx_delay	<= FAUX_UART_DELAY;
	end
	if (en_tx_delay && tx_delay == 0) begin
		tx_delay	<= FAUX_UART_DELAY;
	end
end
endmodule
