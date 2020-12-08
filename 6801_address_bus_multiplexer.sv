`include "6801_types.sv"
module address_bus_multiplexer(
		input addr_type addr_ctrl,
		input logic[2:0] iv,
		input logic[15:0] ea,
		input logic[15:0] pc,
		input logic[15:0] sp,
		output logic[15:0] address,
		output logic vma,
		output logic rw);
always_comb
begin
  case(addr_ctrl)
	idle_ad:
	begin
	   address = 16'b1111111111111111;
		vma     = 1'b0;
		rw      = 1'b1;
	end
    fetch_ad:
	 begin
	   address = pc;
		vma     = 1'b1;
		rw      = 1'b1;
	end
	 read_ad:
	 begin
	   address = ea;
		vma     = 1'b1;
		rw      = 1'b1;
	end
    write_ad:
	 begin
	   address = ea;
		vma     = 1'b1;
		rw      = 1'b0;
	end
	 push_ad:
	 begin
	   address = sp;
		vma     = 1'b1;
		rw      = 1'b0;
	end
    pull_ad:
	 begin
	   address = sp;
		vma     = 1'b1;
		rw      = 1'b1;
	end
	 int_hi_ad:
	 begin
	   address = {12'b111111111111, iv, 1'b0};
		vma     = 1'b1;
		rw      = 1'b1;
	end
    int_lo_ad:
	 begin
	   address = {12'b111111111111, iv, 1'b1};
		vma     = 1'b1;
		rw      = 1'b1;
	end
	 default:
	 begin
	   address = 16'b1111111111111111;
		vma     = 1'b0;
		rw      = 1'b1;
	end
  endcase
end
endmodule
