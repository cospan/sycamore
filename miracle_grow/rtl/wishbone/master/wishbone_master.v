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

/*
	11/07/2011
		-added interrupt handling to the master
		-when the master is idle the interconnect will output the interrupt 
			on the wbs data
	10/30/2011
		-fixed the memory bus issue where that master was not responding 
			to a slave ack
		-changed the READ and WRITE command to call either the memory 
			bus depending on the
		flags in the command sent from the user
	10/25/2011
		-added the interrupt input pin for both busses
	10/23/2011
		-commented out the debug message "GOT AN ACK!!", we're passed this
	10/26/2011
		-removed the stream commands, future versions will use flags instead of separate commands
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
	in_data_count,

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
	wb_ack_i,
	wb_int_i,

	//wishbone memory signals
	mem_adr_o,
	mem_dat_o,
	mem_dat_i,
	mem_stb_o,
	mem_cyc_o,
	mem_we_o,
	mem_msk_o,
	mem_sel_o,
	mem_ack_i,
	mem_int_i
	);

	input 				clk;
	input 				rst;

	output reg			master_ready;
	input 				in_ready;
	input [31:0]		in_command;
	input [31:0] 		in_address;
	input [31:0]		in_data;
	input [27:0]		in_data_count;

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
	input				wb_int_i;

	//wishbone memory bus
	output reg [31:0]	mem_adr_o;
	output reg [31:0]	mem_dat_o;
	input [31:0]		mem_dat_i;
	output reg 			mem_stb_o;
	output reg			mem_cyc_o;
	output reg			mem_we_o;
	output reg			mem_msk_o;
	output reg [3:0]	mem_sel_o;
	input				mem_ack_i;
	input				mem_int_i;


	//parameters
	parameter 			IDLE				= 32'h00000000;
    parameter           WRITE               = 32'h00000001;
    parameter           READ                = 32'h00000002;

	parameter			S_PING_RESP			= 32'h00001EAF;
	//private registers

	reg [31:0]			state			= IDLE;
	reg [31:0]			local_command	= 32'h0;
	reg [31:0]			local_address	= 32'h0;
	reg [31:0]			local_data		= 32'h0;

	reg [31:0]			master_flags	= 32'h0;
	reg [31:0]			rw_count		= 32'h0;
    reg                 wait_for_slave  = 0;


	reg					prev_int		= 0;


	reg					interrupt_mask	= 32'h00000000;
	//private wires
	wire [15:0]			command_flags;


	
	reg					mem_bus_select;

	wire [15:0]			real_command;

	//private assigns
	assign command_flags 				= in_command[31:16];
	assign real_command					= in_command[15:0];

initial begin
    //$monitor("%t, int: %h, ih_ready: %h, ack: %h, stb: %h, cyc: %h", $time, wb_int_i, in_ready, wb_ack_i, wb_stb_o, wb_cyc_o);
    //$monitor("%t, cyc: %h, stb: %h, ack: %h, in_ready: %h, out_en: %h, master_ready: %h", $time, wb_cyc_o, wb_stb_o, wb_ack_i, in_ready, out_en, master_ready);
end


//blocks
always @ (posedge clk) begin
		
	out_en		<= 0;

//master ready should be used as a flow control, for now its being reset every
//clock cycle, but in the future this should be used to regulate data comming in so that the master can send data to the slaves without overflowing any buffers
	//master_ready	<= 1;

	if (rst) begin
		out_status		<= 32'h0;
		out_address 	<= 32'h0;
		out_data		<= 32'h0;
		out_data_count  <= 28'h0;
		local_command	<= 32'h0;
		local_address	<= 32'h0;
		local_data		<= 32'h0;
		master_flags	<= 32'h0;
		rw_count		<= 0;
		state			<= IDLE;
		mem_bus_select	<= 0;
		prev_int		<= 0;

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

		//wishbone memory reset
		mem_adr_o        <= 32'h0;
		mem_dat_o        <= 32'h0;
		mem_stb_o        <= 0;
		mem_cyc_o        <= 0;
		mem_we_o         <= 0;
		mem_msk_o        <= 0;

		//select is always on
		mem_sel_o        <= 4'hF;

		//interrupts
		interrupt_mask	<= 32'h00000000;

	end

	else begin 
/*
		if (wb_ack_i) begin
			wb_stb_o <= 0;
//			wb_cyc_o <= 0;
		end
		if (mem_ack_i) begin
			mem_stb_o <= 0;
//			mem_cyc_o <= 0;
		end
*/

