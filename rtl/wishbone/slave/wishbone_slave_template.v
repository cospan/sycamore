//wishbone_slave_template.v

module wishbone_slave_template (
	clk,
	rst,

	wbs_we_i,
	wbs_cyc_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o;
	wbs_dat_i;
	wbs_dat_o,
	wbs_adr_i;
	wbs_int_o;
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
				//ADDRESS DEFINE : begin
				//	do something
				//end
			endcase
		end

		else begin 
			//read request
			case (wbs_adr_i)
				//ADDRESS DEFINE : begin
				//	do something
				//end
			endcase
		end
		wbs_ack_i;
	end
end


endmodule
