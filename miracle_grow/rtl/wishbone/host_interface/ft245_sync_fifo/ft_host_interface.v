//ft_host_interface.v

module ft_host_interface (
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
	ftdi_siwu,
	ftdi_suspend_n

);


//host interface
input				rst;
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



//ftdi
input				ftdi_clk;
inout	[7:0]		ftdi_data;
input				ftdi_txe_n;
output				ftdi_wr_n;
input				ftdi_rde_n;
output 				ftdi_rd_n;
output 				ftdi_oe_n;
output 				ftdi_siwu;
input				ftdi_suspend_n;



//fifo interface
wire				fifo_rst;
reg					in_fifo_rst;
assign	fifo_rst	=	rst | in_fifo_rst;

reg					in_fifo_rd;
wire				in_fifo_empty;
wire	[7:0]		in_fifo_data;

reg					out_fifo_wr;
wire				out_fifo_full;	
reg		[7:0]		out_fifo_data;

//instantiate the ft245_sync core
ft245_sync_fifo sync_fifo(
	.clk(clk),
	.rst(rst),

	.in_fifo_rst(fifo_rst),
	.in_fifo_rd(in_fifo_rd),
	.in_fifo_empty(in_fifo_empty),
	.in_fifo_data(in_fifo_data),

	.out_fifo_wr(out_fifo_wr),
	.out_fifo_full(out_fifo_full),
	.out_fifo_data(out_fifo_data),

	.ftdi_clk(ftdi_clk),
	.ftdi_data(ftdi_data),
	.ftdi_txe_n(ftdi_txe_n),
	.ftdi_wr_n(ftdi_wr_n),
	.ftdi_rde_n(ftdi_rde_n),
	.ftdi_rd_n(ftdi_rd_n),
	.ftdi_oe_n(ftdi_oe_n),
	.ftdi_siwu(ftdi_siwu),
	.ftdi_suspend_n(ftdi_suspend_n)

);
parameter	IDLE				=	8'h0;

parameter	READ_D0				=	8'h1;
parameter	READ_ID				=	8'h2;

parameter	READ_D1				=	8'h3;
parameter	READ_CMD			=	8'h4;

parameter	READ_D2				=	8'h5;
parameter	READ_ADDR			=	8'h6;

parameter	READ_D3				=	8'h7;
parameter	READ_DATA			=	8'h8;
parameter	READ_DATA_TO_MASTER	=	8'h9;

parameter	READ_D4				=	8'hA;
parameter	BAD_ID				=	8'hB;

parameter	WAIT_FIFO			=	8'hC;

parameter	WRITE_COMMAND		=	8'hD;
parameter	WRITE_ADDR			=	8'hE;
parameter	WRITE_DATA			=	8'hF;
parameter	WAIT_FOR_MASTER		=	8'h10;



reg [31:0]	read_count;
reg [1:0]	read_byte_count;


reg	[7:0]	read_state	=	IDLE;
reg	[7:0]	write_state	=	IDLE;

