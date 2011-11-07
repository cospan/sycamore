//wb_gpio.v
/*
Distributed under the MIT license.
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
	10/29/2011
		-added an 'else' statement that so either the
		reset HDL will be executed or the actual code
		not both
*/

/*
	10/23/2011
		-fixed the wbs_ack_i to wbs_ack_o
		-added the default entries for read and write
			to illustrate the method of communication
		-added license
*/
/*
	9/10/2011
		-removed the duplicate wbs_dat_i
		-added the wbs_sel_i port
*/

/*
	Use this to tell sycamore how to populate the Device ROM table
	so that users can interact with your slave

	META DATA

	identification of your device 0 - 65536
	DRT_ID:  1

	flags (read drt.txt in the slave/device_rom_table directory 1 means
	a standard device
	DRT_FLAGS:  1

	number of registers this should be equal to the nubmer of ADDR_???
	parameters
	DRT_SIZE:  5

*/


module wb_gpio (
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

	gpio_in,
	gpio_out
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


//gpio
input		[31:0]	gpio_in;
output reg	[31:0]	gpio_out;


parameter			ADDR_GPIO			=	32'h00000000;
parameter			ADDR_GPIO_MASK		=	32'h00000001;
parameter			ADDR_INTERRUPTS		=	32'h00000002;
parameter			ADDR_INTERRUPT_EN	=	32'h00000003;
parameter			ADDR_INTERRUPT_EDGE =	32'h00000004;


//gpio registers
reg			[31:0]	gpio_mask;

//interrupt registers
reg			[31:0]	interrupts;
reg			[31:0]	interrupt_mask;
reg			[31:0]	interrupt_edge;
reg					clear_interrupts;

//blocks
always @ (posedge clk) begin

	clear_interrupts 	<= 0;

	if (rst) begin
		wbs_dat_o	<= 32'h00000000;
		wbs_ack_o	<= 0;

		//reset gpio's
		gpio_out			<= 32'h00000000;
		gpio_mask			<= 32'h00000000;


		//reset interrupts
		interrupt_mask		<= 32'h00000000;
		interrupt_edge		<= 32'h00000000;
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
					ADDR_GPIO: begin
						$display("user wrote %h", wbs_dat_i);
						gpio_out	<= wbs_dat_i & gpio_mask;
					end
					ADDR_GPIO_MASK: begin
						$display("%h ->gpio_mask", wbs_dat_i);
						gpio_mask	<= wbs_dat_i;
					end
					ADDR_INTERRUPTS: begin
						$display("trying to write %h to interrupts?!", wbs_dat_i);
						//can't write to the interrupt
					end
					ADDR_INTERRUPT_EN: begin
						$display("%h -> interrupt enable", wbs_dat_i);
						interrupt_mask	<= wbs_dat_i;
					end
					ADDR_INTERRUPT_EDGE: begin
						$display("%h -> interrupt_edge", wbs_dat_i);
						interrupt_edge	<= wbs_dat_i;
					end
					default: begin
					end
				endcase
			end

			else begin 
				//read request
				case (wbs_adr_i)
					ADDR_GPIO: begin
						$display("user read %h", wbs_adr_i);
						wbs_dat_o <= gpio_in;
					end
					ADDR_GPIO_MASK: begin
						$display("user read %h", wbs_adr_i);
						wbs_dat_o <= gpio_mask;
					end
					ADDR_INTERRUPTS: begin
						$display("user read %h", wbs_adr_i);
						wbs_dat_o 			<= interrupts;
						clear_interrupts	<= 1;
					end
					ADDR_INTERRUPT_EN: begin
						$display("user read %h", wbs_adr_i);
						wbs_dat_o			<= interrupt_mask;
					end
					ADDR_INTERRUPT_EDGE: begin
						$display("user read %h", wbs_adr_i);
						wbs_dat_o			<= interrupt_edge;
					end
					default: begin
					end
				endcase
			end
			wbs_ack_o <= 1;
		end
	end
end

//interrupts
reg	[31:0]	prev_gpio_in;

//this is the change
wire [31:0]	gpio_edge;
assign gpio_edge	= prev_gpio_in ^ gpio_in;

/*
initial begin
	$monitor ("%t, interrupts: %h, mask: %h, edge: %h, gpio_edge: %h", $time, interrupts, interrupt_mask, interrupt_edge, gpio_edge);
end
*/


always @ (posedge clk) begin

	if (rst) begin
		interrupts	<= 32'h00000000;
		wbs_int_o	<= 0;
	end
	else begin
		if (clear_interrupts) begin
			interrupts <= 32'h00000000;
		end
		else begin
			//check to see if there was a negative or postive edge that occured
			interrupts	<= interrupt_mask & (interrupt_edge ^~ gpio_edge);
		end
		if (interrupts != 0) begin
			//tell the master that we have interrupts
			$display ("slave initiazting an interrupt");
			wbs_int_o	<= 1;
		end
		else begin
			wbs_int_o	<= 0;
		end
	end
	prev_gpio_in	<= gpio_in;
end

endmodule
