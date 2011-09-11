//tft.v

/**
 * 8/22/2011
 * new horizon 4.3 inch TFT LCD
 * Version 0.0.01
 *	getting SOMETHING on the screen
 *
 * 8/28/2011
 *	Version 0.0.02
 *	getting things on the screen but the screen suddenly goes into reset,
 *	adding debug wishbone commands to rule out possible signal attenuation
 *	due to poor connectors, if the initial test of slowing down the clock
 *	doesn't work I'll add more code to slow down all the LCD variables
 *	(horizontal/vertical front porch, back porch and pulses)
 *
 * 8/29/2011
 *	Version 0.0.03
 *	Things are working on the LCD, it only displays solid colors written
 *	from the host, but now the physical layer is confirmed
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

/*
	META DATA

	DRT_ID:10
	DRT_FLAGS:1
	DRT_SIZE:4

*/


module tft (
	clk,
	rst,

	wbs_we_i,
	wbs_cyc_i,
	wbs_stb_i,
	wbs_sel_i,
	wbs_ack_o,
	wbs_dat_i,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,

	//LCD Control Signals
	red,
	green,
	blue,
	pclk,
	disp_en,
	hsync,
	vsync,
	data_en,

	debug_leds
);

input 				clk;
input 				rst;

//wishbone slave signals
input 				wbs_we_i;
input 				wbs_stb_i;
input 				wbs_cyc_i;
input		[3:0]	wbs_sel_i;
input		[31:0]	wbs_adr_i;
input  		[31:0]	wbs_dat_i;
output reg  [31:0]	wbs_dat_o;
output reg			wbs_ack_o;
output reg			wbs_int_o;

output [7:0]		debug_leds;

//LCD Signals
output [7:0]		red;
output [7:0]		green;
output [7:0]		blue;

//pclk needs to be at 9.2MHz
output 				pclk;
output reg			disp_en;
output				hsync;
output				vsync;
output				data_en;

//parameters
parameter	ADDR_FLAGS 		= 32'h00000000;
parameter	ADDR_COLOR		= 32'h00000001;
parameter	ADDR_CLK_DIV	= 32'h00000002;

parameter	TFT_FLAG_EN			= 0;
parameter	TFT_FLAG_ONESHOT 	= 1;
//TFT Parameters
parameter HORIZONTAL_SIZE		=	16'd0480;
parameter HORIZONTAL_FRONT_PORCH = 	16'd0002;
parameter HORIZONTAL_PULSE		=	16'd0041;
parameter HORIZONTAL_BACK_PORCH	=	16'd0002;

parameter VERTICAL_SIZE			= 	16'd0272;
parameter VERTICAL_FRONT_PORCH	=	16'd0002;
parameter VERTICAL_PULSE		=	16'd0010;
parameter VERTICAL_BACK_PORCH	=	16'd0002;


reg	[15:0]			resx;	
reg [15:0]			resy;
reg	[15:0]			v_pulse;
reg [15:0]			v_front_porch;
reg [15:0]			v_back_porch;
reg [15:0]			h_pulse;
reg [15:0]			h_front_porch;
reg [15:0]			h_back_porch;
reg [15:0]			clock_divide;

wire				lock;

tft_pclk_gen clk_gen(
	.clk(clk),
	.rst(rst),
	.lock(lock),
	.pclk(pclk),
	.clock_divide(clock_divide)
);

//debug enable when display is enable, if this goes on, then this means that Wishbone is communicating everything

wire [15:0]				vis_y_pos;
wire [15:0]				vis_x_pos;

reg	[7:0]			red_in;
reg [7:0]			green_in;
reg [7:0]			blue_in;

reg debug_flag_en;
reg debug_wb;

assign debug_leds[0]	= disp_en;
assign debug_leds[1]	= lock;
assign debug_leds[2]	= vsync;
assign debug_leds[3]	= hsync;
assign debug_leds[4]	= data_en;
assign debug_leds[5]	= pclk;
assign debug_leds[6]	= debug_flag_en; 
assign debug_leds[7]	= debug_wb;

