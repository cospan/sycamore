//sdram_clkgen.v


module sdram_clkgen (
	input clk,
	input rst,

	output locked,
	output out_clk
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
	.CLKFX180(),
	.LOCKED(locked),
	.PSDONE(),
	.STATUS(),
	.CLKFB(),
	.CLKIN(clk),
	.PSCLK(gnd),
	.PSEN(gnd),
	.PSINCDEC(gnd),
	.RST(rst)

);

BUFG bufg_sdram_clk (
	.I(clock_out),
	.O(out_clk)
);

endmodule
