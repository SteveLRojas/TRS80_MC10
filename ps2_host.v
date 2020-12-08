//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ps2_host.v                                                  ////
////                                                              ////
////  Description                                                 ////
////  Top file, gluing all parts together                         ////
////                                                              ////
////  Author:                                                     ////
////      - Piotr Foltyn, piotr.foltyn@gmail.com                  ////
////   Module modified by Esteban Looser-Rojas                    ////
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

module ps2_host(
  input wire sys_clk,
  input wire sys_rst,
  input wire ps2_clk,
  input wire ps2_data,
  output wire [7:0] rx_data,
  output wire ready,
  output wire error
);

wire ps2_clk_negedge;
wire ps2_clk_posedge;

ps2_host_clk_ctrl ps2_host_clk_ctrl (
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .ps2_clk(ps2_clk),
  .ps2_clk_posedge(ps2_clk_posedge),
  .ps2_clk_negedge(ps2_clk_negedge)
);

ps2_host_rx ps2_host_rx(
  .sys_clk(sys_clk),
  .sys_rst(sys_rst),
  .ps2_clk_negedge(ps2_clk_negedge),
  .ps2_data(ps2_data),
  .rx_data(rx_data),
  .ready(ready),
  .error(error)
);
endmodule
