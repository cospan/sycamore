//wishbone_slave_template.v

/*
	9/10/2011
		removed the duplicate wbs_dat_i
		added the wbs_sel_i port
*/

/*
	Use this to tell sycamore how to populate the Device ROM table
	so that users can interact with your slave

	META DATA

	identification of your device 0 - 65536
	DRT_ID: 0

	flags (read drt.txt in the slave/device_rom_table directory 1 means
	a standard device
	DRT_FLAGS:1

	number of registers this should be equal to the nubmer of ADDR_???
	parameters
	DRT_SIZE:3

*/


module wishbone_slave_template (
	clk,
	rst,

	wbs_we_i,
	wbs_cyc_i,
	wbs_sel_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,
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

parameter			ADDR_0	=	32'h00000000;
parameter			ADDR_1	=	32'h00000001;
parameter			ADDR_2	=	32'h00000002;

//blocks
always @ (posedge clk) begin
	if (rst) begin
		wbs_dat_o	<= 32'h0;
		wbs_ack_o	<= 0;
		wbs_int_o	<= 0;
	end

	//when the master acks our ack, then put our ack down
	if (wbs_ack_o & ~ wbs_stb_i)begin
		wbs_ack_o <= 0;
	end

	if (wbs_stb_i & wbs_cyc_i) begin
		//master is requesting somethign
		if (wbs_we_i) begin
			//write request
			case (wbs_adr_i) 
				ADDR_0: begin
					//writing something to address 0
					//do something
				end
				ADDR_1: begin
					//writing something to address 1
					//do something
				end
				ADDR_2: begin
					//writing something to address 3
					//do something
				end
				//add as many ADDR_X you need here
				default: begin
				end
			endcase
		end

		else begin 
			//read request
			case (wbs_adr_i)
				ADDR_0: begin
					//reading something from address 0
				end
				ADDR_1: begin
					//reading something from address 1
				end
				ADDR_2: begin
					//reading soething from address 2
				end
				default: begin
				end
			endcase
		end
		wbs_ack_i <= 1;
	end
end


endmodule
