//ddr_dcm.v

/**
 * 8/31/2011
 * Version 0.0.01
 *	Initial
 *
 */

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
`timescale 1ns/1ps
`include "project_defines.v"  //this holds the define for SIM, VENDOR_FPGA and VENDOR_XILINX

module ddr_dcm (
	clk,
	rst,

	ddr_clk,
	ddr_2x_clk,
	dcm_lock,

	ddr_fb_clk_in
);


input 		clk;
input 		rst;
output 		ddr_clk;
output		ddr_2x_clk;
output 		dcm_lock;

input		ddr_fb_clk_in;


//defaults to 100MHz
`ifdef VENDOR_XILINX
	
	wire	dcm1_clk;
	wire	dcm1_clk_out;
	wire	fb_clk_in;
	
	wire	dcm2_clk_in;
	wire	dcm2_synth_clk_out;
	wire	dcm2_clk_out;
	wire	dcm2_fb_clk_in;

	wire	dcm1_lock;
	wire	dcm2_lock;
	assign	dcm_lock	=	(dcm1_lock & dcm2_lock);

	//DCM1
   	IBUFG dcm1_in_ibuf (.I(clk), .O(dcm1_clk));
   	BUFG  dcm1_out_buf (.I(dcm1_clk_out), .O(ddr_clk));
   	IBUFG dcm1_fb_ibuf (.I(ddr_fb_clk_in), .O(fb_clk_in)); 

   	BUFG  dcm2_in_buf (.I(dcm1_clk), .O(dcm2_clk_in));
   	BUFG  dcm2_out_buf (.I(dcm2_synth_clk_out), .O(ddr_2x_clk));
   	BUFG  dcm2_fb_buf (.I(dcm2_clk_out), .O(dcm2_fb_clk_in));



	//Main DDR Clock
	//Attach the feedback from the external feedback
	DCM_SP #( 
		.CLK_FEEDBACK("2X"), 
		.CLKDV_DIVIDE(2.0), 
		.CLKFX_DIVIDE(1), 
        .CLKFX_MULTIPLY(1), 
		.CLKIN_DIVIDE_BY_2("FALSE"), 
        .CLKIN_PERIOD(20.000), 
		.CLKOUT_PHASE_SHIFT("NONE"), 
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), 
		.DFS_FREQUENCY_MODE("LOW"), 
        .DLL_FREQUENCY_MODE("LOW"), 
		.DUTY_CYCLE_CORRECTION("TRUE"), 
        .FACTORY_JF(16'hC080), 
		.PHASE_SHIFT(0), 
		.STARTUP_WAIT("FALSE") ) 
         DCM_SP_INST1 (	.CLKFB(fb_clk_in), 
                        .CLKIN(dcm1_clk), 
                        .DSSEN(0), 
                        .PSCLK(0), 
                        .PSEN(0), 
                        .PSINCDEC(0), 
                        .RST(rst), 
                        .CLKDV(), 
                        .CLKFX(), 
                        .CLKFX180(), 
                        .CLK0(dcm2_clk_in), 
                        .CLK2X(dcm1_clk_out), 
                        .CLK2X180(), 
                        .CLK90(), 
                        .CLK180(), 
                        .CLK270(), 
                        .LOCKED(dcm1_lock), 
                        .PSDONE(), 
                        .STATUS()
	);

	//Internal DCM to generate the 2X clock frequency within the core for DDR capability
	DCM_SP #( 
   		.CLK_FEEDBACK("1X"), 
		.CLKDV_DIVIDE(2.0), 
		.CLKFX_DIVIDE(1), 
        .CLKFX_MULTIPLY(4), 
		.CLKIN_DIVIDE_BY_2("FALSE"), 
        .CLKIN_PERIOD(20.000), 
		.CLKOUT_PHASE_SHIFT("NONE"), 
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), 
		.DFS_FREQUENCY_MODE("LOW"), 
        .DLL_FREQUENCY_MODE("LOW"), 
		.DUTY_CYCLE_CORRECTION("TRUE"), 
        .FACTORY_JF(16'hC080), 
		.PHASE_SHIFT(0), 
		.STARTUP_WAIT("FALSE") ) 
         DCM_SP_INST2 (	.CLKFB(dcm2_fb_clk_in), 
                        .CLKIN(dcm2_clk_in), 
                        .DSSEN(0), 
                        .PSCLK(0), 
                        .PSEN(0), 
                        .PSINCDEC(0), 
                        .RST(rst), 
                        .CLKDV(), 
                        .CLKFX(dcm2_synth_clk_out), 
                        .CLKFX180(), 
                        .CLK0(dcm2_clk_out), 
                        .CLK2X(), 
                        .CLK2X180(), 
                        .CLK90(), 
                        .CLK180(), 
                        .CLK270(), 
                        .LOCKED(dcm2_lock), 
                        .PSDONE(), 
                        .STATUS()
	);


`else


//simulation
parameter DELAY	= 4;
parameter PERIOD = 1;

wire		sim_clk;
reg			sim_2x_clk;
reg	[7:0]	count;
reg	[7:0]	count_2x;

assign fb_clock_out	=	1;
assign ddr_clk		=	sim_clk;
assign ddr_2x_clk	=	sim_2x_clk;

initial begin
	sim_clk	= 1'b0;
	#(PERIOD);
	forever
		#(PERIOD) sim_clk	= ~sim_clk;
end

always @ (posedge sim_clk) begin
	if (rst) begin
		count	<= 0;	
	end
	else begin	
		if (count_2x >= DELAY) begin
			count_2x <= 0;
			sim_2x_clk	<= ~sim_2x_clk;
			if (count >= (DELAY >> 1)) begin
				sim_clk	<= ~sim_clk;
			end
			else begin
				count	<= count + 1;
			end
		end
		else begin
			count_2x = count_2x + 1;
		end
	end
end
`endif

endmodule
