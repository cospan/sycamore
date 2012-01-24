//ft245_sync_fifo.v

module ft245_sync_fifo (
	clk,
	rst,

	data,
	txe_n,
	wr_n,

	rde_n,
	rd_n,
	oe_n,

	siwu
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



always @ (posedge clk) begin
	if (rst) begin
	end
	else begin

	end
end


endmodule

