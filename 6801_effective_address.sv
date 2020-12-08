module effective_address_6801(
			input logic clk,
			input logic hold,
			input ea_type ea_ctrl,
			input logic[7:0] accb,
			output logic[15:0] ea,
			input logic[7:0] data_in,
			input logic[15:0] xreg);
logic[15:0] tempind;
logic[15:0] tempea;
always_comb
begin
  case (ea_ctrl)
  add_ix_ea:
	 tempind = {8'b00000000, ea[7:0]};
  inc_ea:
	 tempind = 16'b0000000000000001;
  default:
    tempind = 16'b0000000000000000;
  endcase

  case (ea_ctrl)
  reset_ea:
	 tempea = 16'b0000000000000000;
  load_accb_ea:
	 tempea = {8'b00000000, accb[7:0]};
  add_ix_ea:
	 tempea = xreg;
  fetch_first_ea:
  begin
	 tempea[7:0] = data_in;
	 tempea[15:8] = 8'b00000000;
	end
  fetch_next_ea:
  begin
	 tempea[7:0] = data_in;
	 tempea[15:8] = ea[7:0];
	end
  default:
    tempea = ea;
  endcase
end

always_ff @(posedge clk)
begin
    if (hold == 1'b1)
      ea <= ea;
    else
      ea <= tempea + tempind;
end
endmodule
