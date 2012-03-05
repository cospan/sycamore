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



//sdram_clkgen.v


module sdram_clkgen (
	input clk,
	input rst,

	output locked,
	output out_clk,
	output phy_out_clk
);

wire clock_out;
DCM_SP #(
	.CLKFX_DIVIDE(1),
	.CLKFX_MULTIPLY(2),
	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("NONE"),
	.DESKEW_ADJUST("SOURCE_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.FACTORY_JF(16'hC080),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("FALSE")
) dcm_fx (
	.DSSEN(),
	.CLK0(),
	.CLK180(),
	.CLK270(),
	.CLK2X(),
	.CLK2X180(),
	.CLK90(),
	.CLKDV(),
	.CLKFX(clock_out),
	.CLKFX180(clock_out_n),
	.LOCKED(locked),
	.PSDONE(),
	.STATUS(),
	.CLKFB(),
	.CLKIN(clk),
	.PSCLK(1'b0),
	.PSEN(1'b0),
	.PSINCDEC(1'b0),
	.RST(rst)

);


ODDR2 #(
	.DDR_ALIGNMENT("NONE"),	//Sets output alignment to NON
	.INIT(1'b0),			//Sets the inital state to 0
	.SRTYPE("SYNC")			//Specified "SYNC" or "ASYNC" reset
)	pad_buf (

	.Q(phy_out_clk),
	.C0(clock_out),
	.C1(clock_out_n),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);


BUFG bufg_sdram_clk (
	.I(clock_out),
	.O(out_clk)
);

endmodule
