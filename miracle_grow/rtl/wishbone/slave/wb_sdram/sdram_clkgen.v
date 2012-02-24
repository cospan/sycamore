//sdram_clkgen.v


module sdram_clkgen (
	input clk,
	input rst,

	output locked,
	output out_clk,
	output phy_out_clk
);

wire clock_out;
DCM_SP #(
	.CLKFX_DIVIDE(1),
	.CLKFX_MULTIPLY(2),
	.CLKIN_DIVIDE_BY_2("FALSE"),
	.CLKIN_PERIOD(),
	.CLKOUT_PHASE_SHIFT("NONE"),
	.CLK_FEEDBACK("NONE"),
	.DESKEW_ADJUST("SOURCE_SYNCHRONOUS"),
	.DFS_FREQUENCY_MODE("LOW"),
	.DLL_FREQUENCY_MODE("LOW"),
	.DUTY_CYCLE_CORRECTION("TRUE"),
	.FACTORY_JF(16'hC080),
	.PHASE_SHIFT(0),
	.STARTUP_WAIT("FALSE")
) dcm_fx (
	.DSSEN(),
	.CLK0(),
	.CLK180(),
	.CLK270(),
	.CLK2X(),
	.CLK2X180(),
	.CLK90(),
	.CLKDV(),
	.CLKFX(clock_out),
	.CLKFX180(clock_out_n),
	.LOCKED(locked),
	.PSDONE(),
	.STATUS(),
	.CLKFB(),
	.CLKIN(clk),
	.PSCLK(1'b0),
	.PSEN(1'b0),
	.PSINCDEC(1'b0),
	.RST(rst)

);


ODDR2 #(
	.DDR_ALIGNMENT("NONE"),	//Sets output alignment to NON
	.INIT(1'b0),			//Sets the inital state to 0
	.SRTYPE("SYNC")			//Specified "SYNC" or "ASYNC" reset
)	pad_buf (

	.Q(phy_out_clk),
	.C0(clock_out),
	.C1(clock_out_n),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);


BUFG bufg_sdram_clk (
	.I(clock_out),
	.O(out_clk)
);

endmodule
