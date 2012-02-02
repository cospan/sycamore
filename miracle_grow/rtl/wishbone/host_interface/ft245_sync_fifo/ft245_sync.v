//ft245_sync_fifo.v


module ft245_sync_fifo (
	rst,
	clk,

	//host interface
	master_ready,
	ih_ready,

	in_command,
	in_address,
	in_data_count,
	in_data,


	//outgoing data
	oh_ready,
	oh_en,

	out_status,
	out_address,
	out_data_count,
	out_data,


	//phy interface
	ftdi_clk,
	ftdi_data,
	ftdi_txe_n,
	ftdi_wr_n,
	ftdi_rde_n,
	ftdi_rd_n,
	ftdi_oe_n,
	ftdi_siwu


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
input				clk;

input				master_ready;
output reg			ih_ready;

output reg	[31:0]	in_command;
output reg	[27:0]	in_data_count;
output reg	[31:0]	in_address;
output reg	[31:0]	in_data;

output reg			oh_ready;
input				oh_en;

input		[31:0]	out_status;
input		[31:0]	out_address;
input		[27:0]	out_data_count;
input		[31:0]	out_data;





reg		[7:0]		data_out;

assign ftdi_data	=	(ftdi_oe_n) ? data_out:8'hZ;

wire	[31:0]		ft_data_out;

//wires

reg					in_command_ready;

reg		[31:0]		in_fifo_data_in;
reg					in_fifo_rd;
wire				in_fifo_empty;

wire	[31:0]		in_fifo_data_out;
reg					in_fifo_wr;
wire				in_fifo_full;


reg					in_fifo_rst;

reg				out_fifo_rst;
wire 			out_fifo_full;
wire	[31:0]	out_fifo_data_out;
wire			out_fifo_empty;
wire			out_fifo_rd;
wire			out_fifo_wr;

//data that will be read from the FTDI chip (in)
afifo 
	#(		.DATA_WIDTH(32),
			.ADDRESS_WIDTH(9)
	)
fifo_in (
	.rst(out_fifo_rst),

	.din_clk(ftdi_clk),
	.dout_clk(clk),

	.data_in(in_fifo_data_in),
	.data_out(in_fifo_data_out),
	.full(out_fifo_full),
	.empty(out_fifo_empty),

	.wr_en(in_fifo_wr),
	.rd_en(ftdi_in_rd)

);
//data that will be sent to the FTDI chip (out)
afifo 
	#(		.DATA_WIDTH(32),
			.ADDRESS_WIDTH(9)
	)
	fifo_out (
	.rst(out_fifo_rst),

	.din_clk(clk),	
	.dout_clk(ftdi_clk),

	.data_in(out_fifo_data_out),
	.data_out(out_fifo_data_out),
	.full(out_fifo_full),
	.empty(out_fifo_empty),

	.wr_en(out_fifo_wr),
	.rd_en(out_fifo_rd)
);


parameter	IDLE	=	4'h0;
parameter	READ_OE	=	4'h1;
parameter	READ	=	4'h2;
parameter	WRITE	=	4'h3;
parameter	WRITE_ST=	4'h4;

reg	[3:0]	ftdi_state;	

reg	[31:0]	read_count;

always @ (posedge ftdi_clk) begin
	

	if (rst) begin
		data_out		<=	8'h0;
		ftdi_wr_n		<=	1;
		ftdi_rd_n		<=	1;
		ftdi_oe_n		<=	1;

		ftdi_state		<= 	IDLE;

		read_count		<=	0;

		in_command		<=	32'h0;
		in_address		<=	32'h0;
		in_fifo_data_in	<=	32'h0;
		in_fifo_rst		<=	1;
		out_fifo_rst	<= 	1;
		in_fifo_wr		<=	0;
		
	end
	else begin
		//pulses 
		if (in_fifo_rst) begin
			in_fifo_rst <= 0;
		end
		if (in_fifo_wr) begin
			in_fifo_wr	<= 0;
		end

		if (out_fifo_rst) begin
			out_fifo_rst <= 0;
		end 




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
					in_command		<= 32'h0;
					in_address		<= 32'h0;
					read_count		<= 32'h0;
					in_data_count	<= 28'h0;

					//reset the incomming fifo to get rid of possible erronious data
//XXX: this might not be the correct choice specificially in case the data from the user is over 512 bytes
					in_fifo_rst	<= 1;
				end
				else if (~ftdi_txe_n) begin
					$display ("core: FTDI chip is ready to be written to");
					ftdi_state		<= WRITE;
					ftdi_wr_n		<= 0;
					out_fifo_rst	<= 1;
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
					$display ("core: in_command: %h", in_command);
					$display ("core: in_address: %h", in_address);
					$display ("core: read_data: %h", in_fifo_data_in);
					$display ("core: read_count: %h", in_data_count);
					//were done
					ftdi_state	<=	IDLE;
					ftdi_oe_n	<=	1;
					ftdi_rd_n	<=	1;
				end
				else begin
					$display ("core: Read %02X, count = %d", ftdi_data, read_count);
					if (read_count == 0) begin
						in_command <= ftdi_data;
					end
					else if (read_count >=1 && read_count < 4) begin
						//reading command
						in_data_count <= {in_data_count[19:0], ftdi_data}; 
					end
					else if (read_count >= 4 && read_count < 8) begin
						//reading address
						in_address <= {in_address[24:0], ftdi_data}; 
					end
					else begin
						//reading data
						in_fifo_data_in	<= {in_fifo_data_in[24:0], ftdi_data};
						if ((read_count & 31'h00000003) == 3) begin
							$display ("core: new data, send this off to the FIFO");
							in_fifo_wr	<= 1;
							//tell the host we are ready

						end
					end
					read_count = read_count + 1;


//XXX: if the rxe_n went high it doesn't mean that I should should return to IDLE there might be a gap in the data, I should
// code for this contingency... this does lead to the possiblity that there might be a misalignment of data... maybe all
//continuing packet should have one header 32 bit to indicate that this is a continuing packet... or simply just a byte

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


//host clock domain
always @ (posedge clk) begin
	if (rst) begin
		//reset
		ih_ready	<= 0;
		oh_ready	<= 0;
	end
	else begin
		//check if there is an incomming command that we should prep the master for
		//check if we need to pull data out of the incomming FIFO


		//writing
		//for the most part I am simply putting data into the output fifo and telling the other block to send it out
		//check if the master wants to send data to the host
		//check if the master wants to put more data 

	end
end





endmodule

