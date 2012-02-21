//mg_defines.v
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
	11/12/2011
		-Added NACK support
			commands
				COMMAND_NACK_TO_WR: set the NACK timeout
				COMMAND_NACK_TO_RD: read the NACK timeout

			status codes
				NACK_TIMEOUT: a NACK timeout occured

			default values:
				DEF_NACK_TIMEOUT: currently  set to 20 hex or 32 ticks
	11/06/2011
		-Added PERIPH_INTERRUPT to notify users of a peripheral 
			slave interrupt
		-Changed COMMAND_INTERRUPT to COMMAND_WR_INT_EN and
		COMMAND_RD_INT_EN
*/

// defines for the miracle grow project

`ifndef __MG_DEFINES__
`define __MG_DEFINES__

`define COMMAND_PING 		32'h00000000
`define COMMAND_WRITE 		32'h00000001
`define COMMAND_READ		32'h00000002
`define COMMAND_RW_FLAGS	32'h00000007
`define COMMAND_WR_INT_EN	32'h00000008
`define COMMAND_RD_INT_EN	32'h00000009
`define COMMAND_NACK_TO_WR	32'h0000000A
`define COMMAND_NACK_TO_RD	32'h0000000B

//conditions
`define PERIPH_INTERRUPT	32'h10000000
`define NACK_TIMEOUT		32'h20000000

//flags
`define FLAG_MEM_BUS		16'h0001

//default variables
`define DEF_NACK_TIMEOUT	32'h00000020

`endif //__MG_DEFINES__
