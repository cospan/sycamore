//device_rom_table.v


//!!replace this with the number of devices in the DRT
`define DRT_NUM_OF_DEVICES 		1
//!!end
`define DRT_SIZE_OF_HEADER 	4
`define DRT_SIZE_OF_DEV		4


module drt (
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
//parameter DRT_SIZE			= 31 * `DRT_SIZE_OF_HEADER + (`DRT_NUM_OF_DEVICES * `DRT_SIZE_OF_DEV);
//reg [DRT_SIZE:0][31:0] drt;


//blocks
always @ (posedge clk) begin
	//load everything in the ROM
	if (rst) begin
//		drt[0][31:0]	<= {DRT_ID, DRT_VERSION};
//		drt[1][31:0]	<= 32'h`DRT_NUM_OF_DEVICES;
//		drt[2][31:0]	<= DRT_RFU_1;
//		drt[3][31:0]	<= DRT_RFU_2;

		//!!populate the list
//		drt[`DRT_SIZE_OF_HEADER + 0 * `DRT_SIZE_OF_DEV + 0][31:0]	<= 32'h01234567	//device 0 ID
//		drt[`DRT_SIZE_OF_HEADER + 0 * `DRT_SIZE_OF_DEV + 1][31:0]	<= 32'h76543210 //device 0 info/flags
//		drt[`DRT_SIZE_OF_HEADER + 0 * `DRT_SIZE_OF_DEV + 2][31:0]	<= 32'h0000000F	//device 0 offset from 0x00
//		drt[`DRT_SIZE_OF_HEADER + 0 * `DRT_SIZE_OF_DEV + 3][31:0]	<= 32'h0000000F	//device 0 size
		//!!end populate list
	end
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
			//write request
			case (wbs_adr_i) 
				//ADDRESS DEFINE : begin
				//	do something
				//end
				wbs_ack_i;
			endcase
		end

		else begin 
			//read request
			//wbs_dat_o	<= drt[wbs_adr_i - `DRT_SIZE_OF_HEADER][31:0];	
			wbs_ack_o	<= 1;
			endcase
		end
	end
end


endmodule
