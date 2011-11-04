//wishbone_interconnect.v
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


module arbitrator_2_masters (
	clk,
	rst,

	//master ports
	m0_we_i,
	m0_cyc_i,
	m0_stb_i,
	m0_sel_i,
	m0_ack_o,
	m0_dat_i,
	m0_dat_o,
	m0_adr_i,
	m0_int_o,


	m1_we_i,
	m1_cyc_i,
	m1_stb_i,
	m1_sel_i,
	m1_ack_o,
	m1_dat_i,
	m1_dat_o,
	m1_adr_i,
	m1_int_o,




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
input			m0_we_i;
input			m0_cyc_i;
input			m0_stb_i;
input	[3:0]	m0_sel_i;
input	[31:0]	m0_adr_i;
input	[31:0]	m0_dat_i;
output	[31:0]	m0_dat_o;
output			m0_ack_o;
output			m0_int_o;


input			m1_we_i;
input			m1_cyc_i;
input			m1_stb_i;
input	[3:0]	m1_sel_i;
input	[31:0]	m1_adr_i;
input	[31:0]	m1_dat_i;
output	[31:0]	m1_dat_o;
output			m1_ack_o;
output			m1_int_o;




//this should be parameterized
reg [7:0]master_select;

//master select block
parameter MASTER_NO_SEL = 8'hFF;
parameter MASTER_0 = 0;
parameter MASTER_1 = 1;


always @(rst or master_select or m0_stb_i or m1_stb_i ) begin
	if (rst) begin
		master_select <= MASTER_NO_SEL;
	end
	else begin
		case (master_select)
			MASTER_0: begin
				if (~m0_stb_i) begin
					master_select <= MASTER_NO_SEL;
				end
			end
			MASTER_1: begin
				if (~m1_stb_i) begin
					master_select <= MASTER_NO_SEL;
				end
			end
			default: begin
				//nothing selected
				if (m0_stb_i) begin
					master_select <= MASTER_0;
				end
				else if (m1_stb_i) begin
					master_select <= MASTER_1;
				end
			end
		endcase
	end
end


//write select block
always @(master_select or m0_we_i or m1_we_i) begin
	case (master_select)
		MASTER_0: begin
			s_we_o <= m0_we_i;
		end
		MASTER_1: begin
			s_we_o <= m1_we_i;
		end
		default: begin
			s_we_o <= 1'h0;
		end
	endcase
end


//strobe select block
always @(master_select or m0_we_i or m1_we_i) begin
	case (master_select)
		MASTER_0: begin
			s_stb_o <= m0_stb_i;
		end
		MASTER_1: begin
			s_stb_o <= m1_stb_i;
		end
		default: begin
			s_stb_o <= 1'h0;
		end
	endcase
end


//cycle select block
always @(master_select or m0_cyc_i or m1_cyc_i) begin
	case (master_select)
		MASTER_0: begin
			s_cyc_o <= m0_cyc_i;
		end
		MASTER_1: begin
			s_cyc_o <= m1_cyc_i;
		end
		default: begin
			s_cyc_o <= 1'h0;
		end
	endcase
end


//select select block
always @(master_select or m0_sel_i or m1_sel_i) begin
	case (master_select)
		MASTER_0: begin
			s_sel_o <= m0_sel_i;
		end
		MASTER_1: begin
			s_sel_o <= m1_sel_i;
		end
		default: begin
			s_sel_o <= 4'h0;
		end
	endcase
end


//address seelct block
always @(master_select or m0_adr_i or m1_adr_i) begin
	case (master_select)
		MASTER_0: begin
			s_adr_o <= m0_adr_i;
		end
		MASTER_1: begin
			s_adr_o <= m1_adr_i;
		end
		default: begin
			s_adr_o <= 32'h00000000;
		end
	endcase
end


//data select block
always @(master_select or m0_dat_i or m1_dat_i) begin
	case (master_select)
		MASTER_0: begin
			s_dat_o <= m0_dat_i;
		end
		MASTER_1: begin
			s_dat_o <= m1_dat_i;
		end
		default: begin
			s_dat_o <= 32'h00000000;
		end
	endcase
end


//assign block
assign m0_ack_o = (master_select == MASTER_0) ? s_ack_i : 0;
assign m0_dat_o = (master_select == MASTER_0) ? s_dat_i : 0;
assign m0_int_o = (master_select == MASTER_0) ? s_int_i : 0;

assign m1_ack_o = (master_select == MASTER_1) ? s_ack_i : 0;
assign m1_dat_o = (master_select == MASTER_1) ? s_dat_i : 0;
assign m1_int_o = (master_select == MASTER_1) ? s_int_i : 0;



endmodule
