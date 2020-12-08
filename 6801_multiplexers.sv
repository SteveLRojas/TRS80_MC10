module left_mux_6801(
			input left_type left_ctrl, 
			input logic[7:0] acca, accb, 
			input logic[15:0] xreg, sp, md,
			output logic[15:0] left);
always_comb
begin
  case (left_ctrl)
	 acca_left:
	 begin
	   left[15:8] = 8'b00000000;
		left[7:0]  = acca;
	end
	 accb_left:
	 begin
	   left[15:8] = 8'b00000000;
		left[7:0]  = accb;
	end
	 accd_left:
	 begin
	   left[15:8] = acca;
		left[7:0]  = accb;
	end
	 ix_left:
	   left = xreg;
	 sp_left:
	   left = sp;
	 default:
//	 md_left:
	   left = md;
    endcase
end
endmodule

module right_mux_6801(input right_type right_ctrl, input logic[7:0] accb, input logic[15:0] md, output logic[15:0] right);
always_comb
begin
  case (right_ctrl)
	 zero_right:
	   right = 16'b0000000000000000;
	 plus_one_right:
	   right = 16'b0000000000000001;
	 accb_right:
	   right = {8'b00000000, accb};
	 default:
//	 md_right:
	   right = md;
    endcase
end
endmodule

module NMI_mux_6801(input logic clk, hold, input nmi_type nmi_ctrl, output logic nmi_ack);
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   nmi_ack <= nmi_ack;
	 else
    case (nmi_ctrl)
	 set_nmi:
      nmi_ack <= 1'b1;
	 reset_nmi:
	   nmi_ack <= 1'b0;
	 default:
//  when latch_nmi =>
	   nmi_ack <= nmi_ack;
	 endcase
end
endmodule
