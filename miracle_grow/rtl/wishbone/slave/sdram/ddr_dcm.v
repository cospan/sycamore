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
`timescale 100ps/1ps
`include "project_defines.v"  //this holds the define for SIM, VENDOR_FPGA and VENDOR_XILINX

module ddr_dcm (
	clk,
	rst,

	ddr_clk,
	ddr_clk_n,
	ddr_2x_clk,
	dcm1_lock,
	dcm2_lock,

	ddr_fb_clk_in
);


input 		clk;
input 		rst;
output 		ddr_clk;
output		ddr_clk_n;
output		ddr_2x_clk;
output 		dcm1_lock;
output		dcm2_lock;
input		ddr_fb_clk_in;


`ifdef VENDOR_XILINX
	
	wire	fb_clk_in;
	wire	ddr_clk_pre;
	wire	dcm2_clk_in_pre;
	wire	dcm2_clk_in;
	wire	dcm2_synth_clk_out;
	wire	dcm2_clk_out;
	wire	dcm2_clk_fb_pre;
	wire	dcm2_clk_fb;
	wire	clk_in;


	//DCM1
//	BUFG  dcm1_clk_in ( .I(clk), .O(clk_in));
	//2X output of the first DCM driver for the main clock
   	BUFG  dcm1_out_buf (.I(ddr_clk_pre), .O(ddr_clk));
	BUFG  dcm1_out_buf_n (.I(~ddr_clk_pre), .O(ddr_clk_n));
	//Input from the clock feedback pin for the first DCM
   	IBUFG dcm1_fb_ibuf (.I(ddr_fb_clk_in), .O(fb_clk_in)); 


	//DCM2
	//output of the first DCM
   	BUFG  dcm2_in_buf (.I(dcm2_clk_in_pre), .O(dcm2_clk_in));
	//200MHz clock output used for the DDR state machine
   	BUFG  dcm2_out_buf (.I(dcm2_synth_clk_out), .O(ddr_2x_clk));
	//feedback for the 200MHz DDR state machine
   	BUFG  dcm2_fb_buf (.I(dcm2_clk_fb_pre), .O(dcm2_clk_fb));



	//Main DDR Clock
	//Attach the feedback from the external feedback
	DCM_SP #( 
		.CLK_FEEDBACK("2X"), 
		.CLKDV_DIVIDE(1.0), 
		.CLKFX_DIVIDE(1.0), 
        .CLKFX_MULTIPLY(1.0), 
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
		 				.CLKIN(clk),
                        //.CLKIN(clk_in), 
                        .DSSEN(0), 
                        .PSCLK(0), 
                        .PSEN(0), 
                        .PSINCDEC(0), 
                        .RST(rst), 
                        .CLKDV(), 
                        .CLKFX(), 
                        .CLKFX180(), 
                        .CLK0(dcm2_clk_in_pre), 
                        .CLK2X(ddr_clk_pre), 
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
		.CLKFX_DIVIDE(1.0), 
        .CLKFX_MULTIPLY(4.0), 
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
         DCM_SP_INST2 (	.CLKFB(dcm2_clk_fb), 
                        .CLKIN(dcm2_clk_in), 
                        .DSSEN(0), 
                        .PSCLK(0), 
                        .PSEN(0), 
                        .PSINCDEC(0), 
                        .RST(rst), 
                        .CLKDV(), 
                        .CLKFX(dcm2_synth_clk_out), 
                        .CLKFX180(), 
                        .CLK0(dcm2_clk_fb_pre), 
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
parameter DELAY	= 1;


reg			sim_clk = 0;
reg			sim_2x_clk = 0;
reg			count;

assign fb_clock_out	=	1;
assign ddr_clk		=	sim_clk;
assign ddr_2x_clk	=	sim_2x_clk;

assign	dcm1_lock	=	1;
assign	dcm2_lock	=	1;

always #25 sim_2x_clk = ~sim_2x_clk;

always @ (posedge sim_2x_clk) begin
	if (rst) begin
	end
	else begin	
		sim_clk	<= ~sim_clk;
	end

end
`endif

endmodule
