// $Header: /devl/xcs/repo/env/Databases/CAEInterfaces/versclibs/data/blanc/X_BUFHCE.v,v 1.5 2008/10/21 20:27:37 yanx Exp $
///////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995/2009 Xilinx, Inc.
// All Right Reserved.
///////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor : Xilinx
// \   \   \/     Version : 13.i 
//  \   \         Description : Xilinx Timing Simulation Library Component
//  /   /                       H Clock Buffer with Active High Enable
// /___/   /\     Filename : BUFHCE.v
// \   \  /  \    Timestamp : Wed Apr 22 17:10:55 PDT 2009
//  \___\/\___\
//
// Revision:
//    04/08/08 - Initial version.
//    09/19/08 - Add GSR
//    10/19/08 - Recoding to same as BUFGCE according to hardware.
//    11/15/10 - Add CE_TYPE attribute (CR578114)
// End Revision

`timescale 1 ps/1 ps

module BUFHCE (O, CE, I);

  parameter CE_TYPE = "SYNC";
  parameter integer INIT_OUT = 0;

`ifdef XIL_TIMING

  parameter LOC = "UNPLACED";

`endif


  output O;
  input CE;
  input I;

  reg notifier;
  wire del_I, delCE;
  wire  NCE, o_bufg_o, o_bufg1_o;
  reg CE_TYPE_BINARY;
  reg INIT_OUT_BINARY;

  initial begin
    case (CE_TYPE)
      "SYNC" : CE_TYPE_BINARY = 1'b0;
      "ASYNC" : CE_TYPE_BINARY = 1'b1;
      default : begin
        $display("Attribute Syntax Error : The Attribute CE_TYPE on BUFHCE instance %m is set to %s.  Legal values for this attribute are SYNC, or ASYNC.", CE_TYPE);
        $finish;
      end
    endcase

    if ((INIT_OUT >= 0) && (INIT_OUT <= 1))
      INIT_OUT_BINARY = INIT_OUT;
    else begin
      $display("Attribute Syntax Error : The Attribute INIT_OUT on BUFHCE instance %m is set to %d.  Legal values for this attribute are  0 to 1.", INIT_OUT);     $finish;
    end

  end

    
    BUFGCTRL bufgctrl0_inst (.O(o_bufg_o),
			     .CE0(1'b1),
			     .CE1(1'b1),
			     .I0(del_I),
			     .I1(1'b0), 
//			     .IGNORE0(1'b0), 
			     .IGNORE0(CE_TYPE_BINARY), 
			     .IGNORE1(1'b0), 
			     .S0(~NCE), 
			     .S1(NCE));
    
    defparam bufgctrl0_inst.INIT_OUT = 1'b0;
    defparam bufgctrl0_inst.PRESELECT_I0 = "TRUE";
    defparam bufgctrl0_inst.PRESELECT_I1 = "FALSE";
                               
                                       
    INV I1 (.I(delCE),
            .O(NCE));

    
    BUFGCTRL bufgctrl1_inst (.O(o_bufg1_o), 
			     .CE0(1'b1), 
			     .CE1(1'b1), 
			     .I0(del_I), 
			     .I1(1'b1), 
//			     .IGNORE0(1'b0), 
			     .IGNORE0(CE_TYPE_BINARY), 
			     .IGNORE1(1'b0), 
			     .S0(~NCE), 
			     .S1(NCE));
    
    defparam bufgctrl1_inst.INIT_OUT = 1'b0;
    defparam bufgctrl1_inst.PRESELECT_I0 = "FALSE";
    defparam bufgctrl1_inst.PRESELECT_I1 = "TRUE";

    
    assign O = (INIT_OUT == 1) ? o_bufg1_o : o_bufg_o;

    
`ifndef XIL_TIMING
    
    assign del_I = I;
    assign delCE = CE;
    
`endif

    
    specify

	(I => O) = (100:100:100, 100:100:100);
      
`ifdef XIL_TIMING

	$period (posedge I, 0:0:0, notifier);
	$setuphold (negedge I, negedge CE, 0:0:0, 0:0:0, notifier,,, del_I, delCE);
	$setuphold (negedge I, posedge CE, 0:0:0, 0:0:0, notifier,,, del_I, delCE);
	$setuphold (posedge I, negedge CE, 0:0:0, 0:0:0, notifier,,, del_I, delCE);
	$setuphold (posedge I, posedge CE, 0:0:0, 0:0:0, notifier,,, del_I, delCE);

`endif

	specparam PATHPULSE$ = 0;
	
    endspecify

    
endmodule
