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


// defines for the miracle grow project

`ifndef __MG_DEFINES__
`define __MG_DEFINES__

`define COMMAND_PING 		32'h00000000
`define COMMAND_WRITE 		32'h00000001
`define COMMAND_READ		32'h00000002
`define COMMAND_WSTREAM_C 	32'h00000003
`define COMMAND_WSTREAM		32'h00000004
`define COMMAND_RSTREAM_C	32'h00000005
`define COMMAND_RSTREAM		32'h00000006
`define COMMAND_RW_FLAGS	32'h00000007
`define COMMAND_INTERRUPT	32'h00000008

`endif //__MG_DEFINES__
