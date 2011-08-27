//tft_core.v

/**
 * 8/23/2011
 * Version 0.0.01
 *
 **/



/**
 *
 *	the data needs to be set up on the falling edge of the pclk, since the 
 *	pclk_2x will come in
 *
 **/

module tft_core (
	clk,
	rst,

	resx,
	resy,

	v_pulse,
	v_front_porch,
	v_back_porch,

	h_pulse,
	h_front_porch,
	h_back_porch,

	vis_y_pos,
	vis_x_pos,

	red_in,
	green_in,
	blue_in,

	//out to the LCD screen
	red_out,
	green_out,
	blue_out,
	pclk,
	disp_en,
	hsync,
	vsync,
	data_en


);


input 				clk;
input 				rst;

input [7:0]			red_in;
input [7:0]			green_in;
input [7:0]			blue_in;

input [15:0]		resx;
input [15:0]		resy;
input [15:0]		v_pulse;
input [15:0]		v_front_porch;
input [15:0]		v_back_porch;
input [15:0]		h_pulse;
input [15:0]		h_front_porch;
input [15:0]		h_back_porch;

output reg [7:0]	red_out;
output reg [7:0]	green_out;
output reg [7:0]	blue_out;
output reg			hsync;
output reg			vsync;
output reg			data_en;
input				disp_en;

input				pclk;

output reg [15:0]	vis_y_pos;
output reg [15:0]	vis_x_pos;

//registers			
reg	[15:0]			y_pos;
reg [15:0]			x_pos;


reg [15:0]	total_x;
reg [15:0]	total_y;
reg [15:0] stop_vis_x;
reg [15:0] stop_vis_y;
reg [15:0] start_vis_x;
reg [15:0] start_vis_y;

always @ (posedge pclk) begin

	if (rst) begin
		red_out 	<= 8'h0;
		green_out 	<= 8'h0;
		blue_out	<= 8'h0;
		hsync		<= 0;
		vsync		<= 0;
		data_en		<= 0;

		y_pos		<= 16'hFFFF;
		vis_y_pos	<= 16'h0000;
		x_pos		<= 16'hFFFF;
		vis_x_pos 	<= 16'h0000;

		total_x		<= 16'd0612;
		total_y		<= 16'd0272;

		stop_vis_x	<= 16'd0582;
		stop_vis_y	<= 16'd0258;

		start_vis_x	<= 16'd0008;
		start_vis_y	<= 16'd0018;


	end
	else begin
		
		if (disp_en) begin
			if (y_pos < (total_y)) begin

				x_pos <= x_pos + 1;
				$display ("y_pos: %d", y_pos);
				$display ("x_pos: %d", x_pos);
				//$display ("vis_x_pos: %d", vis_x_pos);
				//$display ("vis_y_pos: %d", vis_y_pos);
			

				if (x_pos < total_x) begin
					if (x_pos >= h_pulse) begin
						hsync	<= 1;
					end
					if ((x_pos >= start_vis_x) && (x_pos < (stop_vis_x))) begin
						//FINALLY OUTPUT A PIXEL!
                        red_out    <= red_in;
                        green_out    <= green_in;
                        blue_out    <= blue_in;
						data_en <= 1;
						//output the pixel at the 
						vis_x_pos	<= vis_x_pos + 1;
					end
					else if (x_pos >= stop_vis_x) begin
						data_en	<= 0;
					end
				end
				else begin
					$display ("finished row");
					//$display ("y_pos: %d", y_pos);
					hsync		<= 0;
					x_pos 		<= 0;
					y_pos 		<= y_pos + 1;
					vis_x_pos	<= 0;
					vis_y_pos	<= 0;
					if (y_pos >= v_pulse) begin
						vsync <= 1;
					end
					if ((y_pos >= start_vis_y) && (y_pos < (stop_vis_y))) begin
						//set the visual y pixel
						vis_y_pos	<= vis_y_pos + 1;
					end
				end
			end

			else begin
				vsync 		<= 0;
                data_en     <= 0;
				hsync		<= 0;
				x_pos		<= 0;
				y_pos		<= 0;
				vis_x_pos	<= 0;
				vis_y_pos 	<= 0;
			end
		end
		//initialize a session by setting all values to zero
		else begin
			$display ("y total: %d", total_y);
			$display ("x total: %d", total_x);

			vsync	<= 0;
			hsync	<= 0;
			//one shot for sending a frame
			y_pos			<= 16'h0;
			x_pos			<= 16'h0;
			vis_x_pos		<= 16'h0;
			vis_y_pos		<= 16'h0;

			total_x	<=	h_pulse + resx + h_front_porch + h_back_porch;
			total_y	<=	v_pulse + resy + v_front_porch + v_back_porch;

			start_vis_x	<= h_pulse + h_back_porch;
			start_vis_y <= v_pulse + v_back_porch; 
			
			stop_vis_x	<= h_pulse + resx + h_back_porch;
			stop_vis_y	<= v_pulse + resy + v_back_porch;

		end

	end

end

endmodule
