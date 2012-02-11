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

reg		[7:0]		next_read_state;
reg		[7:0]		next_write_state;

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


parameter	READ_WAIT_1			=	8'h1;
parameter	READ_WAIT_2			=	8'h2;			

parameter	WRITE_ID			=	8'h1;


parameter	READ_ID				=	8'h3;

parameter	READ_CMD			=	8'h4;
parameter	PROCESS_CMD			=	8'h5;

parameter	READ_ADDR			=	8'h6;
parameter	PROCESS_ADDR		=	8'h7;
parameter	READ_DATA			=	8'h8;
parameter	READ_DATA_TO_MASTER	=	8'h9;

parameter	READ_D4				=	8'hA;
parameter	BAD_ID				=	8'hB;

parameter	WAIT_FIFO			=	8'hC;

parameter	WRITE_COMMAND		=	8'h3;
parameter	WRITE_ADDR			=	8'h4;
parameter	WRITE_DATA			=	8'h5;
parameter	WAIT_FOR_MASTER		=	8'h6;



reg [31:0]	read_count;
reg [1:0]	read_byte_count;
reg			prev_rd;


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
		next_read_state	<= 	IDLE;
		prev_rd			<=	0;
	end
	else begin
		//read should only be pulsed
		prev_rd			<=	in_fifo_rd;
		in_fifo_rd		<=	0;
		ih_ready		<=	0;
		in_fifo_rst		<=	0;

		case (read_state)
			IDLE: begin
				if (~in_fifo_empty) begin
					$display ("FT_HI: Found data in the FIFO!");
					in_fifo_rd	<= 1;
					read_state	<= READ_WAIT_2; 
					next_read_state	<= READ_ID;
				end
			end
