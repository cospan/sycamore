//bram.v
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
 * This BRAM code was inspired by this website:
 * http://www.dilloneng.com/documents/howto/ram_inference
 *
 */


module bram (
	clk,
	rst,

	en,
	we,
	write_address,
	read_address,
	data_in,
	data_out
);

input clk;
input rst;

input en;
input we;
input [31:0] write_address;
input [31:0] read_address;
input [31:0] data_in;
output reg [31:0] data_out;

//synthesis attribute ram_style of mem is block
reg [31:0] mem [0:1023]; //pragma attribute mem ram_block TRUE
reg [31:0] read_address_reg;


/*
initial begin
	$monitor ("%t: wa: %h, ra: %h, di: %h, do: %h", $time, write_address, read_address, data_in, data_out); 
end
*/

always @ (posedge clk) begin
	if (rst) begin
		data_out <= 32'h0;
	end
	else begin
		if (en) begin
			read_address_reg <= read_address;

			if (we) begin
				mem[write_address] <= data_in;
			end
			data_out <= mem[read_address_reg];
		end
	end
end

endmodule
