//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ps2_host_clk_ctrl.v                                         ////
////                                                              ////
////  Description                                                 ////
////  Taking care of all interactions with ps2_clk line           ////
////                                                              ////
////  Author:                                                     ////
////      - Piotr Foltyn, piotr.foltyn@gmail.com                  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2011 Author                                    ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

// synopsys translate_off
//`include "timescale.v"
// synopsys translate_on
//`include "ps2_host_defines.v"

module ps2_host_clk_ctrl(
  input  wire sys_clk,
  input  wire sys_rst,
  input  wire ps2_clk,
  output wire ps2_clk_posedge,
  output wire ps2_clk_negedge
);

// Sample ps2_clk and detect rising and falling edge
reg [1:0] ps2_clk_samples;
initial
begin
	ps2_clk_samples = 2'b00;
end
always @(posedge sys_clk)
begin
  ps2_clk_samples <= (sys_rst) ? 2'b11 : {ps2_clk_samples[0], ps2_clk};
end

assign ps2_clk_posedge = (~ps2_clk_samples[1] &  ps2_clk_samples[0]);
assign ps2_clk_negedge = ( ps2_clk_samples[1] & ~ps2_clk_samples[0]);

endmodule
