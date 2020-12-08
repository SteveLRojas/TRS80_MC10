module accumulator_a_6801(
			input logic clk,
			input logic hold,
			input acca_type acca_ctrl,
			input logic[7:0] data_in,
			input logic[15:0] out_alu,
			output logic[7:0] acca);
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   acca <= acca;
	 else
    case (acca_ctrl)
    reset_acca:
	   acca <= 8'b00000000;
	 load_acca:
	   acca <= out_alu[7:0];
	 load_hi_acca:
	   acca <= out_alu[15:8];
	 pull_acca:
	   acca <= data_in;
	 default:
//	 latch_acca:
	   acca <= acca;
    endcase
end
endmodule

module accumulator_b_6801(
			input logic clk,
			input logic hold,
			input accb_type accb_ctrl,
			input logic[7:0] data_in,
			input logic[15:0] out_alu,
			output logic[7:0] accb);
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   accb <= accb;
	 else
    case (accb_ctrl)
    reset_accb:
	   accb <= 8'b00000000;
	 load_accb:
	   accb <= out_alu[7:0];
	 pull_accb:
	   accb <= data_in;
	 default:
//	 latch_accb:
	   accb <= accb;
    endcase
end
endmodule
