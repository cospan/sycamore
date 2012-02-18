module sdram (
	clk,
	rst,


	sdram_clk,
	cs_n,
	cke,
	ras_n,
	cas_n,
	we_n,

	addr,
	bank,
	data,
	data_str
);

input 				clk;
input 				rst;

output				sdram_clk;
output	reg			cke;
output 	reg			cs_n;
output	reg			ras_n;
output	reg			cas_n;
output	reg			we_n;

output	reg	[11:0]	addr;
output	reg	[1:0]	bank;
inout	[15:0]		data;
output	reg	[1:0]	data_str;

reg		[15:0]		data_out;
assign data	=		(we_n) ? 16'hZ:data_out;


wire				read_cs_n;
wire				read_ras_n;
wire				read_cas_n;
wire				read_we_n;
wire	[11:0]		read_addr_n;
wire	[1:0]		read_bank;


wire				write_cs_n;
wire				write_ras_n;
wire				write_cas_n;
wire				write_we_n;
wire	[11:0]		write_addr_n;
wire	[1:0]		write_bank;


always @ (posedge sdram_clk) begin
	if (rst) begin
		cke			<= 0;
		cs_n		<= 0;
		ras_n		<= 0;
		cas_n		<= 0;
		we_n		<= 0;
		addr		<= 12'h0;
		bank		<= 2'h0;
		data_out	<= 16'h0;
		data_str	<= 2'h0;
	end
	else begin
	end
end

endmodule 