//universal wait here
			READ_WAIT_1: begin
				if (~in_fifo_empty) begin
					read_state	<= READ_WAIT_2;
					in_fifo_rd	<= 1;
				end
			end
			READ_WAIT_2: begin
				read_state	<= next_read_state;
				if (~in_fifo_empty) begin
					if (read_byte_count != 2) begin	
						in_fifo_rd	<= 1;
					end
				end
			end
			READ_ID: begin
				//make sure the ID byte is correct
				if (in_fifo_data == 8'hCD) begin
					read_byte_count <= 0;
					if (~in_fifo_empty & prev_rd) begin
						in_fifo_rd	<= 1;
						//flow right through
						read_state <= READ_CMD;
					end
					else if (~in_fifo_empty) begin
						in_fifo_rd	<= 1;
						read_state	<= READ_WAIT_2;
					end
					else begin
						read_state	<= READ_WAIT_1;
					end
					next_read_state	<= READ_CMD;
				end
				else begin
					//incomming data is bad wait till the rde_n goes high
					$display("ID byte was not read, data is not correct");
					read_state <= BAD_ID;
				end
			end
			READ_CMD: begin
				if (read_byte_count == 0) begin
					in_command		<= {24'h0, in_fifo_data};
					in_data_count	<= 28'h0;
				end
				else begin
					in_data_count <= {in_data_count[19:0], in_fifo_data};
				end
				if (read_byte_count == 3) begin
					//done reading the command and data count
					read_state		<= PROCESS_CMD;
				end
				else begin
					if (~in_fifo_empty & prev_rd) begin
						if (read_byte_count != 2) begin	
							in_fifo_rd	<= 1;
						end
						read_state	<= READ_CMD;
					end
					else if (~in_fifo_empty) begin
						//need to wait one cycle for the data to get
						//ready
						in_fifo_rd	<= 1;
						read_state	<= READ_WAIT_2;
					end
					else begin
						//the fifo isn't even ready
						read_state		<= READ_WAIT_1;
					end
					next_read_state	<= READ_CMD;
				end
				read_byte_count 	<= read_byte_count + 1;
			end
			PROCESS_CMD: begin
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
					$display ("FT_HI: in command = %h", in_command);
					if (~in_fifo_empty) begin
						read_state <= READ_WAIT_2;
						in_fifo_rd	<= 1;
					end
					else begin
						read_state	<= READ_WAIT_1;
					end
					next_read_state	<= READ_ADDR;

					//process in data count
					read_byte_count	<= 0;

					//the first data is included in this 
					//first transmition
					if (in_data_count > 0) begin
						//for writes the first data byte is 
						//included in the first in_ready high,
						//so reduce the count by one
						read_count		<= in_data_count - 1;
						in_data_count	<= in_data_count - 1;
					end
				end
			end
			READ_ADDR: begin
				in_address		<= {in_address[23:0], in_fifo_data};
				if (read_byte_count == 3) begin
					read_byte_count <= 0;
					read_state	<= PROCESS_ADDR;
				end
				else begin
					if (~in_fifo_empty & prev_rd) begin
						if (read_byte_count != 2) begin	
							in_fifo_rd	<= 1;
						end
					end
					else if (~in_fifo_empty) begin
						in_fifo_rd	<= 1;
						read_state	<= READ_WAIT_2;
					end
					else begin
						read_state	<= READ_WAIT_1;
					end
					next_read_state	<= READ_ADDR;
				end
				read_byte_count <= read_byte_count + 1;
			end
			PROCESS_ADDR: begin
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
					if (~in_fifo_empty) begin
						read_state	 <= READ_WAIT_2;
						in_fifo_rd	<= 1;
					end
					else begin
						read_state	<= READ_WAIT_1;
					end
					next_read_state <= READ_DATA;	
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
				in_data <= {in_data[24:0], in_fifo_data};
				if (read_byte_count == 3) begin
					//send data off to the master
					if (master_ready) begin
						ih_ready <= 1;
						if (read_count > 0) begin
							read_count <= read_count - 1;
							if (~in_fifo_empty & prev_rd) begin
								if (read_byte_count != 2) begin	
									in_fifo_rd	<= 1;
								end
								read_state	<= READ_DATA;
							end
							else if (~in_fifo_empty) begin
								in_fifo_rd	<= 1;
								read_state	<= READ_WAIT_2;
							end
							else begin
								read_state	<= READ_WAIT_1;
							end
							next_read_state	<= READ_DATA;
						end
						else begin
							read_state	<= READ_D4;
						end
					end
					else begin
						read_state	<= READ_DATA_TO_MASTER;
					end
				end
				else begin
					if (~in_fifo_empty & prev_rd) begin
						in_fifo_rd	<= 1;
						read_state	<= READ_DATA;
					end
					else if (~in_fifo_empty) begin
						in_fifo_rd	<= 1;
						read_state	<= READ_WAIT_2;						
					end
					else begin
						read_state	<= READ_WAIT_1;
					end
					next_read_state	<= READ_DATA;
				end
				read_byte_count <= read_byte_count + 1;
				//need to send off the data to the master when the master
				//is ready for it
			end
			READ_DATA_TO_MASTER: begin
				if (master_ready) begin
					$display ("FT_HI: sending data to master");
					ih_ready <= 1;
					read_byte_count <= 0;
					if (read_count > 0) begin
						read_count <= read_count - 1;
						if (~in_fifo_empty) begin
							in_fifo_rd	<= 1;
							read_state	<= READ_WAIT_2;
						end
						else begin
							read_state <= READ_WAIT_1;
						end
						next_read_state	<= READ_DATA;
					end
					else begin
						//DONE!
						read_state <= READ_D4;
						in_fifo_rst	<= 1;
					end
				end
			end
			READ_D4: begin
				in_fifo_rst	<= 1;
				if (ftdi_rde_n) begin
					read_state		<=	IDLE;
				end	
			end
			BAD_ID: begin
				in_fifo_rst	<= 1;
				//need to wait unilt the rde_n goes low
				$display ("FT_HI: BAD ID, I should send a response to the host that something went wrong here"); 
				read_state	<=	READ_D4;
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

reg	[31:0]	local_status;
reg [31:0]	local_address;
reg	[31:0]	local_data_count;
reg	[31:0]	local_data;


always @ (posedge clk) begin
	if (rst) begin
		oh_ready			<=	0;
		write_count			<=	0;
		write_byte_count	<=	0;
		out_fifo_wr			<=	0;
		next_write_state	<=	0;

		local_status		<=	0;
		local_address		<=	0;
		local_data_count	<=	0;
		local_data			<=	0;

	end
	else begin
		out_fifo_wr			<= 	0;
		case (write_state)
			IDLE: begin
				oh_ready	<= 1;
				if (oh_en) begin
					oh_ready	<= 0;

					$display ("FT_OH: Send the identification byte");
					out_fifo_data	<= 8'hDC;
					write_byte_count <= 0;
					
					$display ("FT_OH: Master sending data");
					$display ("FT_OH: out_status: %h", out_status[7:0]);
					//tell the master to kick back for a sec
					write_count	<= out_data_count;
	//				out_fifo_data	<= {out_status[7:0], out_data_count[23:0]};
					local_status		<= out_status;
					local_address		<= out_address;
					local_data_count	<= out_data_count;
					local_data			<= out_data;

					write_state	<= WRITE_ID;

				end
			end
			WRITE_ID: begin
				if (~out_fifo_full)	begin
					out_fifo_wr	<= 1;
					write_state	<= WRITE_COMMAND;
					write_byte_count	<= 0;
				end
			end
			WRITE_COMMAND: begin
				if (~out_fifo_full) begin
					out_fifo_data	<= local_status[31:24];
					local_status	<= {local_status[23:0], 8'h0};
					out_fifo_wr 	<= 1;
					if (write_byte_count == 3) begin
						if (out_status[3:0] == 4'hF) begin
							write_state <= IDLE;
						end
						else begin
							write_state <= WRITE_ADDR;
						end
					end
					//the write byte count should roll over to 0
					write_byte_count <= write_byte_count + 1;
				end
			end
			WRITE_ADDR: begin
				if (~out_fifo_full) begin
					out_fifo_data	<= local_address[31:24];
					local_address	<= {local_address[23:0], 8'h0};
					out_fifo_wr		<= 1;
					if (write_byte_count == 3) begin
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
				end
			end
			WRITE_DATA: begin
				if (~out_fifo_full) begin
					out_fifo_wr		<= 1;
					out_fifo_data	<= local_data[31:24];
					local_data	<= {local_data[23:0], 8'h0};
					if (write_byte_count == 3) begin
						oh_ready <= 1;
						if (write_count > 0) begin
							write_count <= write_count - 1;
							write_state <= WAIT_FOR_MASTER;
						end
						else begin
							write_state	<= IDLE;
						end
					end
					write_byte_count <= write_byte_count + 1;
				end
			end
			WAIT_FOR_MASTER: begin
				oh_ready <= 1;
				if (oh_en) begin
					//another 32 bit word to read
					write_state	<= WRITE_DATA;
					write_byte_count <= 0;
					oh_ready <= 0;
					local_data	<= out_data;
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
