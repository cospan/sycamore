//wishbone_master
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

`include "mg_defines.v"

module wishbone_master (
	clk,
	rst,

	//indicate to the input that we are ready
	master_ready,

	//input handler interface
	in_ready,
	in_command,
	in_address,
	in_data,

	//output handler interface
	out_ready,
	out_en,
	out_status,
	out_address,
	out_data,
    out_data_count,

	//wishbone signals
	wb_adr_o,
	wb_dat_o,
	wb_dat_i,
	wb_stb_o,
	wb_cyc_o,
	wb_we_o,
	wb_msk_o,
	wb_sel_o,
	wb_ack_i
	);

	input 				clk;
	input 				rst;

	output reg			master_ready;
	input 				in_ready;
	input [31:0]		in_command;
	input [31:0] 		in_address;
	input [31:0]		in_data;

	input				out_ready;
	output reg			out_en			= 0;
	output reg [31:0]	out_status		= 32'h0;
	output reg [31:0]	out_address		= 32'h0;
	output reg [31:0]	out_data		= 32'h0;
    output reg [27:0]   out_data_count  = 28'h0;
	
	//wishbone
	output reg [31:0]	wb_adr_o;
	output reg [31:0]	wb_dat_o;
	input [31:0]		wb_dat_i;
	output reg 			wb_stb_o;
	output reg			wb_cyc_o;
	output reg			wb_we_o;
	output reg			wb_msk_o;
	output reg [3:0]	wb_sel_o;
	input				wb_ack_i;

	//parameters
//	parameter 			COMMAND_PING		= 32'h00000000;
//	parameter			COMMAND_WRITE		= 32'h00000001;
//	parameter			COMMAND_READ		= 32'h00000002;
//	parameter			COMMAND_WSTREAM_C 	= 32'h00000003;
//	parameter			COMMAND_WSTREAM		= 32'h00000004;
//	parameter			COMMAND_RSTREAM_C	= 32'h00000005;
//	parameter			COMMAND_RSTREAM		= 32'h00000006;
//	parameter			COMMAND_RW_FLAGS	= 32'h00000007;
//	parameter			COMMAND_INTERRUPT	= 32'h00000008;

	parameter 			IDLE				= 32'h00000000;
    parameter           WRITE               = 32'h00000001;
    parameter           READ                = 32'h00000002;
	parameter			STREAM_WRITE_C		= 32'h00000003;
	parameter			STREAM_WRITE		= 32'h00000004;
	parameter			STREAM_READ_C		= 32'h00000005;
	parameter			STREAM_READ			= 32'h00000006;

	parameter			S_PING_RESP			= 32'h00001EAF;
	//private registers

	reg [31:0]			state			= IDLE;
	reg [31:0]			local_command	= 32'h0;
	reg [31:0]			local_address	= 32'h0;
	reg [31:0]			local_data		= 32'h0;

	reg [31:0]			master_flags	= 32'h0;
	reg [31:0]			rw_count		= 32'h0;
    reg                 wait_for_slave  = 0;
	//private wires
	

	//private assigns
/*initial begin
    $monitor("%t, stb: %h", $time, wb_stb_o);
end
*/
	//blocks
	always @ (posedge clk) begin
		
		out_en		<= 0;

//master ready should be used as a flow control, for now its being reset every
//clock cycle, but in the future this should be used to regulate data comming in so that the master can send data to the slaves without overflowing any buffers
		master_ready	<= 1;

		if (rst) begin
			out_status		<= 32'h0;
			out_address 	<= 32'h0;
			out_data		<= 32'h0;
            out_data_count  <= 28'h0;
			local_command	<= 32'h0;
			local_address	<= 32'h0;
			local_data		<= 32'h0;
			master_flags	<= 32'h0;
			master_ready	<= 1;
			rw_count		<= 0;
			state			<= IDLE;

            wait_for_slave  <= 0;

            //wishbone reset
            wb_adr_o        <= 32'h0;
            wb_dat_o        <= 32'h0;
            wb_stb_o        <= 0;
            wb_cyc_o        <= 0;
            wb_we_o         <= 0;
            wb_msk_o        <= 0;
			//select is always on
            wb_sel_o        <= 4'hF;
		end

        else begin 
            if (wb_ack_i) begin
                wb_stb_o <= 0;
                wb_cyc_o <= 0;
            end
            if (in_ready && (state == READ || state == WRITE)) begin
                state   <= IDLE;
            end

            case (state)

            READ: begin
                if (wb_ack_i) begin
                    $display ("GOT AN ACK!!!");
                    wb_stb_o    <= 0;
                    wb_cyc_o    <= 0;
                    wb_we_o     <= 0;
                    out_en      <= 1; 
                    out_data    <= wb_dat_i;
                    state       <= IDLE;
                    end
            end
            WRITE: begin
                if (wb_ack_i) begin
                    wb_stb_o    <= 0;
                    wb_cyc_o    <= 0;
                    wb_we_o     <= 0;
 
                    out_en	   <= 1;
                    state       <= IDLE;
                end
            end
    		STREAM_READ_C: begin
    			if (out_ready) begin
                    //send a request for new data
                    if (wb_stb_o == 0) begin
                        $display ("requesting more data from slave");
                        wb_stb_o    <= 1;
                        wb_cyc_o    <= 1;
                        wb_we_o     <= 0;
                        out_address <= wb_adr_o;
                    end
                    //got a response back
                    else if (wb_ack_i) begin
                        wb_stb_o    <= 0;
                        wb_cyc_o    <= 0;
                        wb_we_o     <= 0;
                        out_data    <= wb_dat_i;
                        rw_count    <= rw_count - 1;
                        out_en      <= 1;
				        rw_count	<= rw_count - 1;
                        wb_adr_o    <= wb_adr_o + 1;
                    end

   					if (rw_count <= 1)begin
	    				state	<= IDLE;
		    		end

			    end
   			end
   			STREAM_READ: begin
    			if (out_ready) begin
                    //send a request for new data
                    if (wb_stb_o == 0) begin
                        wb_stb_o    <= 1;
                        wb_cyc_o    <= 1;
                        wb_we_o     <= 0;
                    end
                    //got a response back
                    else if (wb_ack_i) begin
                        wb_stb_o    <= 0;
                        wb_cyc_o    <= 0;
                        wb_we_o     <= 0;
                        out_data    <= wb_dat_i;
                        rw_count    <= rw_count - 1;
                        out_en      <= 1;
				        rw_count	<= rw_count - 1;

                    end

   					if (rw_count <= 1)begin
	    				state	<= IDLE;
		    		end
			    end
   			end
  		
            default: begin
            end
            endcase 

	    	//handle input
		    if (in_ready) begin
    			local_command	<= in_command;
	    		local_address	<= in_address;
		    	local_data		<= in_data;


			    case(state)
    				IDLE: begin
		    			case (in_command)

			    		`COMMAND_PING: begin
					    	out_status	<= ~in_command;
    						out_address	<= 32'h00000000;
	    					out_data	<= S_PING_RESP;
		    				out_en		<= 1;
			    			state 		<= IDLE;
				    	end
    					`COMMAND_WRITE:	begin
		    				out_status	<= ~in_command;
                            wb_adr_o    <= in_address;
							out_address	<= in_address;
							out_data	<= in_data;
                            wb_stb_o    <= 1;
                            wb_cyc_o    <= 1;
                            wb_we_o     <= 1;
                            wb_dat_o    <= in_data;
    	    				state		<= WRITE;
			    		end
				    	`COMMAND_READ: 	begin
						    out_status	<= ~in_command;
                            wb_adr_o    <= in_address;
							out_address	<= in_address;
                            wb_stb_o    <= 1;
                            wb_cyc_o    <= 1;
                            wb_we_o     <= 0;
    			    		state		<= READ;
					    end
    					`COMMAND_WSTREAM_C: begin
		    				out_status	<= ~in_command;
			    			out_en		<= 1;
				    		master_ready<= 0;
                            wb_adr_o    <= in_address;
    						rw_count	<= in_data;
	    					state		<= STREAM_WRITE_C;
		    			end
			    		`COMMAND_WSTREAM: begin
					    	out_status	<= ~in_command;
						    out_en		<= 1;
                            wb_adr_o    <= in_address;
	    					master_ready	<= 0;
		    				rw_count	<= in_data;
			    			state		<= STREAM_WRITE;
				    	end
					    `COMMAND_RSTREAM_C: begin
	    					out_status	<= ~in_command;
		    				out_en		<= 1;
				    		rw_count	<= in_data;
                            out_data_count  <= in_data;
                            wb_adr_o    <= in_address;
					    	master_ready <= 0;
						    state		<= STREAM_READ_C;
    					end
	    				`COMMAND_RSTREAM: begin
			    			out_status	<= ~in_command;
				    		out_en		<= 1;
					    	master_ready <= 0;
    						rw_count	<= in_data;
                            out_data_count  <= in_data;
	    					state		<= STREAM_READ;
                            wb_adr_o    <= in_address;
		    			end
			    		`COMMAND_RW_FLAGS: begin
					    	out_status	<= ~in_command;
						    out_en		<= 1;
    						state		<= IDLE;
	    				end
		    			`COMMAND_INTERRUPT: begin
				    		out_status	<= ~in_command;
					    	out_en		<= 1;
						    state		<= IDLE;
    					end
    					default: 		begin
	    					state		<= IDLE;
		    		    end
			    	endcase
    		    end
            	STREAM_WRITE_C: begin
	        		if (in_ready) begin
	        			master_ready	<= 0;
						//local data is only used for simulation
			        	//we should be really writing to the address
				        local_data	<= in_data;
   						out_data	<= in_data;
        				rw_count	<= rw_count - 1;
		        		if (rw_count <= 1)begin
				    	state	<= IDLE;
					    out_en	<= 1;
  						end
    				end
	    		end
		    	STREAM_WRITE: begin
			    	if (in_ready) begin
					    master_ready	<= 0;
   						//local data is only used for simulation
    					//we should be really writing to the address
	    				local_data	<= in_data;
		    			out_data	<= in_data;
				    	rw_count	<= rw_count - 1;
						if (rw_count <= 1)begin
        					state	<= IDLE;
		    				out_en	<= 1;
			    		end
				    end
   				end
    	    	default: begin
	    		end
		    endcase
    
            end
	    end
	//handle output
    end

endmodule
