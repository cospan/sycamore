//device_rom_table.v


/*
 *use defparam in the instantiating module in order to set the 
 * number of items in the ROM
 * defparam DRT_NUM_OF_DEVICES = 2;
 */

//`define DRT_NUM_OF_DEVICES 1
`define DRT_SIZE_OF_HEADER 	4
`define DRT_SIZE_OF_DEV		4


module device_rom_table (
	clk,
	rst,

	wbs_we_i,
	wbs_cyc_i,
	wbs_dat_i,
	wbs_stb_i,
	wbs_ack_o,
	wbs_dat_i,
	wbs_dat_o,
	wbs_adr_i,
	wbs_int_o,
);

input 					clk;
input 					rst;

//wishbone slave signals
input 					wbs_we_i;
input 					wbs_stb_i;
input 					wbs_cyc_i;
input		[31:0]		wbs_adr_i;
input  		[31:0]		wbs_dat_i;
output reg  [31:0]		wbs_dat_o;
output reg				wbs_ack_o;
output reg				wbs_int_o; 

parameter DRT_NUM_OF_DEVICES = 1;

parameter DRT_ID_ADR		= 32'h00000000;	
parameter DRT_NUM_DEV_ADR	= 32'h00000001;
parameter DRT_RFU_1_ADR		= 32'h00000002;
parameter DRT_RFU_2_ADR		= 32'h00000003;

//parameters that go into the ROM
parameter DRT_ID			= 16'h0001;
parameter DRT_VERSION		= 16'h0001;
parameter DRT_RFU_1			= 32'h00000000;
parameter DRT_RFU_2			= 32'h00000000;

parameter DRT_DEV_OFF_ADR	= 32'h00000004;
parameter DRT_DEV_SIZE		= 4'h4;

parameter DEV_ID_OFF		= 4'h0;
parameter DEV_INFO_OFF		= 4'h1;
parameter DEV_MEM_OFF_OFF	= 4'h2;
parameter DEV_SIZE_OFF		= 4'h3;

//registers
parameter DRT_SIZE			= `DRT_SIZE_OF_HEADER + (`DRT_NUM_OF_DEVICES * `DRT_SIZE_OF_DEV);
//reg [DRT_SIZE:0][31:0] drt;
reg [31:0] drt [(DRT_SIZE - 1):0]; 

//NEED A way to pull data in from input file
//`DRT_INPUT_FILE
//integer i;
initial begin
//	$display ("size of ROM: 32 x %d", DRT_SIZE);
//	$display ("total size of ROM is %d", DRT_SIZE * 32 + 4);
//	$display ("drt: %h", drt[0]);
	$readmemh(`DRT_INPUT_FILE, drt, 0, DRT_SIZE - 1); 
//	for (i = 0; i < DRT_SIZE; i = i+1) begin
//		$display ("drt[%d]: %h", i, drt[i]);
//	end
end

always @ (posedge clk) begin
	if (rst) begin
		wbs_dat_o	<= 32'h0;
		wbs_ack_o	<= 0;
		wbs_int_o	<= 0;
	end

	//when the master acks our ack, then put our ack down
	if (wbs_ack_o & ~ wbs_stb_i)begin
		wbs_ack_o <= 0;
	end

	if (wbs_stb_i & wbs_cyc_i) begin
		//master is requesting somethign
		if (wbs_we_i) begin
			//ROMS can't be written to
		end

		else begin 
			//read request
			wbs_dat_o	<= drt[wbs_adr_i];	
		end
		wbs_ack_o	<= 1;
	end
end


endmodule
