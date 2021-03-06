//ft245_sync_fifo.v


module ft245_sync_fifo (
	rst,
	clk,

	//in fifo
	in_fifo_rst,
	in_fifo_rd,
	in_fifo_empty,
	in_fifo_data,

	//out fifo
	out_fifo_wr,
	out_fifo_full,
	out_fifo_data,


	//phy interface
	ftdi_clk,
	ftdi_data,
	ftdi_txe_n,
	ftdi_wr_n,
	ftdi_rde_n,
	ftdi_rd_n,
	ftdi_oe_n,
	ftdi_suspend_n,
	ftdi_siwu,


);
//host interface
input				clk;
input				rst;

input				in_fifo_rst;
input				in_fifo_rd;
output				in_fifo_empty;
output	[7:0]		in_fifo_data;

//out fifo
input				out_fifo_wr;
output				out_fifo_full;
input	[7:0]		out_fifo_data;


//ftdi
input				ftdi_clk;
inout	[7:0]		ftdi_data;
input				ftdi_txe_n;
output reg			ftdi_wr_n;
input				ftdi_rde_n;
output reg			ftdi_rd_n;
output reg			ftdi_oe_n;
output reg			ftdi_siwu;
input				ftdi_suspend_n;



wire		[7:0]		data_out;

assign ftdi_data	=	(ftdi_oe_n) ? data_out:8'hZ;

wire	[7:0]		ft_data_out;


//wires

reg					in_command_ready;

//reg		[7:0]		in_fifo_data_in;
reg					in_fifo_wr;
wire				in_fifo_full;


wire 			out_fifo_full;
wire			out_fifo_empty;
reg				out_fifo_rd;
wire			out_fifo_wr;

//data that will be read from the FTDI chip (in)
afifo 
	#(		.DATA_WIDTH(8),
			.ADDRESS_WIDTH(9)
	)
fifo_in (
	.rst(in_fifo_rst),

	.din_clk(ftdi_clk),
	.dout_clk(clk),

	.data_in(ftdi_data),
	.data_out(in_fifo_data),
	.full(in_fifo_full),
	.empty(in_fifo_empty),

	.wr_en(in_fifo_wr),
	.rd_en(in_fifo_rd)

);
//data that will be sent to the FTDI chip (out)
afifo 
	#(		.DATA_WIDTH(8),
			.ADDRESS_WIDTH(9)
	)
	fifo_out (
	.rst(rst),

	.din_clk(clk),	
	.dout_clk(ftdi_clk),

	.data_in(out_fifo_data),
	.data_out(data_out),
	.full(out_fifo_full),
	.empty(out_fifo_empty),

	.wr_en(out_fifo_wr),
	.rd_en(out_fifo_rd)
);


parameter	IDLE	=	4'h0;
parameter	READ_OE	=	4'h1;
parameter	READ	=	4'h2;
parameter	DELAY1	=	4'h3;
parameter	WRITE	=	4'h4;
parameter	WAIT_RD	=	4'h8;

reg	[3:0]	ftdi_state;	

reg	[31:0]	read_count;
reg			prev_rd;

always @ (posedge ftdi_clk) begin
	
	if (rst) begin
		ftdi_wr_n		<=	1;
		ftdi_rd_n		<=	1;
		ftdi_oe_n		<=	1;
		ftdi_state		<= 	IDLE;
		ftdi_siwu		<=	1;

		read_count		<=	0;

		//in_fifo_data_in	<=	8'h0;
		in_fifo_wr		<=	0;
		out_fifo_rd		<=	0;
		prev_rd			<=	0;


		
	end
	else begin
		//pulses 
		prev_rd			<= out_fifo_rd;
		in_fifo_wr		<= 0;
		out_fifo_rd		<= 0;
		ftdi_wr_n		<= 1;
		ftdi_rd_n		<= 1;

//check if the txe_n or rxe_n unexpectedy went high, if so we need to gracefully return to IDLE
		case (ftdi_state)
			IDLE: begin
				ftdi_oe_n	<=	1;
				ftdi_wr_n	<=	1;
				ftdi_rd_n	<=	1;
				read_count	<= 	0;
				//in_fifo_data_in	<= 8'h0;

				if (~ftdi_rde_n & ~in_fifo_full) begin
					//new data from the host
//if the FIFO is not full we can read data into the FIFO, but for this first version don't worry about FIFO
					//$display ("core: new data available from the FTDI chip");
					ftdi_state		<=	READ_OE;
					ftdi_oe_n		<= 0;
					read_count		<= 32'h0;

					//reset the incomming fifo to get rid of possible erronious data
//XXX: this might not be the correct choice specificially in case the data from the user is over 512 bytes
				end
				else if (~ftdi_txe_n & ~out_fifo_empty) begin
					//$display ("core: FTDI chip is ready to be written to");
					ftdi_state		<= DELAY1;
//					ftdi_state		<= WRITE;
					out_fifo_rd		<= 1;
//					ftdi_wr_n		<= 0;

				end
			end
			READ_OE: begin
				//$display ("core: read oe");
				//need to allow for one clock cycle between the oe_n goes down and rd_n going down
				ftdi_rd_n		<= 0;
				ftdi_state		<= READ;
				in_fifo_wr		<= 1;
			end
			READ: begin
				if (ftdi_rde_n | in_fifo_full) begin
					//were done
					ftdi_state	<=	IDLE;
					ftdi_oe_n	<=	1;
					ftdi_rd_n	<=	1;
				end
				else begin
					ftdi_rd_n	<=	0;
					
				//	//$display ("core: Read %02X", ftdi_data);
					//ftdi_data is going to the write buffer
					in_fifo_wr	<= 1;
				end
//all packets should be 4 byte aligned (or 32 bits aligned)
			end
			DELAY1: begin
				ftdi_state <= WRITE;
				if (~out_fifo_empty) begin
					out_fifo_rd	<= 1;	
				end
				ftdi_wr_n	<=	0;
			end
			WRITE: begin
				//hang out till the FTDI chip is free
				$display ("Sending data: %h", ftdi_data);
				if (~ftdi_txe_n) begin
					if (~out_fifo_empty) begin
						$display ("core: continue reading");	
						ftdi_state	<= WRITE;
						ftdi_wr_n	<=	0;
						out_fifo_rd <=	1;
					end
					else begin
						$display ("core: out fifo is empty");	
						ftdi_state	<= IDLE;
					end
				end
			end
			WAIT_RD: begin
				//drain the incomming buffer
				//ftdi_rd_n	<= 0;
				ftdi_rd_n		<= 0;
				ftdi_oe_n		<= 0;
				if (ftdi_rde_n) begin
					ftdi_state	<= IDLE;
				end
			end
			default: begin
				ftdi_state	<= IDLE;
			end
		endcase
	end
end

endmodule

