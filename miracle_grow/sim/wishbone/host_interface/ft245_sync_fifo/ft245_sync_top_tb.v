//uart_top_tb.v
/*
Distributed under the MIT licesnse.
Copyright (c) 2011 Dave McCoy (dave.mccoy@cospandesign.com)

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

`timescale 1ns/1ps

`include "project_defines.v"

module ft245_sync_top_tb; 


	reg 			clk			=	0;
	reg 			rst			=	0;

	wire 	[7:0]	data;
	reg 	[7:0] 	in_data;
	reg				txe_n;
	wire			wr_n;
	reg				rde_n;
	wire			rd_n;
	wire			oe_n;
	wire			siwu;

	reg				ftdi_clk	=	0;

	reg		[31:0]	host_data_in;
	reg				host_rd;
	wire			host_empty;

	wire	[31:0]	host_data_out;
	reg				host_wr;
	wire			host_full;


	assign	data	= (oe_n) ? 8'hZ:in_data;

	
	//instantiate the uart
	ft245_sync_fifo sync_fifo(
		.rst(rst),
		.ftdi_clk(ftdi_clk),
		.ftdi_data(data),
		.ftdi_txe_n(txe_n),
		.ftdi_wr_n(wr_n),
		.ftdi_rde_n(rde_n),
		.ftdi_rd_n(rd_n),
		.ftdi_oe_n(oe_n),
		.ftdi_siwu(siwu),

		.hi_clk(clk),
		.hi_data_in(host_data_in),
		.hi_rd(host_rd),
		.hi_empty(host_empty),
		
		.hi_data_out(host_data_out),
		.hi_wr(host_wr),
		.hi_full(host_full)
	);


integer ch;
integer fd_in;
integer fd_out;


reg		ftdi_new_data_available;
reg		ftdi_ready_to_read;


//make the ftdi clock 3X faster than the regular clock
always #1		ftdi_clk	= ~ftdi_clk;

always #3		clk			= ~clk;



reg	[15:0]	number_to_write;
//virtual FTDI variables
reg	[3:0]	ftdi_state;
reg	[3:0]	temp_state; //weird behavior in the while loops, need something to do in them


parameter FTDI_IDLE					=	4'h0;
parameter FTDI_RX_ENABLE_OUTPUT		=	4'h1;
parameter FTDI_RX_WRITING			=	4'h2;
parameter FTDI_RX_STOP				=	4'h3;
parameter FTDI_TX_READING			=	4'h4;
parameter FTDI_TX_READING_FULL		=	4'h5;
parameter FTDI_TX_READING_FINISHED	=	4'h6;


initial begin

	ch 		= 0;
	$dumpfile ("design.vcd");
	$dumpvars (0, ft245_sync_top_tb);
	fd_in = $fopen ("fsync_input_data.txt", "r");

	#10
	rst						<= 1;
	ftdi_new_data_available <= 0;
	ftdi_ready_to_read		<= 0;
	number_to_write			<= 0;
	#10
	rst 					<= 0;
	#10

	//testing input
	if (fd_in == 0) begin
		$display("fsync_input_data.txt was not found");
	end	
	else begin
		$display("Excercising a write");
		ftdi_new_data_available <= 1;

		number_to_write			<= 1;
		while (ftdi_state != FTDI_TX_READING_FINISHED) begin
			#2
			temp_state	<= ftdi_state;
		end

		ftdi_new_data_available	<= 0;

		$display ("wating for state machine to return to IDLE");
		while (ftdi_state != FTDI_IDLE) begin
			#2
			temp_state	<= ftdi_state;
		end

		$display("Excercising a read");
		ftdi_ready_to_read		<= 1;

		while (ftdi_state	!=	FTDI_RX_STOP) begin
			#2
			temp_state	<= ftdi_state;
		end
		ftdi_ready_to_read		<= 0;

		$display ("wating for state machine to return to IDLE");
		while (ftdi_state != FTDI_IDLE) begin
			#2
			temp_state	<= ftdi_state;
		end
	end

	$display ("Finished tests");
	#10000
	$finish;
end

parameter	FTDI_BUFFER_SIZE		= 512;

reg [15:0]	ftdi_write_count;
reg [15:0]	ftdi_read_count;

//virtual FTDI chip
always @ (posedge ftdi_clk) begin
	if (rst) begin
		txe_n				<=	1;
		rde_n				<=	1;
		ftdi_state			<=	FTDI_IDLE;
		ftdi_write_count	<=	0;
		ftdi_read_count		<=	0;
	end
	else begin
		//not in reset
		case (ftdi_state)
			FTDI_IDLE: begin
				//no command from the test bench
//I should allow the write count not to reset when the user isn't finished reading and prematurely quits a read sequence
				ftdi_write_count	<= 0;
				ftdi_read_count		<= 0;

				//check ifthe 'initial' wants to receive
				rde_n	<= ~ftdi_ready_to_read;

				//check if the 'initial' wants to transmit
				txe_n	<= ~ftdi_new_data_available;	
				
				//read always gets priority
				if (~rde_n & ~oe_n) begin
					$display("rde_n and oe_n LOW, wait for rd_n to go LOW");
					ftdi_state	<=	FTDI_RX_ENABLE_OUTPUT;
					ftdi_write_count	<= number_to_write;
				end
				else if (~txe_n & ~wr_n) begin
					$display("txe_n and wr_n LOW, starting reading data from the core");
					ftdi_state	<=	FTDI_TX_READING;
				end

			end
			FTDI_RX_ENABLE_OUTPUT: begin
				$display ("waiting for rd_n to go low");
				//enable is high, now wait for the read to go low
				if (~rd_n) begin
					$display("rd_n LOW, start writing data to the core");
					ftdi_state	<= FTDI_RX_WRITING;					
				end
			end
			FTDI_RX_WRITING: begin
				$display ("sending %d data", ftdi_write_count);
				if (rd_n || oe_n) begin
					ftdi_state	<= FTDI_RX_STOP;
					rde_n		<= 1;
				end
				if (ftdi_write_count > 0) begin
					ftdi_write_count <= ftdi_write_count - 1;
				end
				//can't wait an entire clock cycle to see if we have reached the max count
				else begin
					$display("Sent last byte, telling the core that I've sent all my data");
					ftdi_state	<= FTDI_RX_STOP;
					rde_n		<= 1;
				end
				in_data		<= ftdi_write_count[7:0];
//setup a tristate buffer to send the data
			end
			FTDI_RX_STOP:	begin
				$display ("Wating for core to acknowledge my stop");
				//the core signaled that it is finished transmitting
				if (oe_n & rd_n) begin
					$display ("Core acknowledged my empty, going to IDLE");
					ftdi_state	<= FTDI_IDLE;
				end
			end
			FTDI_TX_READING:	begin
				//reading data from the core
				//$display ("read %02X from the core", data);
				if (wr_n) begin
					$display ("Core has terminated write before buffer is full");
					ftdi_state	<= FTDI_TX_READING_FINISHED;
					txe_n		<= 1;
				end
				if (ftdi_read_count == FTDI_BUFFER_SIZE -1 ) begin
					$display ("FTDI TX buffer full, read %d times", ftdi_read_count);
					txe_n		<= 1;
					ftdi_state	<= FTDI_TX_READING_FINISHED;
				end
				ftdi_read_count	<=	ftdi_read_count + 1;
			end
			FTDI_TX_READING_FINISHED:	begin
				//the core has signaled a finished read cycle
//wait for a dip in the SIWU signal
				$display ("wating for the core to ack my reading is finished");
				if (wr_n) begin
					$display ("Finished a TX read from the core");
					ftdi_state	<= FTDI_IDLE;
				end
			end
			default:					begin
				ftdi_state	<= FTDI_IDLE;
			end
		endcase
	end
end


//host_interface
always @ (posedge clk) begin
	if (rst) begin
		host_data_in	<= 32'h0;
		host_rd			<= 0;
		
		host_wr			<= 0;
	end
	else begin
		//not in reset
	end
end

endmodule
