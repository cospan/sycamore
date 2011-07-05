module uart_output_handler(
	clk,
	rst,
	byte,
	status,
	address,
	data,
	send_en,
	uart_ready,
	handler_ready,
	uart_byte_en,
	finished,
);

//incomming signals
input clk;
input rst;

input [31:0] status;
input [31:0] address;
input [31:0] data;

input uart_ready;

input send_en;

output reg [7:0] byte;
output reg uart_byte_en;
output handler_ready;
output reg finished;


//STATEs
parameter STATE_IDLE			= 	8'h0;
parameter STATE_WRITE_STATUS	= 	8'h1;
parameter STATE_WRITE_ADDRESS	= 	8'h2;
parameter STATE_WRITE_DATA		= 	8'h3;

parameter CHAR_S				= 	8'h53;
parameter CHAR_0				= 	8'h30;
parameter CHAR_HEX_OFFSET		=	8'h37;

//Registers
reg[7:0]	r_STATE				= 	STATE_IDLE;

reg[3:0]	r_nibble_count		= 	4'h0;

reg r_data_ready				= 	0;
reg r_uart_wait					=	0;

reg	[31:0]	r_status			=	0;
reg [31:0]	r_address			=	0;
reg [31:0]	r_data				=	0;

//Wire
wire pos_edge_data_ready;

//Assign
assign pos_edge_data_ready	= 	(ready & ~r_data_ready);
//handler is only ready when STATE is STATE_IDLE and uart is ready
assign handler_ready		= 	((r_STATE == STATE_IDLE) & (uart_ready == 1));


//Synchronous
always @ (posedge clk) begin
	r_data_ready <= ready;
end


always @ (posedge clk) begin

	//uart_byte_en should only be high for one clock cycle

	finished	<= 0;

	if (rst) begin
		r_STATE			<=	STATE_IDLE;
		r_nibble_count	<=	4'h0;
		byte			<= 	8'h0;
		uart_byte_en 	<= 	0;
	end

	else begin
		//don't do anything until the UART is ready
		if (uart_ready) begin
			case (r_STATE)
				STATE_IDLE: begin
					byte			<= 	8'h0;
					r_nibble_count	<=	4'h0;
					if (send_en) begin
						r_status		<= status;
						r_address		<= address;
						r_data			<= data;
						byte			<= 	CHAR_S;	
						r_STATE			<=	STATE_WRITE_STATUS; 
						uart_byte_en	<= 1;
					end 
				end
				STATE_WRITE_STATUS: begin
					//shift the data into the output byte one at a time
					if (r_status[31:28] < 10)begin
						//send character number
						byte 	<= r_status[31:28] + CHAR_0;
					end
					else begin
						//send  character hex value
						byte 	<= r_status[31:28] + CHAR_HEX_OFFSET;
					end
					r_status 				<= {r_status[28:0], 4'h0};
					uart_byte_en			<= 1;
					r_nibble_count			<= r_nibble_count + 1;

					if (r_nibble_count >= 7) begin
						r_STATE			<= STATE_WRITE_ADDRESS;
						r_nibble_count	<= 4'h0;
					end

				end
				STATE_WRITE_ADDRESS: begin
					//shift the data into the output byte one at a time
					if (r_address[31:28] < 10)begin
						//send character number
						byte 	<= r_address[31:28] + CHAR_0;
					end
					else begin
						//send character hex value
						byte 	<= r_address[31:28] + CHAR_HEX_OFFSET;
					end

					r_address 			<= {r_address[28:0], 4'h0};
					uart_byte_en		<= 1;
					r_nibble_count		<= r_nibble_count + 1;

					if (r_nibble_count >= 7) begin
						r_STATE			<= STATE_WRITE_DATA;
						r_nibble_count	<= 4'h0;
					end

				end
				STATE_WRITE_DATA: begin
					//shift the data into the output byte one at a time
					if (r_data[31:28] < 10)begin
						//send character number
						byte 	<= r_data[31:28] + CHAR_0;
					end
					else begin
						//send  character hex value
						byte 	<= r_data[31:28] + CHAR_HEX_OFFSET;
					end

					r_data 				<= {r_data[28:0], 4'h0};
					uart_byte_en		<= 1;
					r_nibble_count		<= r_nibble_count + 1;

					if (r_nibble_count >= 7) begin
						finished		<= 1;
						r_STATE			<= STATE_IDLE;
						r_nibble_count	<= 4'h0;
					end

				end
				default: begin
					r_STATE	<=	STATE_IDLE;
			end
		endcase
		end
		else begin
			uart_byte_en			<= 0;
		end
	end
	
end

endmodule
