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
	ftdi_siwu
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



//fifo interface
wire				fifo_rst;
reg					in_fifo_rst;
assign	fifo_rst	=	rst | in_fifo_rst;

reg					in_fifo_rd;
wire				in_fifo_empty;
wire	[31:0]		in_fifo_data;

reg					out_fifo_wr;
wire				out_fifo_full;	
reg		[31:0]		out_fifo_data;

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
	.ftdi_siwu(ftdi_siwu)

);
parameter	IDLE		=	4'h0;

parameter	READ_D1		=	4'h1;
parameter	READ_CMD	=	4'h2;

parameter	READ_D2		=	4'h3;
parameter	READ_ADDR	=	4'h4;

parameter	READ_D3		=	4'h5;
parameter	READ_DATA	=	4'h6;

parameter	READ_D4		=	4'h7;

parameter	WAIT_FIFO	=	4'h8;

parameter	WRITE_ADDR	=	4'h9;
parameter	WRITE_DATA	=	4'hA;
parameter	WAIT_FOR_MASTER	=	4'hB;



reg [31:0]	read_count;


reg	[3:0]	read_state	=	IDLE;
reg	[3:0]	write_state	=	IDLE;

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
					read_state	<= READ_D1; in_fifo_rd	<= 1;
				end
			end
			READ_D1: begin
				read_state	<= READ_CMD;
			end
			READ_CMD: begin
				in_command		<= {24'h0, in_fifo_data[31:24]};
				in_data_count	<= {4'h0, in_fifo_data[23:0]};
				read_count		<= {8'h0, in_fifo_data[23:0]};
				if (in_fifo_data[27:24] == 0) begin
					$display ("FT_HI: in command = %h", in_fifo_data[31:24]);
					$display ("FT_HI: data count = %d", in_fifo_data[23:0]);
					if (master_ready) begin
						$display ("PING");
						ih_ready	<= 1;
						read_state	<= READ_D4;
						in_fifo_rst	<= 1;
					end
				end
				else begin
					$display ("FT_HI: in command = %h", in_fifo_data);
					if (~in_fifo_empty) begin
						read_state	<=	READ_D2;
						in_fifo_rd	<= 	1;
					end
				end
			end
			READ_D2: begin
				read_state	<= READ_ADDR;
			end
			READ_ADDR: begin
				in_address		<= in_fifo_data;
				if (in_command[3:0] == 2) begin
					$display ("FT_HI: Read command");
					//read
					//this is all the data we need
					$display ("FT_HI: in address = %h", in_fifo_data);
					if (master_ready) begin
						ih_ready	<= 1;
						read_state	<= READ_D4;
						in_fifo_rst	<= 1;
					end
				end
				else if (in_command[3:0] == 1) begin
					//write
					if (master_ready) begin
						if (read_count > 0) begin
//							$display ("FT_HI: in write command");
							if (~in_fifo_empty) begin
								$display ("FT_HI: Write command");
								$display ("FT_HI: in address = %h", in_fifo_data);
								read_count	<= read_count - 1;
								read_state	<= READ_D3;
								in_fifo_rd	<= 1;
							end
						end
						else begin
							$display ("this is a strange read.. the count of data is zero!");
							read_state	<= READ_D4;
							in_fifo_rst	<= 1;
						end
					end
				end
				else begin
					//don't know this command
					$display ("FT_HI: Error unknown command!: %h", in_command[3:0]);

//XXX: RESET THE FIFO!
					read_state	<= READ_D4;

				end
			end
			READ_D3: begin
				read_state	<= READ_DATA;
			end
			READ_DATA: begin
				//need to send off the data to the master when the master
				//is ready for it
				in_data	<= in_fifo_data;
				if (master_ready) begin
					$display ("FT_HI: sending data to master");
					$display ("FT_HI: data count: %d", read_count);
					ih_ready	<= 1;
					if (read_count > 0) begin
						read_count	<= read_count - 1;
						read_state	<= WAIT_FIFO;
					end
					else begin
						$display ("FT_HI: Sent all write data to master");
						read_state	<= READ_D4;
						in_fifo_rst	<= 1;
					end
				end
			end
			WAIT_FIFO: begin
				if (~in_fifo_empty) begin
					in_fifo_rd	<= 1;
					read_state	<= READ_D3;
				end
			end
			READ_D4: begin
				read_state		<= IDLE;
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

always @ (posedge clk) begin
	if (rst) begin
		oh_ready		<=	0;
		write_count		<=	0;
		out_fifo_wr		<=	0;
	end
	else begin
		out_fifo_wr		<= 	0;
		case (write_state)
			IDLE: begin
				oh_ready	<= 1;
				if (oh_en) begin
					$display ("FT_OH: Master sending data");
					$display ("FT_OH: out_status: %h", out_status[7:0]);
					//tell the master to kick back for a sec
					write_count	<= out_data_count;
					out_fifo_data	<= {out_status[7:0], out_data_count[23:0]};
					if (~out_fifo_full) begin
						oh_ready	<= 0;
						//ready to progress
						//put the data into the FIFO	
						out_fifo_wr	<= 1;
						if ((out_status[7:0]) == 8'hFF) begin
							$display ("FT_OH: Ping response");
						end
						else begin
							write_state	<= WRITE_ADDR;
						end

					end
				end
			end
			WRITE_ADDR: begin
				if (~out_fifo_full) begin
					out_fifo_wr		<= 1;
					out_fifo_data	<=	out_address;
					if (write_count > 0) begin
						write_count 	<= write_count - 1;
						write_state		<= WRITE_DATA;
					end
					else begin
						write_state		<= IDLE;	
					end
				end
			end
			WRITE_DATA: begin
				if (~out_fifo_full) begin
					out_fifo_wr		<= 1;
					out_fifo_data	<= out_data;
					oh_ready		<= 1;
					if (write_count > 0) begin
						write_state		<= WAIT_FOR_MASTER;
						write_count		<= write_count	- 1;
					end
					else begin
						write_state		<= IDLE;
					end
				end
			end
			WAIT_FOR_MASTER: begin
				//wait for master to raise oh_en
				oh_ready	<= 1;
				if (oh_en) begin
					oh_ready		<= 0;
					write_state		<= WRITE_DATA;
				end
			end
			default: begin
			end
		endcase
	end
end


endmodule
