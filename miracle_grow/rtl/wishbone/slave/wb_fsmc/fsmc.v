

module fsmc_module (
	clk,
	rst,

	//fsmc
	fsmc_adr,
	fsmc_dat,
	fsmc_ce_n,
	fsmc_we_n,
	fsmc_oe_n,
	fsmc_ub_n,
	fsmc_lb_n,

	//data
	received,
	transmitted,
	transmit_request,
	transmit_ready,
	upper_word,
	rx_data,
	tx_data
);

//ports
input				clk;
input				rst;

input	[15:0]		fsmc_adr;
inout	[15:0]		fsmc_dat;
input				fsmc_ce_n;
input				fsmc_we_n;
input				fsmc_oe_n;
input				fsmc_ub_n;
input				fsmc_lb_n;


output	reg			received;
output	reg			transmitted;
output	reg			transmit_request;
input				transmit_ready;
output	reg	[31:0]	rx_data;
input		[31:0]	tx_data;
output	reg			upper_word;


//states
parameter		FSMC_IDLE 		= 	0;
parameter		FSMC_GETADDR 	= 	1;
parameter		FSMC_READ		=	2;
parameter		FSMC_WRITE		=	3;
parameter		FSMC_FINISH		=	4;


//registers

reg	[7:0]		fsmc_state;
reg				fsmc_data_out_en;
reg [15:0]		fsmc_dat_o;
wire [15:0]		fsmc_dat_i;


assign	fsmc_dat	=	(fsmc_data_out_en) ? fsmc_dat_o: 16'hZ;
assign	fsmc_dat_i	=	fsmc_dat;

//localize FSMC data

reg	[15:0]	lfsmc_adr;
reg	[15:0]	lfsmc_dat_i;
reg			lfsmc_ce_n;
reg			lfsmc_we_n;
reg			lfsmc_oe_n;
reg			lfsmc_ub_n;
reg			lfsmc_lb_n;

always @ (posedge clk) begin
	if (rst) begin
		lfsmc_adr	<= 16'h0;
		lfsmc_dat_i	<= 16'h0;
		lfsmc_ce_n	<= 1;
		lfsmc_we_n	<= 1;
		lfsmc_oe_n	<= 1;
		lfsmc_ub_n	<= 1;
		lfsmc_lb_n	<= 1;
	end
	else begin
		lfsmc_adr	<= fsmc_adr;
		lfsmc_dat_i	<= fsmc_dat_i;
		lfsmc_ce_n	<= fsmc_ce_n;
		lfsmc_we_n	<= fsmc_we_n;
		lfsmc_oe_n	<= fsmc_oe_n;
		lfsmc_ub_n	<= fsmc_ub_n;
		lfsmc_lb_n	<= fsmc_lb_n;
	end
end



//Syncronous logic
always @ (posedge clk) begin
	if (received) begin
		received			<= 0;
	end
	if (transmitted) begin
		transmitted			<= 0;
	end
	if (transmit_request) begin
		transmit_request	<= 0;
	end

	if (rst) begin
		fsmc_state			<= FSMC_IDLE;
		fsmc_data_out_en	<= 0;
		fsmc_dat_o			<= 16'h0;
		//reset wishone
		rx_data				<= 32'h0;
		upper_word			<= 0;
		received			<= 0;
		transmitted			<= 0;
		transmit_request	<= 0;
	end
	else begin
		case (fsmc_state)
			FSMC_IDLE: begin
				fsmc_data_out_en	<= 0;
				fsmc_dat_o			<= 16'h0;
				if (lfsmc_ce_n == 0) begin
					fsmc_state	<= FSMC_GETADDR;
				end
			end
			FSMC_GETADDR: begin
				if (lfsmc_ce_n == 0) begin
					//start a wishbone transaction
					if (~lfsmc_ub_n) begin
						//upper word
						upper_word	<= 1;
					end
					else begin
						//lower word
						upper_word	<= 0;
					end

					
					if (lfsmc_we_n) begin
						//fsmc read
						fsmc_state	<= FSMC_READ;
						//request data from the above module
						transmit_request	<= 1;
					end
					else begin
//XXX: there is a bug here, the FSMC waits for a small amount of time before dropping the write enable
						//fsmc write
						fsmc_state	<= FSMC_WRITE;
						if (~lfsmc_ub_n) begin
							//upper word
							rx_data[31:16] <= lfsmc_dat_i;
						end
						else begin
							//lower word
							rx_data[15:0]	<= lfsmc_dat_i;
						end
					end
				end
				else begin
					fsmc_state	<= FSMC_IDLE;
				end
			end
			FSMC_READ: begin
				//got an ack back from the wishbone bus
				//disable the wishbone device
				if (~lfsmc_oe_n && transmit_ready) begin
					fsmc_data_out_en	<= 1;
					if (~lfsmc_ub_n) begin
						fsmc_dat_o	<=	tx_data[31:16];
						//fsmc_dat_o	<=	wb_dat_i[31:16]; 
					end
					else begin
						//fsmc_dat_o	<=	wb_dat_i[15:0];
						fsmc_dat_o	<= tx_data[15:0];
					end
					transmitted	<= 1;
					fsmc_state	<= FSMC_FINISH;
				end
				if (lfsmc_ce_n) begin
					fsmc_state	<= FSMC_IDLE;
				end
			end
			FSMC_WRITE: begin
				received	<= 1;
				fsmc_state	<= FSMC_IDLE;
			end
			FSMC_FINISH: begin
				//wait for the chip enable to go high
				if (lfsmc_ce_n) begin
					fsmc_state	<= FSMC_IDLE;
				end
			end
			default: begin
				fsmc_state	<= FSMC_IDLE;
			end
		endcase	
	end
end


endmodule
