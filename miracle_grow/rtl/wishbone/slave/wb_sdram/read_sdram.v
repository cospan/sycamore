module read_sdram (
	rst,
	//sdram clock
	clk,
	cs_n,
	ras_n,
	cas_n,
	we_n,

	addr,
	bank,
	data_out,
	data_in,
	data_str,

	//sdram controller
	en,
	read_address,
	read_count,
	fifo_data,
	fifo_full,
	fifo_wr
);

input				rst;
input				clk;
output	reg			cs_n;
output	reg			ras_n;
output	reg			cas_n;
output	reg			we_n;
output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
output	reg	[15:0]	data_out;
input				data_in;
output	reg	[1:0]	data_str;

//sdram controller
input				en;
input		[23:0]	read_count;
input		[13:0]	read_address;
output		[31:0]	fifo_data;
input				fifo_full;
output	reg			fifo_wr;

//states
parameter	IDLE		8'h0;
parameter	ACTIVE		8'h1;
parameter	READ		8'h2;
parameter	READ_APCHG	8'h3;
parameter	PRECHARGE	8'h4;

reg	[7:0]			state;

reg	[23:0]			lread_count;
reg	[1:0]			lbank;
reg	[11:0]			laddress;

always @ (posedge clk) begin
	if (rst) begin
		cs_n		<= 1;
		ras_n		<= 1;
		cas_n		<= 1;
		we_n		<= 1;
		addr		<= 12'h0;
		bank		<= 2'h0;
		data_out	<= 16'h0;
		data_str	<= 2'h0;

		fifo_data	<= 16'h0;
		fifo_wr		<= 0;

		state		<= IDLE;
		lread_count	<= 24'h0;
		lbank		<= 2'h0;
		laddress	<= 12'h0;

	end
	else begin
		fifo_wr		<= 1;

		case (state)
			IDLE: begin
				if (en) begin
					//initiate a read cycle
					lread_count	<= read_count;
					lbank		<= read_address[13:12];
					laddress	<= read_address[11:0];
					state		<= ACTIVE;
				end
			end
			ACTIVE: begin
				$display ("read_sdram: ACTIVE");

				cs_n	<=	0;
				ras_n	<=	0;
				cas_n	<=	1;
				we_n	<=	1;
				addr	<=	laddress;
				bank	<=	lbank;

				if (lread_count > 1) begin
					//enable auto-precharge
					state	<= READ;
				end
				else begin
					state	<= READ_APCHG;
				end
			end
			READ: begin
				$display ("read_sdram: READ, no precharge");
			end
			READ_APCHG: begin
				$display ("read_sdram: READ with auto precharge");
			end
			PRECHARGE: begin
				$display ("read_sdram: PRECHARGE");
			end
			default: begin
				$display ("read_sdram: got to an unknown state");
				state	<= IDLE;
			end

		endcase
	end
end
endmodule
