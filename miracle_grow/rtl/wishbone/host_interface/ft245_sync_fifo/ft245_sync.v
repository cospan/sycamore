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

reg		[7:0]		data_out;

assign ftdi_data	=	(ftdi_oe_n) ? data_out:8'hZ;

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

parameter	IDLE	=	4'h0;
parameter	READ_OE	=	4'h1;
parameter	READ	=	4'h2;
parameter	WRITE	=	4'h3;
parameter	WRITE_ST=	4'h4;

reg	[3:0]	ftdi_state;	


always @ (posedge ftdi_clk) begin
	if (rst) begin
		data_out		<=	8'h0;
		ftdi_wr_n		<=	1;
		ftdi_rd_n		<=	1;
		ftdi_oe_n		<=	1;

		ftdi_state		<= 	IDLE;
	end
	else begin
//check if the txe_n or rxe_n unexpectedy went high, if so we need to gracefully return to IDLE
		case (ftdi_state)
			IDLE: begin
				ftdi_oe_n	<=	1;
				ftdi_wr_n	<=	1;
				ftdi_rd_n	<=	1;
				data_out	<=	8'h0;

				if (~ftdi_rde_n) begin
					//new data from the host
//if the FIFO is not full we can read data into the FIFO, but for this first version don't worry about FIFO
					$display ("new data available from the FTDI chip");
					ftdi_state	<=	READ_OE;
					ftdi_oe_n	<= 0;
				end
				else if (~ftdi_txe_n) begin
					$display ("FTDI chip is ready to be written to");
					ftdi_state	<= WRITE;
					ftdi_wr_n	<= 0;
//I might need to setup the first byte in here
				end
			end
			READ_OE: begin
				$display ("read oe");
				//need to allow for one clock cycle between the oe_n goes down and rd_n going down
				ftdi_rd_n		<= 0;
				ftdi_state		<= READ;
			end
			READ: begin
				//need to constantly check to see if the FIFO is empty, if so raise the RD	
//might need to hold the next byte in a temporary buffer cause the FIFO might be one step behind
				if (ftdi_rde_n) begin
					//were done
					ftdi_state	<=	IDLE;
					ftdi_oe_n	<=	1;
					ftdi_rd_n	<=	1;
				end
				else begin
					$display ("Read %02X", ftdi_data);

//temporarily do this for the demo
				end
//all packets should be 4 byte aligned (or 32 bits aligned)
			end
			WRITE: begin
				if (ftdi_txe_n) begin
					//were done
					$display ("host is full");
					ftdi_wr_n	<=	1;
					ftdi_state	<=	IDLE;
				end
				else begin
					data_out		<=	data_out + 1;
				end

//need a way to prematurely end a transmit... when the FIFO is finished
			end
			default: begin
				ftdi_state	<= IDLE;
			end
		endcase
	end
end


endmodule

