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


/* 
    Thanks Rudolf Usselmann yours was a better implementation than mine

    Copyright (C) 2000-2002
    Rudolf Usselmann
    www.asics.ws
    rudi@asics.ws
*/

module wishbone_interconnect (
	clk,
	rst,

    m_we_i,
    m_cyc_i,
    m_stb_i,
	m_sel_i,
    m_ack_o,
    m_dat_i,
    m_dat_o,
    m_adr_i,
    m_int_o,

${PORTS}
);


${ADDRESSES}

parameter ADDR_FF = 8'hFF;

//state

//control signals
input 				clk;
input 				rst;

//wishbone master signals
input 				m_we_i;
input 				m_stb_i;
input 				m_cyc_i;
input		[3:0]	m_sel_i;
input		[31:0]	m_adr_i;
input  		[31:0]	m_dat_i;
output reg  [31:0]	m_dat_o;
output reg      	m_ack_o;
output	 			m_int_o;


//wishbone slave signals
${PORT_DEFINES}

//this should be parameterized
wire [7:0]slave_select;
wire [31:0] interrupts;

assign slave_select =   m_adr_i[31:24];

${DATA}

${ACK}

${INT}
assign m_int_o	= 	(interrupts != 0);

${ASSIGN}

endmodule
