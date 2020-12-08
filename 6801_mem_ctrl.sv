module opcode_fetch_6801(input logic clk, hold, input op_type op_ctrl, input logic[7:0] data_in, output logic[7:0] op_code);
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   op_code <= op_code;
	 else
    case (op_ctrl)
	 reset_op:
	   op_code <= 8'b00000001; // nop
  	 fetch_op:
      op_code <= data_in;
	 default:
//	 latch_op:
	   op_code <= op_code;
    endcase
end
endmodule

module IV_control_6801(input logic clk, hold, input iv_type iv_ctrl, output logic[2:0] iv);
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   iv <= iv;
	 else
    case (iv_ctrl)
	 reset_iv:
	   iv <= 3'b111;
	 nmi_iv:
      iv <= 3'b110;
  	 swi_iv:
      iv <= 3'b101;
	 irq_iv:
      iv <= 3'b100;
	 icf_iv:
	   iv <= 3'b011;
	 ocf_iv:
      iv <= 3'b010;
  	 tof_iv:
      iv <= 3'b001;
	 sci_iv:
      iv <= 3'b000;
	 default:
	   iv <= iv;
    endcase
end
endmodule

module data_fetch_6801(
			input logic clk,
			input logic hold, 
			input md_type md_ctrl,
			input logic[7:0] data_in,
			input logic[15:0] out_alu, 
			output logic[15:0] md);
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   md <= md;
	 else
    case (md_ctrl)
    reset_md:
	   md <= 16'b0000000000000000;
	 load_md:
	   md <= out_alu[15:0];
	 fetch_first_md:
	 begin
	   md[15:8] <= 8'b00000000;
	   md[7:0] <= data_in;
	end
	 fetch_next_md:
	 begin
	   md[15:8] <= md[7:0];
		md[7:0] <= data_in;
	end
	 shiftl_md:
	 begin
	   md[15:1] <= md[14:0];
		md[0] <= 1'b0;
	end
	 default:
//	 latch_md:
	   md <= md;
    endcase
end
endmodule

module SP_6801(
			input logic clk,
			input logic hold,
			input sp_type sp_ctrl,
			input logic[15:0] out_alu,
			output logic[15:0] sp);
initial
begin
	sp <= 16'h0000;
end
always_ff @(posedge clk)
begin
	if (hold == 1'b1)
		sp <= sp;
	else
	if(sp_ctrl == load_sp)
		sp <= out_alu[15:0];
	else
		sp <= sp;
end
endmodule

module XREG_6801(
			input logic clk,
			input logic hold,
			input ix_type ix_ctrl,
			input logic[15:0] out_alu,
			input logic[7:0] data_in,
			output logic[15:0] xreg);
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   xreg <= xreg;
	 else
    case (ix_ctrl)
    reset_ix:
	   xreg <= 16'b0000000000000000;
	 load_ix:
	   xreg <= out_alu[15:0];
	 pull_hi_ix:
	   xreg[15:8] <= data_in;
	 pull_lo_ix:
	   xreg[7:0] <= data_in;
	 default:
//	 latch_ix:
	   xreg <= xreg;
    endcase
end
endmodule
