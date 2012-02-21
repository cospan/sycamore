//wb_console.v
/*
Distributed under the MIT license.
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

/*
	11/02/2011
		-changed the DRT ID to 6
*/

/*
	Use this to tell sycamore how to populate the Device ROM table
	so that users can interact with your slave

	META DATA

	identification of your device 0 - 65536
	DRT_ID:6

	flags (read drt.txt in the slave/device_rom_table directory 1 means
	a standard device
	DRT_FLAGS:1

	number of registers this should be equal to the nubmer of ADDR_???
	parameters
	DRT_SIZE:3

*/


module wb_console (
	clk,
	rst,

	//Add signals to control your device here

	wbs_we_i,
	wbs_cyc_i,
	wbs_sel_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,

	fb_we_o,
	fb_stb_o,
	fb_cyc_o,
	fb_sel_o,
	fb_adr_o,
	fb_dat_o,
	fb_dat_i,
	fb_ack_i,
	fb_int_i,

	lcd_we_o,
	lcd_stb_o,
	lcd_cyc_o,
	lcd_sel_o,
	lcd_adr_o,
	lcd_dat_o,
	lcd_dat_i,
	lcd_ack_i,
	lcd_int_i

);

input 				clk;
input 				rst;

//wishbone slave signals
input 				wbs_we_i;
input 				wbs_stb_i;
input 				wbs_cyc_i;
input		[3:0]	wbs_sel_i;
input		[31:0]	wbs_adr_i;
input  		[31:0]	wbs_dat_i;
output reg  [31:0]	wbs_dat_o;
output reg			wbs_ack_o;
output reg			wbs_int_o;

//master control signal for memory arbitration
output reg			fb_we_o;
output reg			fb_stb_o;
output reg			fb_cyc_o;
output reg	[3:0]	fb_sel_o;
output reg	[31:0]	fb_adr_o;
output reg	[31:0]	fb_dat_o;
input		[31:0]	fb_dat_i;
input				fb_ack_i;
input				fb_int_i;

//master control signal for lcd arbitration
output reg			lcd_we_o;
output reg			lcd_stb_o;
output reg			lcd_cyc_o;
output reg	[3:0]	lcd_sel_o;
output reg	[31:0]	lcd_adr_o;
output reg	[31:0]	lcd_dat_o;
input		[31:0]	lcd_dat_i;
input				lcd_ack_i;
input				lcd_int_i;



parameter			TIMEOUT				=	32'd10;
//30 times a second
//parameter			TIMEOUT				=	32'd1666666;
//60 times a second
//parameter			TIMEOUT				=	32'd833333;

parameter			ADDR_CONTROL		=	32'h00000000;
parameter			ADDR_TIMEOUT		=	32'h00000001;
parameter			ADDR_UPDATE_RATE	=	32'h00000002;
parameter			ADDR_SCREEN_WIDTH	=	32'h00000003;
parameter			ADDR_SCREEN_HEIGHT	=	32'h00000004;
parameter			ADDR_FONT_ADDRESS	=	32'h00000005;
parameter			ADDR_FRONT			=	32'h00000006;
parameter			ADDR_BACK			=	32'h00000007;


reg			[31:0]	local_data;
reg			[31:0]	timeout;

reg			[31:0]	screen_width;
reg			[31:0]	screen_height;

reg			[31:0]	buffer_pointer;
reg			[31:0]	front;
reg			[31:0]	back;
reg			[31:0]	font_address;

wire		[31:0]	status;

reg					timeout_elapsed;

//flags
reg					console_ready;
reg					enable_console;
reg					enable_timeout;

assign	status[0]	=	console_ready;
assign	status[1]	=	enable_console;
assign 	status[2]	=	enable_timeout;



//blocks
always @ (posedge clk) begin
	enable_console			<= 0;
	if (rst) begin
		wbs_dat_o			<= 32'h0;
		wbs_ack_o			<= 0;
		wbs_int_o			<= 0;

		local_data			<= 32'h00000000;
		console_ready		<= 0;
		timeout				<= TIMEOUT;
		timeout_elapsed			<= 0;

		enable_console		<= 0;
//		enable_timeout		<= 0;
		enable_timeout		<= 1;
		
	end

	else begin
		//when the master acks our ack, then put our ack down
		if (wbs_ack_o & ~ wbs_stb_i)begin
			wbs_ack_o <= 0;
		end

		if (wbs_stb_i & wbs_cyc_i) begin
			//master is requesting somethign
			if (wbs_we_i) begin
				//write request
				case (wbs_adr_i) 
					ADDR_CONTROL: begin
						//writing something to address 0
						//do something
	
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user wrote %h", wbs_dat_i);
						enable_console	<= wbs_dat_i[0];
						enable_timeout	<= wbs_dat_i[1];
						local_data <= wbs_dat_i;
					end
					ADDR_TIMEOUT: begin
						//writing something to address 1
						//do something
	
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user wrote %h", wbs_dat_i);
						timeout			<= wbs_dat_i;
					end
					ADDR_UPDATE_RATE: begin
						//writing something to address 3
						//do something
	
						//NOTE THE FOLLOWING LINE IS AN EXAMPLE
						//	THIS IS WHAT THE USER WILL READ FROM ADDRESS 0
						$display("user wrote %h", wbs_dat_i);
					end
					//add as many ADDR_X you need here
					default: begin
					end
				endcase
			end

			else begin 
				//read request
				case (wbs_adr_i)
					ADDR_CONTROL: begin
						//read the control and status flags
						$display("user read %h", ADDR_CONTROL);
						wbs_dat_o <= status;
					end
					ADDR_TIMEOUT: begin
						//read the timeout value
						$display("user read %h", ADDR_TIMEOUT);
						wbs_dat_o <= timeout;
					end
					ADDR_UPDATE_RATE: begin
						//read the update rate
						$display("user read %h", ADDR_UPDATE_RATE);
						wbs_dat_o <= ADDR_UPDATE_RATE;
					end
					//add as many ADDR_X you need here
					default: begin
					end
				endcase
			end
			wbs_ack_o <= 1;
		end
	end
end


//wishbone master module
always @ (posedge clk) begin
	if (rst) begin
		fb_we_o		<= 0;
		fb_stb_o 	<= 0;
		fb_cyc_o 	<= 0;
		fb_sel_o 	<= 4'h0;
		fb_adr_o	<= 32'h00000000;
		fb_dat_o	<= 32'h00000000;
	end
	else begin
		if (timeout_elapsed) begin
			$display ("write to the memory");
		end
		if (fb_ack_i) begin
			$display ("got an ack!");
			fb_stb_o	<= 0;
			fb_cyc_o	<= 0;
		end
		if (enable_console) begin
			$display("enable a host write! of %h", local_data);
			fb_stb_o <= 1;
			fb_cyc_o <= 1;
			fb_sel_o <= 4'b1111;
			fb_we_o	<= 1;
			fb_adr_o <= 0;
			fb_dat_o <= 32'h0000000F;  
		end
	end
end


//timeout
reg		[31:0]	timeout_count;
always @ (posedge clk) begin
	timeout_elapsed	<= 0;
	if (rst) begin
		timeout_count	<= 32'h00000000;
	end
	else begin
		if (enable_timeout) begin
			if (timeout_count > timeout) begin
				//reached the max, reset everything
				timeout_count 	<= 32'h00000000;
				timeout_elapsed	<= 1;
				$display ("timeout!");
			end
			else begin
				timeout_count <= timeout_count + 1;
			end
		end
		else begin
			timeout_count <= 32'h00000000;
		end
	end
end

endmodule
