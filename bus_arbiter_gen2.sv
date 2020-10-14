module bus_arbiter_gen2(
			input logic clk,
			input logic RW_in,
			input logic[15:0] VDG_address,
			input logic[15:0] CPU_address,
			input logic[7:0] RAM_data_in,
			input logic[7:0] CPU_data_in,
			output logic[15:0] system_address,
			output logic[7:0] RAM_data_out,
			output logic[7:0] VDG_data_out,
			output logic[7:0] memory_data_out,
			output logic RW_out);
logic state;
always_ff @(posedge clk)
begin
state <= ~state;
unique case (state)
	1'b1:	//VDG address
	begin
		system_address <= VDG_address;
		VDG_data_out <= RAM_data_in;
		RW_out <= 1'b0;
	end
	1'b0:	//CPU address
	begin
		system_address <= CPU_address;
		memory_data_out <= CPU_data_in;
		RAM_data_out <= RAM_data_in;
		RW_out <= RW_in;
	end
endcase
end
endmodule
