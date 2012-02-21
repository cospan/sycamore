//wb_bram.v
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
	11/05/2011
		set en_ram to 0 on reset
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
	DRT_ID:  5

	flags (read drt.txt in the slave/device_rom_table directory 1 means
	a standard device
	DRT_FLAGS:  1

	number of registers this should be equal to the nubmer of ADDR_???
	parameters
	DRT_SIZE:  4096

*/


module wb_bram (
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
	wbs_int_o
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

parameter			RAM_SIZE = 31;
parameter			SLEEP_COUNT = 4;

wire [31:0] read_data;
reg [31:0] write_data;
reg	[RAM_SIZE:0] ram_adr;
reg en_ram;

reg [3:0] ram_sleep;

bram br (
	.clk(clk),
	.rst(rst),
	.en(en_ram),
	.we(wbs_we_i),
	.write_address(ram_adr),
	.read_address(ram_adr),
	.data_in(write_data),
	.data_out(read_data)
);



//blocks
always @ (posedge clk) begin
	if (rst) begin
		wbs_dat_o	<= 32'h0;
		wbs_ack_o	<= 0;
		wbs_int_o	<= 0;
		ram_sleep	<= SLEEP_COUNT;
		ram_adr		<= 0;
		en_ram		<= 0;
	end

	else begin
		//when the master acks our ack, then put our ack down
		if (wbs_ack_o & ~wbs_stb_i)begin
			wbs_ack_o <= 0;
			en_ram <= 0;
		end

		if (wbs_stb_i & wbs_cyc_i) begin
			//master is requesting somethign
			en_ram <= 1;
			ram_adr <= wbs_adr_i[RAM_SIZE:0];
			if (wbs_we_i) begin
				//write request
				//the bram module will handle all the writes
				write_data <= wbs_dat_i;
//				$display ("write a:%h, d:%h", wbs_adr_i[RAM_SIZE:0], wbs_dat_i);
			end

			else begin 
				//read request
				wbs_dat_o <= read_data;
				//wbs_dat_o <= wbs_adr_i;
//				$display ("read a:%h, d:%h", wbs_adr_i[RAM_SIZE:0], read_data);
			end
			if (ram_sleep > 0) begin
				ram_sleep <= ram_sleep - 1;
			end
			else begin
				wbs_ack_o <= 1;
				ram_sleep <= SLEEP_COUNT;
			end
		end
	end
end


endmodule
