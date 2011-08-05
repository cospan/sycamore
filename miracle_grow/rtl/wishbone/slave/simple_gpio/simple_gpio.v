//gpio.v

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


module simple_gpio (
	clk,
	rst,

	wbs_we_i,
	wbs_cyc_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_i,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,

	gpio_in,
	gpio_out
);

input 				clk;
input 				rst;

//wishbone slave signals
input 				wbs_we_i;
input 				wbs_stb_i;
input 				wbs_cyc_i;
input		[31:0]	wbs_adr_i;
input  		[31:0]	wbs_dat_i;
output reg  [31:0]	wbs_dat_o;
output reg			wbs_ack_o;
output reg			wbs_int_o;

//gpio
input		[31:0]	gpio_in;
output reg	[31:0]	gpio_out;

parameter	ADDR_IO 	= 32'h00000000;
parameter	ADDR_MASK	= 32'h00000001;

reg			[31:0]	mask;
/*
initial begin
    $monitor ("%t: we: %h stb: %h c: %h a: %h di: %h do: %h ak: %h i: %h", $time, wbs_we_i, wbs_stb_i, wbs_cyc_i, wbs_adr_i, wbs_dat_i, wbs_dat_o, wbs_ack_o, wbs_int_o );
end
*/
//blocks
always @ (posedge clk) begin
	if (rst) begin
		wbs_dat_o	<= 32'h0;
		wbs_ack_o	<= 0;
		wbs_int_o	<= 0;
		gpio_out	<= 32'h0;
		mask		<= 32'h0;
    end

    else begin
//     $display ("gpio stb: %h ack: %h", wbs_stb_i, wbs_ack_o);
	
    	//when the master acks our ack, then put our ack down
	    if (wbs_ack_o & ~ wbs_stb_i)begin
    		wbs_ack_o <= 0;
	    end

    	if (wbs_stb_i & wbs_cyc_i) begin
            $display ("new transaction in GPIO, ADDR: %h", wbs_adr_i);
	    	//master is requesting somethign
    		if (wbs_we_i) begin
		    	//write request
	    		case (wbs_adr_i) 
    				ADDR_IO	: begin
                        $display ("writing to gpio_out: %h", wbs_dat_i);
					    gpio_out	<= wbs_dat_i & mask;
				    end
			    	ADDR_MASK: begin
		    			mask		<= wbs_dat_i;
	    			end
    				default: begin
			    	end
		    	endcase
	    	end

    		else begin 
	    		//read request
    			case (wbs_adr_i)
				    ADDR_IO	: begin
      //                  $display ("Reading GPIO");
			    		wbs_dat_o	<= gpio_in;
		    		end
	    			ADDR_MASK: begin
    					wbs_dat_o	<= mask;
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