//XXX: this may change for burst mode
//		if (in_ready && (state == READ || state == WRITE)) begin
//			state   <= IDLE;
//		end

		case (state)

			READ: begin
				if (mem_bus_select) begin
					if (mem_ack_i) begin
						if (out_data_count == 0) begin
							//finished all the reads, put de-assert the cycle
							mem_cyc_o   <= 0;
							state       <= IDLE;
						end
						else begin
							//finished the next double word
							out_data_count	<= out_data_count -1;
						end
						//put the strobe down to say we got that double word
						mem_stb_o   <= 0;
						mem_we_o    <= 0;
						out_data    <= mem_dat_i;
						//initiate an output transfer
						out_en      <= 1; 
					end
					else begin
						if (out_ready) begin
							//don't start a new transaction until the output is ready
							mem_stb_o	<= 1;
							mem_we_o	<= 0;
						end
					end
				end
				else begin
					if (wb_ack_i) begin
						//just but the strobe down at least until a cycle passes
						wb_stb_o    <= 0;
					end
					else if (~wb_stb_o && out_ready) begin
						$display("WBM: out_data_count = %h", out_data_count);
						if (out_data_count == 0) begin
							$display("WBM: out_data_count == 0");
							//finished all the reads, put de-assert the cycle
							wb_cyc_o    <= 0;
							state       <= IDLE;
						end
						else begin
							out_data_count	<= out_data_count - 1;
						end

						//put the data in the otput
						out_data    <= wb_dat_i;
						//tell the io_handler to send data
						out_en		<= 1;	
						wb_stb_o	<= 1;
					end
				end
			end
			WRITE: begin
				if (mem_bus_select) begin
					if (mem_ack_i) begin
						if (in_data_count == 0) begin
							//finished all writes	
							$display ("WBM: in_data_count == 0");
							mem_cyc_o	<= 0;
							state		<= IDLE;
							out_en		<= 1;
							wb_we_o		<= 0;
						end
						mem_stb_o    <= 0;
						//tell the IO handler were ready for the next one
						master_ready	<=	1;
					end
					else if (in_ready) begin
						$display ("WBM: (burst mode) writing another double word");
						master_ready	<=	0;
						mem_stb_o		<= 1;
						mem_we_o		<= 1;
						mem_adr_o		<= mem_adr_o + 4;
						mem_dat_o		<= in_data;
					end
				end //end working with mem_bus
				else begin //peripheral bus
					if (wb_ack_i) begin
						if (in_data_count == 0) begin
							$display ("WBM: in_data_count == 0");
							wb_cyc_o	<= 0;
							state		<= IDLE;
							out_en		<= 1;
							wb_we_o     <= 0;
						end
            	   	    wb_stb_o    <= 0;
						//tell the IO handler were ready for the next one
						master_ready	<= 1;
					end
					else if (in_ready) begin 
						$display ("WBM: (burst mode) writing another double word");
						master_ready	<=	0;
						wb_stb_o		<= 1;
						wb_we_o			<= 1;
						wb_adr_o		<= wb_adr_o + 1;
						wb_dat_o		<= in_data;
					end
				end
			end
			IDLE: begin
				//handle input
				master_ready	<= 1;
				if (in_ready) begin
					mem_bus_select	<= 0;

					local_address	<= in_address;
					local_data		<= in_data;

					case (real_command)

						`COMMAND_PING: begin
							$display ("WBM: ping");
							out_status			<= ~in_command;
							out_address			<= 32'h00000000;
							out_data			<= S_PING_RESP;
							out_en				<= 1;
							state 				<= IDLE;
						end
						`COMMAND_WRITE:	begin
							out_status	<= ~in_command;
							if (command_flags & `FLAG_MEM_BUS) begin
								mem_bus_select	<= 1;	
								mem_adr_o    	<= in_address;
								mem_stb_o    	<= 1;
								mem_cyc_o    	<= 1;
								mem_we_o     	<= 1;
								mem_dat_o    	<= in_data;
							end
							else begin
								mem_bus_select 	<= 0;
								wb_adr_o    	<= in_address;
								wb_stb_o    	<= 1;
								wb_cyc_o    	<= 1;
								wb_we_o     	<= 1;
								wb_dat_o    	<= in_data;
							end	
							out_address		<= in_address;
							out_data		<= in_data;
							master_ready	<= 0;
							state			<= WRITE;
						end
						`COMMAND_READ: 	begin
							out_data_count		<= in_data_count;
							if (command_flags & `FLAG_MEM_BUS) begin
								mem_bus_select	<= 1;	
								mem_adr_o    	<= in_address;
								mem_stb_o    	<= 1;
								mem_cyc_o    	<= 1;
								mem_we_o     	<= 0;
								out_status		<= ~in_command;
							end
							else begin
								mem_bus_select 	<= 0;
								wb_adr_o    	<= in_address;
								wb_stb_o    	<= 1;
								wb_cyc_o    	<= 1;
								wb_we_o     	<= 0;
								out_status		<= ~in_command;
							end
							master_ready	<= 0;
							out_address		<= in_address;
							state			<= READ;
						end	
						`COMMAND_RW_FLAGS: begin
							out_status		<= ~in_command;
							out_en			<= 1;
							state			<= IDLE;
						end
						`COMMAND_WR_INT_EN: begin
							out_status		<= ~in_command;
							interrupt_mask 	<= in_data;
							out_address		<= 32'h00000000;
							out_data		<= in_data;
							out_en			<= 1;
							state			<= IDLE;
							$display("WBM: setting interrupt enable to: %h", in_data); 
						end
						`COMMAND_RD_INT_EN: begin
							out_status		<= ~in_command;
							out_data		<= interrupt_mask;
							out_address		<= 32'h00000000;
							out_en			<= 1;
							state			<= IDLE;
						end
						default: 		begin
						end
					endcase
				end
				//not handling an input, if there is an interrupt send it to the user
				else if (wb_ack_i == 0 & wb_stb_o == 0 & wb_cyc_o == 0) begin
				    //work around to add a delay
				    wb_adr_o <= local_address;
				    //handle input
				    local_address		<= 32'hFFFFFFFF; 				
					//check if there is an interrupt
					//if the wb_int_i goes positive then send a nortifiaction to the user
					if ((~prev_int) & wb_int_i) begin	
						$display("WBM: found an interrupt!");
						out_status			<= `PERIPH_INTERRUPT;	
						//only supporting interrupts on slave 0 - 31
						out_address			<= 32'h00000000;
						out_data			<= wb_dat_i;
						out_en				<= 1;
					end
					prev_int	<= wb_int_i;
				end
			end
			default: begin
			state <= IDLE;
			end
		endcase
	end
	//handle output
end

endmodule
