//ft245_sync_fifo.v

module ft245_sync_fifo (
	fclk,
	rst,

	data,
	txe_n,
	wr_n,

	rde_n,
	rd_n,
	oe_n,

	siwu,


	//master interface

);


input			clk;
input			rst;

inout	[7:0]	data;
input			txe_n;
output reg		wr_n;

input			rde_n;
output reg		rd_n;
output reg		oe_n;

output reg		siwu;


reg				data_out_en;
reg		[7:0]	data_out;

assign data		=	(data_out_en) ? data_out:8'hZ;


always @ (posedge clk) begin
	if (rst) begin
		data_out_en	<=	0;
		data_out	<=	0;
		wr_n		<=	0;
		rd_n		<=	0;
		oe_n		<=	0;
	end
	else begin

		//reading
			//indicate that we are busy	

		//writing


	end
end


endmodule

