module data_bus_output(
			input logic[15:0] md,
			input logic[7:0] acca, accb,
			input logic[15:0] xreg,
			input logic[7:0] cc,
			input logic[15:0] pc,
			input dout_type dout_ctrl,
			output logic[7:0] data_out);
always_comb
begin
    case (dout_ctrl)
	 md_hi_dout: //// alu output
	   data_out = md[15:8];
	 md_lo_dout:
	   data_out = md[7:0];
	 acca_dout: //// accumulator a
	   data_out = acca;
	 accb_dout: //// accumulator b
	   data_out = accb;
	 ix_lo_dout: //// index reg
	   data_out = xreg[7:0];
	 ix_hi_dout: //// index reg
	   data_out = xreg[15:8];
	 cc_dout: //// condition codes
	   data_out = cc;
	 pc_lo_dout: //// low order pc
	   data_out = pc[7:0];
	 pc_hi_dout: //// high order pc
	   data_out = pc[15:8];
	 default:
	   data_out = 8'b00000000;
    endcase
end
endmodule
