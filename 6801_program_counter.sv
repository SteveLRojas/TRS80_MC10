module program_counter_6801(
			input logic clk,
			input logic hold,
			input pc_type pc_ctrl,
			input logic[15:0] ea,
			input logic[7:0] data_in,
			output logic[15:0] pc);
logic[15:0] tempof;
logic[15:0] temppc;
always_comb
begin
  case (pc_ctrl)
  add_ea_pc:
  begin
	 if (ea[7] == 0)
	   tempof = {8'b00000000, ea[7:0]};
    else
		tempof = {8'b11111111, ea[7:0]};
	end
  inc_pc:
	 tempof = 16'b0000000000000001;
  default:
    tempof = 16'b0000000000000000;
  endcase

  case (pc_ctrl)
  reset_pc:
	 temppc = 16'b1111111111111110;
  load_ea_pc:
	 temppc = ea;
  pull_lo_pc:
  begin
	 temppc[7:0] = data_in;
	 temppc[15:8] = pc[15:8];
	end
  pull_hi_pc:
  begin
	 temppc[7:0] = pc[7:0];
	 temppc[15:8] = data_in;
	end
  default:
    temppc = pc;
  endcase
end

always_ff @(posedge clk)
begin
    if (hold == 1'b1)
      pc <= pc;
    else
      pc <= temppc + tempof;
end
endmodule
