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
output	[31:0]		in_fifo_data;

//out fifo
input				out_fifo_wr;
output				out_fifo_full;
input	[31:0]		out_fifo_data;


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



reg		[7:0]		data_out;

assign ftdi_data	=	(ftdi_oe_n) ? data_out:8'hZ;

wire	[31:0]		ft_data_out;


//wires

reg					in_command_ready;

reg		[31:0]		in_fifo_data_in;
reg					in_fifo_wr;
wire				in_fifo_full;


wire 			out_fifo_full;
wire	[31:0]	out_fifo_data_out;
wire			out_fifo_empty;
reg				out_fifo_rd;
wire			out_fifo_wr;

//data that will be read from the FTDI chip (in)
afifo 
	#(		.DATA_WIDTH(32),
			.ADDRESS_WIDTH(9)
	)
fifo_in (
	.rst(in_fifo_rst),

	.din_clk(ftdi_clk),
	.dout_clk(clk),

	.data_in(in_fifo_data_in),
	.data_out(in_fifo_data),
	.full(in_fifo_full),
	.empty(in_fifo_empty),

	.wr_en(in_fifo_wr),
	.rd_en(in_fifo_rd)

);
//data that will be sent to the FTDI chip (out)
afifo 
	#(		.DATA_WIDTH(32),
			.ADDRESS_WIDTH(9)
	)
	fifo_out (
	.rst(rst),

	.din_clk(clk),	
	.dout_clk(ftdi_clk),

	.data_in(out_fifo_data),
	.data_out(out_fifo_data_out),
	.full(out_fifo_full),
	.empty(out_fifo_empty),

	.wr_en(out_fifo_wr),
	.rd_en(out_fifo_rd)
);


parameter	IDLE	=	4'h0;
parameter	READ_OE	=	4'h1;
parameter	READ	=	4'h2;
parameter	DELAY1	=	4'h3;
parameter	WRITE0	=	4'h4;
parameter	WRITE1	=	4'h5;
parameter	WRITE2	=	4'h6;
parameter	WRITE3	=	4'h7;
parameter	WAIT_RD	=	4'h8;

reg	[3:0]	ftdi_state;	

reg	[31:0]	read_count;

always @ (posedge ftdi_clk) begin
	
	if (rst) begin
		data_out		<=	8'h0;
		ftdi_wr_n		<=	1;
		ftdi_rd_n		<=	1;
		ftdi_oe_n		<=	1;
		ftdi_state		<= 	IDLE;
		ftdi_siwu		<=	1;

		read_count		<=	0;

		in_fifo_data_in	<=	32'h0;
		in_fifo_wr		<=	0;
		out_fifo_rd		<=	0;


		
	end
	else begin
		//pulses 
		in_fifo_wr		<= 0;
		out_fifo_rd		<= 0;

//check if the txe_n or rxe_n unexpectedy went high, if so we need to gracefully return to IDLE
		case (ftdi_state)
			IDLE: begin
				ftdi_oe_n	<=	1;
				ftdi_wr_n	<=	1;
				ftdi_rd_n	<=	1;
				data_out	<=	8'h0;
				read_count	<= 	0;
				in_fifo_data_in	<= 32'h0;

				if (~ftdi_rde_n) begin
					//new data from the host
//if the FIFO is not full we can read data into the FIFO, but for this first version don't worry about FIFO
					$display ("core: new data available from the FTDI chip");
					ftdi_state		<=	READ_OE;
					ftdi_oe_n		<= 0;
					read_count		<= 32'h0;

					//reset the incomming fifo to get rid of possible erronious data
//XXX: this might not be the correct choice specificially in case the data from the user is over 512 bytes
				end
				else if (~ftdi_txe_n & ~out_fifo_empty) begin
					$display ("core: FTDI chip is ready to be written to");
					ftdi_state		<= DELAY1;
					out_fifo_rd		<= 1;
//					ftdi_wr_n		<= 0;

//I might need to setup the first byte in here
				end
			end
			READ_OE: begin
				$display ("core: read oe");
				//need to allow for one clock cycle between the oe_n goes down and rd_n going down
				ftdi_rd_n		<= 0;
				ftdi_state		<= READ;
			end
			READ: begin
				//need to constantly check to see if the FIFO is empty, if so raise the RD	
//might need to hold the next byte in a temporary buffer cause the FIFO might be one step behind
				if (ftdi_rde_n) begin
//if this is a command that doesn't require address and/or data, then we might have to enable the ih_ready from here
//for example PING or READ
					//were done
					ftdi_state	<=	IDLE;
					ftdi_oe_n	<=	1;
					ftdi_rd_n	<=	1;
				end
				else begin
//					$display ("core: Read %02X, count = %d", ftdi_data, read_count);

					in_fifo_data_in	<= {in_fifo_data_in[24:0], ftdi_data};
					if ((read_count & 31'h00000003) == 3) begin
//							$display ("core: new data, send this off to the FIFO");
							in_fifo_wr	<= 1;
							//tell the host we are ready

					end
					read_count <= read_count + 1;


//XXX: if the rxe_n went high it doesn't mean that I should should return to IDLE there might be a gap in the data, I should
// code for this contingency... this does lead to the possiblity that there might be a misalignment of data... maybe all
//continuing packet should have one header 32 bit to indicate that this is a continuing packet... or simply just a byte

				end
//all packets should be 4 byte aligned (or 32 bits aligned)
			end
			DELAY1: begin
				ftdi_state	<= WRITE0;
			end
			WRITE0: begin
				//$display ("core: sending: %h", out_fifo_data_out[31:24]);
				data_out	<= out_fifo_data_out[31:24];
				//hang out till the FTDI chip is free
				if (~ftdi_txe_n) begin
					//were done
					out_fifo_rd <= 1;
					ftdi_wr_n	<=	0;
					ftdi_state	<=	WRITE1;
				end
				else begin
					$display ("host is full");	
				end
			end
			WRITE1: begin
				//$display ("core: sending: %h", out_fifo_data_out[23:16]);
				data_out	<= out_fifo_data_out[23:16];
				if (~ftdi_txe_n) begin
					ftdi_wr_n	<= 0;
					ftdi_state	<= WRITE2;
				end
				else begin
					$display ("host is full");
				end

			end
			WRITE2: begin
				//$display ("core: sending: %h", out_fifo_data_out[15:8]);
				data_out	<= out_fifo_data_out[15:8];
				if (~ftdi_txe_n) begin
					ftdi_wr_n	<= 0;
					ftdi_state	<= WRITE3;
				end
				else begin
					$display ("host is full");
				end

			end
			WRITE3: begin
				//$display ("core: sending: %h", out_fifo_data_out[7:0]);
				data_out	<= out_fifo_data_out[7:0];
				if (~ftdi_txe_n) begin
					ftdi_wr_n	<= 0;
					ftdi_state	<= IDLE;
				end
				else begin
					$display ("host is full");
				end
			end
			WAIT_RD: begin
				//drain the incomming buffer
				//ftdi_rd_n	<= 0;
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

