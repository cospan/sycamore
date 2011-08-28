//tft_pclk_gen.v

/**
 * 8/23/2011
 * Version 0.0.01
 *
 **/

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

`include "project_defines.v"

module tft_pclk_gen (
	clk,
	rst,

	pclk,
	clock_divide,
	lock
);


input clk;
input rst;
input [15:0] clock_divide;
//I need this statement because of simulation only in the real design, the pclk will transition when rst is low
output lock;

/*
`ifdef VENDOR_XILINX

	output pclk;

	wire clk_fb;
	BUFG	CLKO_BUFG_INST (.I(clk_out), .O(clk_fb));

   DCM_SP #(
   	.CLKDV_DIVIDE(5.0),
	.CLKFX_DIVIDE(1),
    .CLKFX_MULTIPLY(4),
    .CLKIN_DIVIDE_BY_2("FALSE"),
    .CLKIN_PERIOD(20.000),
    .CLKOUT_PHASE_SHIFT("NONE"),
    .CLK_FEEDBACK("1X"),
    .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"),
    .DLL_FREQUENCY_MODE("LOW"),
    .DUTY_CYCLE_CORRECTION("TRUE"),
    .PHASE_SHIFT(0),
    .STARTUP_WAIT("FALSE")
   ) DCM_SP_INST (
      .CLK0(clk_out),
	  .CLK180(),
      .CLK270(),
      .CLK2X(),
      .CLK2X180(),
      .CLK90(),  
      .CLKDV(pclk),
      .CLKFX(),
      .CLKFX180(),
      .LOCKED(lock),
      .PSDONE(),
      .STATUS(),
      .CLKFB(clk_fb),
      .CLKIN(clk),
      .PSCLK(0),
      .PSEN(0),
      .PSINCDEC(0),
      .RST(rst)   
   );

   // End of DCM_SP_inst instantiation


`else
*/
//For debug simply connect clk to pclk

output reg	pclk = 0;
assign lock = 1;

reg	[15:0]	delay;




always @ (posedge clk) begin
	if (rst) begin
		delay 	<= 0;
		pclk	<= 1;
	end
	else begin
		if (delay == 0) begin
			pclk	<= ~pclk;
			delay    <= clock_divide;
		end
		else begin
		    delay <= delay - 1;
		end
	end

end

//`endif

endmodule 
