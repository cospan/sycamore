//sdram_include.v
`ifdef SDRAM_INCLUDE_V
`else
`define SDRAM_INCLUDE_V

`timescale 1ns/10ps

//---------------------------------------------------------------------------
// Frequency and timeouts
//---------------------------------------------------------------------------
`define SYS_CLK_FREQUENCY   50000     // in kHz
`define SDRAM_CLK_MULTIPLY    2        
`define SDRAM_CLK_DIVIDE      1

//---------------------------------------------------------------------------
// Width
//---------------------------------------------------------------------------
`define CMD_WIDTH  3
`define A_WIDTH    12
`define BA_WIDTH   2
`define DQ_WIDTH   16
`define DQS_WIDTH  2
`define DM_WIDTH   2

`define RFIFO_WIDTH  (2 * `DQ_WIDTH )
`define WFIFO_WIDTH  (2 * (`DQ_WIDTH + `DM_WIDTH))
`define CBA_WIDTH    (`CMD_WIDTH+`BA_WIDTH+`A_WIDTH)

// Ranges
`define CMD_RNG      (`CMD_WIDTH-1):0
`define A_RNG        (`A_WIDTH-1):0
`define BA_RNG       (`BA_WIDTH-1):0
`define DQ_RNG       (`DQ_WIDTH-1):0
`define DQS_RNG      (`DQS_WIDTH-1):0
`define DM_RNG       (`DM_WIDTH-1):0

`define RFIFO_RNG    (`RFIFO_WIDTH-1):0
`define WFIFO_RNG    (`WFIFO_WIDTH-1):0
`define WFIFO_D0_RNG (1*`DQ_WIDTH-1):0
`define WFIFO_D1_RNG (2*`DQ_WIDTH-1):(`DQ_WIDTH)
`define WFIFO_M0_RNG (2*`DQ_WIDTH+1*`DM_WIDTH-1):(2*`DQ_WIDTH+0*`DM_WIDTH)
`define WFIFO_M1_RNG (2*`DQ_WIDTH+2*`DM_WIDTH-1):(2*`DQ_WIDTH+1*`DM_WIDTH)
`define CBA_RNG      (`CBA_WIDTH-1):0
`define CBA_CMD_RNG  (`CBA_WIDTH-1):(`CBA_WIDTH-3)
`define CBA_BA_RNG   (`CBA_WIDTH-4):(`CBA_WIDTH-5)
`define CBA_A_RNG    (`CBA_WIDTH-6):0

`define ROW_RNG      12:0

//----------------------------------------------------------------------------
// Configuration registers
//----------------------------------------------------------------------------
//Burst
//Burst Length = 2 (32 bits)
//CAS Latency = 2
//Sequential
`define SDRAM_INIT_LMR	`A_WIDTH'b001000100001

//----------------------------------------------------------------------------
// FML constants
//----------------------------------------------------------------------------
`define FML_ADR_RNG     25:4 
`define FML_ADR_BA_RNG  25:24
`define FML_ADR_ROW_RNG 23:11
`define FML_ADR_COL_RNG 10:4
`define FML_DAT_RNG     31:0
`define FML_BE_RNG       3:0

//----------------------------------------------------------------------------
// SDRAM constants
//----------------------------------------------------------------------------
`define SDRAM_CMD_NOP   3'b111
`define SDRAM_CMD_ACT   3'b011
`define SDRAM_CMD_READ  3'b101
`define SDRAM_CMD_WRITE 3'b100
`define SDRAM_CMD_TERM  3'b110
`define SDRAM_CMD_PRE   3'b010
`define SDRAM_CMD_AR    3'b001
`define SDRAM_CMD_MRS   3'b000

`define ADR_BA_RNG    25:24
`define ADR_ROW_RNG   23:11
`define ADR_COL_RNG   10:4

//ACTIVE -> READ 2 clock cycles 7E
`define T_RCD	2			
//READ -> DATA READY 2 clock cycles for CAS latency
`define T_CAS	2			
//PRECHARGE -> finished	
`define T_RP	2			
//READ -> READ
`define T_CCD	1			
//AUTO REFRESH to ready
`define T_RFC	7		
//160uS delay (100uS + 60uS)
`define T_PLL	16000
//MODE Register Set
`define T_MRD	2

//Auto Refresh Timeout
`define T_AR_TIMEOUT	60000000
//----------------------------------------------------------------------------
// Buffer Cache 
//----------------------------------------------------------------------------
`define WAY_WIDTH      (`WB_DAT_WIDTH + `WB_SEL_WIDTH)
`define WAY_LINE_RNG   (`WAY_WIDTH-1):0
`define WAY_DAT_RNG    31:0
`define WAY_VALID_RNG  35:32

`define TAG_LINE_RNG           32:0
`define TAG_LINE_TAG0_RNG      14:0
`define TAG_LINE_TAG1_RNG      29:15
`define TAG_LINE_DIRTY0_RNG    30
`define TAG_LINE_DIRTY1_RNG    31
`define TAG_LINE_LRU_RNG       32

`endif
