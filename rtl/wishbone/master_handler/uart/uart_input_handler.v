module uart_input_handler(
    clk,
    rst,
    byte_available,
    byte,
    command,
	address,
    data,
    ready,
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

//STATES
parameter STATE_IDLE             = 8'h0;
parameter STATE_READ_ID  		 = 8'h1;
parameter STATE_READ_CONTROL     = 8'h2;
parameter STATE_READ_ADDRESS   	 = 8'h3;
parameter STATE_READ_DATA        = 8'h4;

parameter CHAR_L 				= 8'h4C;

parameter CHAR_0 				= 8'h30;
parameter CHAR_HEX_OFFSET 		= 8'h37;
parameter CHAR_A				= 8'h41;
parameter CHAR_F				= 8'h46;

//Registers
reg [7:0]  r_STATE    		= 'b0;

//reg r_low_byte          	= 0;
reg [3:0] r_nibble_count	= 4'h0;
reg [15:0] r_count      	= 0;

reg r_prev_byte_available = 0;


//Wire
wire pos_edge_byte_available;

//Assign
assign pos_edge_byte_available = (byte_available & ~r_prev_byte_available);

//Synchronous
always @ (posedge clk) begin
    r_prev_byte_available <= byte_available;
end

always @ (posedge clk) begin

	ready	<= 0;
    if (rst) begin
        command     	<= 32'h0000;
		address			<= 32'h0000;
		data			<= 32'h0000;
        r_STATE     	<= STATE_IDLE;
		r_nibble_count	<= 4'h0;
        //r_low_byte  <= 0;
		ready		<= 0;

    end
    else begin
        //main state machine goes here
        case (r_STATE)
            STATE_IDLE: begin
				command			<= 32'h0000;
				address			<= 32'h0000;
				data			<= 32'h0000;
				r_nibble_count	<= 4'h0;
				ready			<= 0;
                if (pos_edge_byte_available) begin
                    r_STATE     <= STATE_READ_ID;
                end
            end
            STATE_READ_ID: begin
                if (byte == CHAR_L) begin
                    //read the first of byte
                    r_STATE     	<= STATE_READ_CONTROL;
					r_nibble_count	<= 4'h0;
                end
                else begin
                    r_STATE 		<= STATE_IDLE;
                end
			end
            STATE_READ_CONTROL: begin
                
                if (pos_edge_byte_available) begin
                    if ((byte < CHAR_0) || 
						((byte > CHAR_0 + 10) && (byte < CHAR_A)) || 
						(byte > CHAR_F)) begin
						/*
						something went wront reset... this code could be put
						outside all of the states, but within the state its
						easier to understand the code
						*/
                        r_STATE    <=    STATE_READ_ID;
                    end
                    else begin
					/*
						read a byte, increment the count and put data into the
						command register MSB first
						*/
						if (byte >= CHAR_A && byte <= CHAR_F) begin
							//A - F value
							command 		<= (command[31:0] << 4) + (byte - CHAR_HEX_OFFSET);
						end
						else begin
							//0-9 value
							command 		<= (command[31:0] << 4) + (byte - CHAR_0);
						end
						r_nibble_count 	<= r_nibble_count + 1;	

						if (r_nibble_count >= 7) begin
							r_STATE			<= STATE_READ_ADDRESS;
							r_nibble_count 	<= 4'h0;
						end
	
                    end
                end
            end
            STATE_READ_ADDRESS: begin
                //read the size
                if (pos_edge_byte_available) begin
                    if ((byte < CHAR_0) || 
						((byte > CHAR_0 + 10) && (byte < CHAR_A)) || 
						(byte > CHAR_F)) begin
						/*
						something went wront reset... this code could be put
						outside all of the states, but within the state its
						easier to understand the code
						*/
                        r_STATE    <=    STATE_READ_ID;
                    end
                    else begin
						if (byte >= CHAR_A && byte <= CHAR_F) begin
							//A - F value
							address 		<= (address[31:0] << 4) + (byte - CHAR_HEX_OFFSET);
						end
						else begin
							//0-9 value
							address 		<= (address[31:0] << 4) + (byte - CHAR_0);
						end
				
						r_nibble_count 	<= r_nibble_count + 1;
					
						if (r_nibble_count >= 7) begin
							r_STATE			<= STATE_READ_DATA;
							r_nibble_count 	<= 4'h0;
						end
                    end                
                end
            end
            STATE_READ_DATA : begin
                if (pos_edge_byte_available) begin
					if ((byte < CHAR_0) || 
						((byte > CHAR_0 + 10) && (byte < CHAR_A)) || 
						(byte > CHAR_F)) begin
						/*
						something went wront reset... this code could be put
						outside all of the states, but within the state its
						easier to understand the code
						*/
                        r_STATE    <=    STATE_READ_ID;
                    end
                    else begin
						if (byte >= CHAR_A && byte <= CHAR_F) begin
							//A - F value
							data 		<= (data[31:0] << 4) + (byte - CHAR_HEX_OFFSET);
						end
						else begin
							//0-9 value
							data 		<= (data[31:0] << 4) + (byte - CHAR_0);
						end

						r_nibble_count	<= r_nibble_count + 1;

						if (r_nibble_count >= 7) begin
							r_STATE			<= STATE_IDLE;
							r_nibble_count	<= 4'h0;
							ready			<= 1;

						end
                    end
                end
            end
            default: begin
                command         <= 8'h0;
                r_STATE         <= STATE_IDLE;
            end
        endcase
        
    end
end
endmodule
