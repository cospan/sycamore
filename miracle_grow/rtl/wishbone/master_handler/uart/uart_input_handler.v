//uart_input_handler.v
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


module uart_input_handler(
    clk,
    rst,
    byte_available,
    byte,
    command,
	address,
    data,
    ready,
    data_count,
);

//incomming signals
input clk;
input rst;
input byte_available;
input [7:0]byte;

//outgoing control
output reg [31:0] command;
output reg [31:0] address;
output reg [31:0] data;
output reg ready;
output reg [27:0]  data_count;

//STATES
parameter IDLE             = 8'h0;
parameter READ_ID          = 8'h1;
parameter READ_DATA_COUNT  = 8'h2;
parameter READ_CONTROL     = 8'h3;
parameter READ_ADDRESS   	 = 8'h4;
parameter READ_DATA        = 8'h5;

parameter CHAR_L 				= 8'h4C;

parameter CHAR_0 				= 8'h30;
parameter CHAR_HEX_OFFSET 		= 8'h37;
parameter CHAR_A				= 8'h41;
parameter CHAR_F				= 8'h46;

//Registers
reg [7:0]  state;

//reg r_low_byte          	= 0;
reg [3:0] nibble_count;
reg [15:0] r_count;


reg send_first_data;
//Wire

//Assign

//Synchronous
always @ (posedge clk) begin

	ready	<= 0;
    if (rst) begin
        command     	<= 32'h0000;
		address			<= 32'h0000;
		data			<= 32'h0000;
        state     	    <= IDLE;
		nibble_count	<= 4'h0;
        //r_low_byte    <= 0;
		ready		    <= 0;
        data_count      <= 24'h0;
        send_first_data <= 0;
    end
    else begin
        //main state machine goes here
        case (state)
            IDLE: begin
				ready			<= 0;
                if (byte_available) begin
                    state     <= READ_ID;
                end
            end
            READ_ID: begin
                //$display ("read id");
                //putting this here lets master hold onto the data for
                //a longer time
                command			<= 32'h0000;
				address			<= 32'h0000;
				data			<= 32'h0000;
                data_count      <= 24'h000;
                send_first_data <= 1;
                if (byte == CHAR_L) begin
                    //read the first of byte
                    state     	<= READ_DATA_COUNT;
					nibble_count	<= 4'h0;
                end
                else begin
                    state 		<= IDLE;
                end
			end

            READ_DATA_COUNT: begin
                if (byte_available) begin
                    if ((byte < CHAR_0) ||
                        (( byte > CHAR_0 + 10) && (byte < CHAR_A)) ||
                        (byte > CHAR_F)) begin
                        //invalid character go back to READ_ID
                        state     <= READ_ID;
                    end
                    else begin
                        //valid character
                        if (byte >= CHAR_A) begin
                            //A - F
                            data_count  <= {data_count[19:0], byte - CHAR_0}; 
                        end
                        else begin
                            data_count  <= {data_count[19:0], byte - CHAR_0};
                        end
                        if (nibble_count >= 6) begin
                            nibble_count    <= 4'h0;
                            state   <= READ_CONTROL;
                        end
                        else begin
                            nibble_count <= nibble_count + 1;
                        end
                    end
                end
                
				//nibble_count	<= 4'h0;
            end
            READ_CONTROL: begin
                if (byte_available) begin
                    if ((byte < CHAR_0) || 
						((byte > CHAR_0 + 10) && (byte < CHAR_A)) || 
						(byte > CHAR_F)) begin
						/*
						something went wront reset... this code could be put
						outside all of the states, but within the state its
						easier to understand the code
						*/
                        state    <=    READ_ID;
                    end
                    else begin
					/*
						read a byte, increment the count and put data into the
						command register MSB first
						*/
						if (byte >= CHAR_A) begin
							//A - F value
							command 		<= (command[31:0] << 4) + (byte - CHAR_HEX_OFFSET);
						end
						else begin
							//0-9 value
							command 		<= (command[31:0] << 4) + (byte - CHAR_0);
						end
						nibble_count 	<= nibble_count + 1;	

						if (nibble_count >= 7) begin
							state			<= READ_ADDRESS;
							nibble_count 	<= 4'h0;
						end
	
                    end
                end
            end
            READ_ADDRESS: begin
                //read the size
                if (byte_available) begin

                    if ((byte < CHAR_0) || 
						((byte > CHAR_0 + 10) && (byte < CHAR_A)) || 
						(byte > CHAR_F)) begin
						/*
						something went wront reset... this code could be put
						outside all of the states, but within the state its
						easier to understand the code
						*/
                        state    <=    READ_ID;
                    end
                    else begin
						if (byte >= CHAR_A) begin
							//A - F value
							address 		<= (address[31:0] << 4) + (byte - CHAR_HEX_OFFSET);
						end
						else begin
							//0-9 value
							address 		<= (address[31:0] << 4) + (byte - CHAR_0);
						end
				
						nibble_count 	<= nibble_count + 1;
					
						if (nibble_count >= 7) begin
							state			<= READ_DATA;
							nibble_count 	<= 4'h0;
						end
                    end                
                end
            end
            READ_DATA : begin
                if (byte_available) begin

					if ((byte < CHAR_0) || 
						((byte > CHAR_0 + 10) && (byte < CHAR_A)) || 
						(byte > CHAR_F)) begin
						/*
						something went wront reset... this code could be put
						outside all of the states, but within the state its
						easier to understand the code
						*/
                        state    <=    READ_ID;
                    end
                    else begin
						if (byte >= CHAR_A) begin
							//A - F value
							data 		<= (data[31:0] << 4 | (byte - CHAR_HEX_OFFSET));
						end
						else begin
							//0-9 value
							data 		<= (data[31:0] << 4 |  (byte - CHAR_0));
						end

						if (nibble_count >= 7) begin
                            if (data_count > 0) begin
                                data_count = data_count - 1;
                            end
                            else begin
							    state			<= IDLE;
                            end
                            nibble_count        <= 4'h0;
                            ready               <= 1;
						end
                        else begin
						    nibble_count	<= nibble_count + 1;
                        end
                    end
                end
            end
            default: begin
                command         <= 8'h0;
                state         <= IDLE;
            end
        endcase
    end
end
endmodule
