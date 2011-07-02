//faux_uart.v

/**
 * used for testing out the uart_io handler independent of a FPGA
 *
 * HOW TO USE
 * reads charaters from a input characters and sens them to the io handler
 */

module faux_uart(
    clk, 					// The master clock for this module
    rst, 					// Synchronous reset.
    rx_en, 					// Incoming serial line
	sim_in_byte				// simulation input byte
    tx_ready, 				// Outgoing serial line
	sim_out_byte,			// simulation output byte
    transmit, 				// Signal to transmit
    tx_byte, 				// Byte to transmit
    received,				// Indicated that a byte has been received.
    rx_byte, 				// Byte received
    is_receiving, 			// Low when receive line is idle.
    is_transmitting,		// Low when transmit line is idle.
    recv_error,				// Indicates error in receiving packet.
    );

input clk;
input rst;
input rx_en;
input [7:0]sim_in_byte;
output reg [7:0]sim_out_byte;
output reg tx_ready;
input transmit;
input [7:0] tx_byte;
output reg received;
output reg [7:0] rx_byte;
output reg is_receiving;
output reg is_transmitting;
output reg recv_error;

parameter INITIAL_COMMAND		= 32'h00000001;
parameter INITIAL_ADDRESS		= 32'h01234567;
parameter INITIAL_DATA			= 32'h89ABCDEF;

parameter CHAR_0 				= 8'h30;
parameter CHAR_L 				= 8'h4C;
parameter CHAR_HEX_OFFSET 		= 8'h37;
parameter CHAR_A				= 8'h41;
parameter CHAR_F				= 8'h46;

parameter FAUX_UART_DELAY		= 8'h0F;

//input/output signals
parameter 	CHAR_S					= 	8'h53;

//faux data
reg	[31:0]	r_command_in			= INITIAL_COMMAND;
reg [31:0]	r_address_in			= INITIAL_ADDRESS;
reg [31:0] 	r_data_in				= INITIAL_DATA;

//states
parameter	RX_IDLE					= 8'h0;
parameter	RX_SEND_ID				= 8'h1;
parameter	RX_SEND_COMMAND			= 8'h2;
parameter	RX_SEND_ADDRESS			= 8'h3;
parameter	RX_SEND_DATA			= 8'h4;

reg [7:0]	rx_state				= RX_IDLE;

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
	received				<= 0;
	if (rst) begin
		rx_byte				<= 8'h0;
		is_receiving		<= 0;
		recv_error			<= 0;
		rx_state			<= RX_IDLE;
	end
	else begin
		//real code
		case (rx_state)
			RX_IDLE: begin
				r_command_in			<= INITIAL_COMMAND;
				r_address_in			<= INITIAL_ADDRESS;
				r_data_in				<= INITIAL_DATA;
				if (rx_en) begin
					rx_byte				<= sim_in_bye;
					rx_state			<= RX_SEND_ID;
					is_receiving		<= 1;
				end
			end
			RX_SEND_ID: begin 
				rx_byte_count		<= RX_TOTAL_BYTE_COUNT;
				received			<= 1;
				rx_state			<= RX_SEND_COMMAND;
			end
			RX_SEND_COMMAND: begin
				if (rx_byte_count > 0) begin
					if (rx_en) begin
						received		<= 1;
						rx_byte			<= sim_in_byte;
						rx_byte_count 	<= rx_byte_count - 1;
					end
				end
				else begin
					received			<= 1;
					rx_byte_count		<= RX_TOTAL_BYTE_COUNT;
					rx_state			<= RX_SEND_ADDRESS;
				end
			end
			RX_SEND_ADDRESS: begin
				if (rx_byte_count > 0) begin
					if (rx_en) begin
						received		<= 1;
						rx_byte			<= sim_in_byte;
						rx_byte_count 	<= rx_byte_count - 1;
					end
				end
				else begin
					received			<= 1;
					rx_byte_count		<= RX_TOTAL_BYTE_COUNT;
					rx_state			<= RX_SEND_DATA;
				end
			end
			RX_SEND_DATA:	begin
				if (rx_byte_count > 0) begin
					if (rx_en) begin
						received		<= 1;
						rx_byte			<= sim_in_byte;
						rx_byte_count 	<= rx_byte_count - 1;
					end
				end
				else begin
					received			<= 1;
					rx_byte_count		<= RX_TOTAL_BYTE_COUNT;
					rx_state			<= RX_IDLE;
				end
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
	tx						<= 0;
	if (rst) begin
		tx 					<= 0;
		is_transmitting		<= 0;
		tx_state			<= TX_IDLE;
	end
	else begin
		//check if the user is trying to send something
		case (tx_state)
			TX_IDLE: begin
				if (transmit) begin
					is_transmitting	<=	1;
					tx_state		<=  TX_READ_ID;
					en_tx_delay		<= 	1;
				end
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
						if (transmit) begin
							//user transmitted new byte
							tx_byte_count 	<= tx_byte_count - 1;
							//verify the byte is in the correct format
//if the character is not a HEX number than quit
							if ((tx_byte < CHAR_0) || (tx_byte > (CHAR_0 + 10) && tx_byte < CHAR_A) || tx_byte > CHAR_F)begin
								//out of range
								tx_state <= TX_IDLE;
								tx_byte_count <= 0;
							end
							else begin
								en_tx_delay		<=	1;
							end
						end
					end
				end
				//finished with the 8 bytes
				else begin
					tx_byte_count	<= TX_TOTAL_BYTE_COUNT;  
					tx_state 		<= TX_READ_ADDRESS;
				end
			end
			TX_READ_ADDRESS: begin
				if (tx_byte_count > 0) begin
					if (tx_delay == 0) begin
						//check to see if the user has transmitted a new byte
						if (transmit) begin
							//user transmitted new byte
							tx_byte_count 	<= tx_byte_count - 1;
							//verify the byte is in the correct format
//if the character is not a HEX number than quit
							if ((tx_byte < CHAR_0) || (tx_byte > (CHAR_0 + 10) && tx_byte < CHAR_A) || tx_byte > CHAR_F)begin
								//out of range
								tx_state <= TX_IDLE;
								tx_byte_count <= 0;
							end
							else begin
								en_tx_delay		<=	1;
							end
						end
					end
				end
				//finished with the 8 bytes
				else begin
					tx_byte_count	<= TX_TOTAL_BYTE_COUNT;  
					tx_state 		<= TX_READ_DATA;
				end

			end
			TX_READ_DATA: begin
				if (tx_byte_count > 0) begin
					if (tx_delay == 0) begin
						//check to see if the user has transmitted a new byte
						if (transmit) begin
							//user transmitted new byte
							tx_byte_count 	<= tx_byte_count - 1;
							//verify the byte is in the correct format
//if the character is not a HEX number than quit
							if ((tx_byte < CHAR_0) || (tx_byte > (CHAR_0 + 10) && tx_byte < CHAR_A) || tx_byte > CHAR_F)begin
								//out of range
								tx_state <= TX_IDLE;
								tx_byte_count <= 0;
							end
							else begin
								en_tx_delay		<=	1;
							end
						end
					end
				end
				//finished with the 8 bytes
				else begin
					tx_byte_count	<= TX_TOTAL_BYTE_COUNT;  
					tx_state 		<= TX_IDLE;
					tx				<= 1;
				end

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