//input handler
always @ (posedge clk) begin
	if (rst) begin
		$display ("FT_HI: in reset");
		in_command		<=	32'h0;
		in_address		<=	32'h0;
		in_data			<=	32'h0;
		in_data_count	<= 	32'h0;
	
		ih_ready		<=	0;
		read_count		<=	0;
		read_state		<=	IDLE;
		in_fifo_rd		<= 	0;
		in_fifo_rst		<=	1;

		read_byte_count	<=	0;
	end
	else begin
		//read should only be pulsed
		in_fifo_rd		<=	0;
		ih_ready		<=	0;
		in_fifo_rst		<=	0;

		case (read_state)
			IDLE: begin
				if (~in_fifo_empty) begin
					$display ("FT_HI: Found data in the FIFO!");
					read_state	<= READ_D0; 
					in_fifo_rd	<= 1;
				end
			end
			READ_D0: begin
				read_state	<= READ_ID;
			end
			READ_ID: begin

				//make sure the ID byte is correct
				if (in_fifo_data == 8'hCD) begin
					read_state <= READ_D1;
					read_byte_count <= 0;
					in_fifo_rd	<= 1;
				end
				else begin
					//incomming data is bad wait till the rde_n goes high
					$display("ID byte was not read, data is not correct");
					read_state <= BAD_ID;
				end
			end
			READ_D1: begin
				if (~in_fifo_empty && in_fifo_rd) begin
					read_state	<= READ_CMD;	
				end
				else if (~in_fifo_empty) begin
					in_fifo_rd	<= 1;
				end
			end
			READ_CMD: begin
				if (read_byte_count == 0) begin
					in_command		<= {24'h0, in_fifo_data};
					in_data_count	<= 28'h0;
				end
				else begin
					in_data_count <= {in_data_count[27:8], in_fifo_data};
				end
				if (read_byte_count < 3) begin
					read_byte_count 	<= read_byte_count + 1;
					if (~in_fifo_empty) begin
						in_fifo_rd	<= 1;
					end
					else begin
						read_state	<= READ_D1;
					end
				end
				else begin
					read_state		<= READ_D2;
					read_byte_count	<= 0;
				end
			end
			READ_D2: begin
				if (in_command == 0) begin
					$display ("FT_HI: in command = %h", in_command);
					$display ("FT_HI: data count = %d", in_data_count);
					if (master_ready) begin
						$display ("PING");
						ih_ready	<= 1;
						read_state	<= READ_D4;
						in_fifo_rst	<= 1;
					end
				end
				else begin
					$display ("FT_HI: in command = %h", in_fifo_data);
					if (~in_fifo_empty && in_fifo_rd) begin
						read_state <= READ_ADDR;
					end
					else if (~in_fifo_empty) begin
						if (read_byte_count == 0) begin
							//the first data is included in this first transmition
							read_count		<= in_data_count;
							if (in_fifo_data > 0) begin
								//for writes the first data byte is included in the first in_ready high, so reduce the count by one
								in_data_count	<= in_data_count - 1;
							end
						end
						in_fifo_rd	<= 	1;
					end
				end
			end
			READ_ADDR: begin
				in_address		<= {in_address[31:8], in_fifo_data};
				if (read_byte_count == 3) begin
					read_byte_count <= 0;
					read_state	<= READ_D3;
				end
				else begin
					if (in_fifo_empty) begin
						$display ("FT_HI: In FIFO empty, wait for more data to come in");
						read_state	<= READ_D2;
					end
					else begin
						in_fifo_rd	<= 1;
					end
					read_byte_count <= read_byte_count + 1;
				end
			end
			READ_D3: begin
				if (in_command[3:0] == 2) begin
					$display ("FT_HI: Read command");
					//read
					//this is all the data we need
					if (master_ready) begin
						$display ("FT_HI: in address = %h", in_address);
						ih_ready	<= 1;
						read_state	<= READ_D4;
						in_fifo_rst	<= 1;
					end
				end
				else if (in_command[3:0] == 1) begin
					$display ("FT_HI: Write command");
					//write
					if (read_count > 0) begin
						if (~in_fifo_empty && in_fifo_rd) begin
							read_state	<= READ_DATA;
						end
						else if (~in_fifo_empty) begin
							in_fifo_rd	<= 1;
						end
					end
				end
				else begin
					//don't know this command
					$display ("FT_HI: Error unknown command!: %h", in_command[3:0]);
					$display ("FT_HI: maybe send a notification to the host that something is wrong");
//XXX: RESET THE FIFO!
					read_state	<= READ_D4;
					in_fifo_rst <= 1;

				end

			end
			READ_DATA: begin

//if the read_count == in_data_count + 1 then we are sending the first byte
				in_data <= {in_data[31:8], in_fifo_data};
				if (read_byte_count == 3) begin
					//send data off to the master
					read_state	<= READ_DATA_TO_MASTER;
					read_count	<= read_count - 1;
				end
				else begin
					if (in_fifo_empty) begin
						$display ("FT_HI: In FIFO empty, wait for more data to come in");
						read_state	<= READ_D3;
					end
					else begin
						in_fifo_rd	<= 1;
					end
					read_byte_count <= read_byte_count + 1;

				end
				//need to send off the data to the master when the master
				//is ready for it
			end
			READ_DATA_TO_MASTER: begin
				if (master_ready) begin
					$display ("FT_HI: sending data to master");
					ih_ready <= 1;
					read_byte_count <= 0;
					if (read_count > 0) begin
						read_state <= READ_D3;
					end
					else begin
						read_state <= READ_D4;
						in_fifo_rst	<= 1;
					end
				end
			end
			READ_D4: begin
				read_state		<= IDLE;
			end
			BAD_ID: begin
				//need to wait unilt the rde_n goes low
				if (~ftdi_rde_n) begin
					in_fifo_rst	<= 1;
					$display ("FT_HI: BAD ID, I should send a response to the host that something went wrong here"); 
				end
			end
			default: begin
				$display ("FT_HI: How did we get here!?");
				read_state	<= IDLE;
			end

		endcase
		
	end
end


//output handler
reg	[31:0]	write_count;

reg [1:0]	write_byte_count;

always @ (posedge clk) begin
	if (rst) begin
		oh_ready			<=	0;
		write_count			<=	0;
		write_byte_count	<= 0;
		out_fifo_wr			<=	0;
	end
	else begin
		out_fifo_wr			<= 	0;
		case (write_state)
			IDLE: begin
				oh_ready	<= 1;
				if (oh_en) begin
					$display ("FT_OH: Send the identification byte");
					out_fifo_data	<= 8'hDC;
					write_byte_count <= 0;
					
					$display ("FT_OH: Master sending data");
					$display ("FT_OH: out_status: %h", out_status[7:0]);
					//tell the master to kick back for a sec
					write_count	<= out_data_count;
	//				out_fifo_data	<= {out_status[7:0], out_data_count[23:0]};
					if (~out_fifo_full) begin
						oh_ready	<= 0;
						//ready to progress
						//put the data into the FIFO	
						out_fifo_wr	<= 1;
						write_state	<= WRITE_COMMAND;
					end
				end
			end
			WRITE_COMMAND: begin
				if (~out_fifo_full) begin
					if (write_byte_count == 0) begin
						out_fifo_data <= out_status[31:24];
					end
					else if (write_byte_count == 1) begin
						out_fifo_data <= out_status[23:16];
					end
					else if (write_byte_count == 2) begin
						out_fifo_data <= out_status[15:8];
					end
					else begin
						out_fifo_data <= out_status[7:0];
						if (out_status[3:0] == 4'hF) begin
							write_state <= IDLE;
						end
						else begin
							write_state <= WRITE_ADDR;
						end
						//the write byte count should roll over to 0
					end
					write_byte_count <= write_byte_count + 1;
					out_fifo_wr <= 1;
				end
			end
			WRITE_ADDR: begin
				if (~out_fifo_full) begin
					if (write_byte_count == 0) begin
						out_fifo_data <= out_address[31:24];
					end
					else if (write_byte_count == 1) begin
						out_fifo_data <= out_address[23:16];
					end
					else if (write_byte_count == 2) begin
						out_fifo_data <= out_address[15:8];
					end
					else begin
						out_fifo_data <= out_address[7:0];
						if (out_status[3:0] == 4'hD) begin
							//write
							write_state		<= WRITE_DATA;
						end
						else begin
							//read
							write_state	<= IDLE;
						end
					end
					write_byte_count <=	write_byte_count + 1;
					out_fifo_wr		<= 1;
				end
			end
			WRITE_DATA: begin
				if (~out_fifo_full) begin
					if (write_byte_count == 0) begin
						out_fifo_data <= out_data[31:24];
					end
					else if (write_byte_count == 1) begin
						out_fifo_data <= out_data[23:16];
					end
					else if (write_byte_count == 2) begin
						out_fifo_data <= out_data[15:8];
					end
					else begin
						out_fifo_data <= out_data[7:0];

						oh_ready <= 1;
						if (write_count > 0) begin
							write_count <= write_count - 1;
							write_state <= WAIT_FOR_MASTER;
						end
						else begin
							write_state	<= IDLE;
						end
					end
					out_fifo_wr		<= 1;
				end
			end
			WAIT_FOR_MASTER: begin
				oh_ready <= 1;
				if (oh_en) begin
					//another 32 bit word to read
					write_state	<= WRITE_DATA;
					write_byte_count <= 0;
					oh_ready <= 0;
				end
				//probably need a timeout
			end
			default: begin
				write_state	<= IDLE;
			end
		endcase
	end
end


endmodule
