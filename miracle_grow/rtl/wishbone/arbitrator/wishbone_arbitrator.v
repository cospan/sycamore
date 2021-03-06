//wishbone_interconnect.v
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


module ${ARBITRATOR_NAME} (
	clk,
	rst,

	//master ports
${PORTS}

	//slave port
    s_we_o,
    s_cyc_o,
    s_stb_o,
	s_sel_o,
    s_ack_i,
    s_dat_o,
    s_dat_i,
    s_adr_o,
    s_int_i

);


//control signals
input 				clk;
input 				rst;

//wishbone slave signals
output reg			s_we_o;
output reg			s_stb_o;
output reg 			s_cyc_o;
output reg	[3:0]	s_sel_o;
output reg	[31:0]	s_adr_o;
output reg  [31:0]	s_dat_o;
input  		[31:0]	s_dat_i;
input      			s_ack_i;
input 				s_int_i;


//wishbone master signals
${PORT_DEFINES}

//this should be parameterized
reg [7:0]master_select;

${MASTER_SELECT}

${WRITE}

${STROBE}

${CYCLE}

${SELECT}

${ADDRESS}

${DATA}

${ASSIGN}

endmodule
