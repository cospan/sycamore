//ft245_sync_fifo.v


module ft245_sync_fifo (
	rst,

	//ftdi interface
	ftdi_clk,
	ftdi_data,
	ftdi_txe_n,
	ftdi_wr_n,
	ftdi_rde_n,
	ftdi_rd_n,
	ftdi_oe_n,
	ftdi_siwu,

	//host interface
	hi_clk,

	hi_data_in,
	hi_rd,
	hi_empty,

	hi_data_out,
	hi_wr,
	hi_full
);

input				rst;

//ftdi
input				ftdi_clk;
inout	[7:0]		ftdi_data;
input				ftdi_txe_n;
output reg			ftdi_wr_n;
input				ftdi_rde_n;
output reg			ftdi_rd_n;
output reg			ftdi_oe_n;
output reg			ftdi_siwu;


//host interface
input				hi_clk;
input	[31:0]		hi_data_in;
input				hi_rd;
output				hi_empty;

output	[31:0]		hi_data_out;
input				hi_wr;
output				hi_full;

reg					data_out_en;
reg		[7:0]		data_out;

assign ftdi_data	=	(data_out_en) ? data_out:8'hZ;

wire	[31:0]		ft_data_out;

//wires

wire				in_fifo_full;

afifo 
	#(		.DATA_WIDTH(32),
			.ADDRESS_WIDTH(9)
	)
	fifo_out (
	.rst(rst),

	.din_clk(ftdi_clk),	
	.dout_clk(hi_clk),

	.data_in(ft_data_out),
	.data_out(hi_data_in),
	.full(in_fifo_full),
	.empty(hi_empty),

	.wr_en(in_fifo_wr_en),
	.rd_en(hi_rd)
);

wire 			out_fifo_full;
wire	[31:0]	ftdi_data_out;
wire			out_fifo_empty;
wire			ftdi_in_rd;

afifo 
	#(		.DATA_WIDTH(32),
			.ADDRESS_WIDTH(9)
	)
fifo_in (
	.rst(rst),

	.din_clk(hi_clk),
	.dout_clk(ftdi_clk),

	.data_in(ftdi_data_out),
	.data_out(hi_data_in),
	.full(out_fifo_full),
	.empty(out_fifo_empty),

	.wr_en(hi_wr),
	.rd_en(ftdi_in_rd)

);



always @ (posedge ftdi_clk) begin
	if (rst) begin
		data_out_en	<=	0;
		data_out	<=	0;
		ftdi_wr_n		<=	0;
		ftdi_rd_n		<=	0;
		ftdi_oe_n		<=	0;
	end
	else begin

		//reading
			//indicate that we are busy	

		//writing


	end
end


endmodule