tft_core core (
	.clk(clk),
	.rst(rst),

	.resx(resx),
	.resy(resy),

	.h_pulse(h_pulse),
	.h_front_porch(h_front_porch),
	.h_back_porch(h_back_porch),
	
	.v_pulse (v_pulse),
	.v_front_porch(v_front_porch),
	.v_back_porch(v_back_porch),

	.vis_y_pos(vis_y_pos),
	.vis_x_pos(vis_x_pos),
	
	.red_in(red_in),
	.green_in(green_in),
	.blue_in(blue_in),

	.red_out(red),
	.green_out(green),
	.blue_out(blue),
	.pclk(pclk),
	.hsync(hsync),
	.vsync(vsync),
	.data_en(data_en),
	.disp_en(disp_en)

);

/*
initial begin
    $monitor ("%t: send_frame: h", $time, send_frame );
end
*/

//blocks
always @ (posedge clk) begin



	if (rst) begin
		wbs_dat_o			<= 32'h0;
		wbs_ack_o			<= 0;
		wbs_int_o			<= 0;

		debug_wb			<= 0;
		debug_flag_en		<= 0;
		disp_en				<= 0;

		resy				<= VERTICAL_SIZE;
		resx				<= HORIZONTAL_SIZE;

		v_pulse				<= VERTICAL_PULSE;
		v_front_porch		<= VERTICAL_FRONT_PORCH;
		v_back_porch		<= VERTICAL_BACK_PORCH;

		h_pulse				<= HORIZONTAL_PULSE;
		h_front_porch		<= HORIZONTAL_FRONT_PORCH;
		h_back_porch		<= HORIZONTAL_BACK_PORCH;

		red_in				<= 8'h0;
		green_in			<= 8'h0;
		blue_in				<= 8'h0;

		//50MHz clock/(3) / 2 ~ 8.3MHz
		clock_divide			<= 16'h03;

    end

    else begin
		if (wbs_stb_i || wbs_ack_o) begin
     		$display ("tft wb: %h ack: %h", wbs_stb_i, wbs_ack_o);
		end

    	//when the master acks our ack, then put our ack down
	    if (wbs_ack_o & ~ wbs_stb_i)begin
    		wbs_ack_o <= 0;
	    end

    	if (wbs_stb_i & wbs_cyc_i) begin
            $display ("new transaction in LCD, ADDR: %h", wbs_adr_i);

			debug_wb	<= ~debug_wb;
	    	//master is requesting somethign
    		if (wbs_we_i) begin
		    	//write request
	    		case (wbs_adr_i) 
    				ADDR_FLAGS	: begin
						debug_flag_en <= ~debug_flag_en;
						disp_en	<= wbs_dat_i[TFT_FLAG_EN];
				    end
			    	ADDR_COLOR: begin
						red_in	<= wbs_dat_i[23:16];
						green_in <= wbs_dat_i[15:8];
						blue_in <= wbs_dat_i[7:0];
	    			end
					ADDR_CLK_DIV: begin
						clock_divide	<= wbs_dat_i[15:0];
					end
    				default: begin
			    	end
		    	endcase
	    	end

    		else begin 
	    		//read request
    			case (wbs_adr_i)
				    ADDR_FLAGS	: begin
      //                  $display ("Reading GPIO");
						wbs_dat_o[0]	<= disp_en;
						wbs_dat_o[31:1] <= 0;
		    		end
	    			ADDR_COLOR: begin
						wbs_dat_o[31:24]	<= 0;
						wbs_dat_o[23:16]	<= red_in;
						wbs_dat_o[15:8]		<= green_in;
						wbs_dat_o[7:0]		<= blue_in;
				    end
					ADDR_CLK_DIV: begin
						wbs_dat_o[31:16] <= 16'h00;
						wbs_dat_o[15:0] <= clock_divide[15:0];
					end
				    default: begin
				    end

			    endcase
		    end
		    wbs_ack_o <= 1;
	    end
    end
end


endmodule
