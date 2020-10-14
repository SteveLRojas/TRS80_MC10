module ps2_host_tx(
  input  logic sys_clk,
  input  logic sys_rst,
  input  logic ps2_clk_negedge,
  input	logic ps2_clk_posedge,
  inout  wire ps2_data,
  inout	wire ps2_clk,
  input  logic [7:0] tx_data,
  input  logic send_req,
  output logic busy,
  output logic ps2_data_q
);
enum logic[3:0] {s_trig, s_wait_low, s_data_low, s_clk_high, wait_clk_low, s_shift, wait_clk_high, wait_both_high} state, next_state;
logic[13:0] counter, next_counter;
logic[10:0] frame, next_frame;
logic data_s, next_data_s, clk_s, next_clk_s;
assign ps2_data_q = data_s;

always_ff @(posedge sys_clk)
begin
	if(sys_rst)
	begin
		state <= s_trig;
	end
	else
	begin
		state <= next_state;
	end
	counter <= next_counter;
	data_s <= next_data_s;
	clk_s <= next_clk_s;
	frame <= next_frame;
end

always_comb
begin
	next_counter = 13'h00;
	next_state = state;
	next_clk_s = 1'b1;
	next_data_s = data_s;
	next_frame = frame;
	ps2_data = data_s ? 1'bz : 1'b0;
	ps2_clk = clk_s ? 1'bz : 1'b0;
	busy = 1'b1;
	case (state)
	s_trig:
	begin
		if(send_req)
			next_state = s_wait_low;
		next_data_s = 1'b1;
		busy = 1'b0;
		next_frame = {1'b0, tx_data[0], tx_data[1], tx_data[2], tx_data[3], tx_data[4], tx_data[5], tx_data[6], tx_data[7], ~^tx_data, 1'b1};
	end
	s_wait_low:
	begin
		next_counter = counter + 14'h01;
		if(counter == 14'h3fff)
			next_state = s_data_low;
		next_clk_s = 1'b0;
		next_data_s = 1'b1;
	end
	s_data_low:
	begin
		next_state = s_clk_high;
		next_data_s = 1'b0;
		next_clk_s = 1'b0;
	end
	s_clk_high:
	begin
		next_state = wait_clk_low;
		next_clk_s = 1'b1;
	end
	wait_clk_low:
	begin
		if(ps2_clk_negedge)
		begin
			if(frame == 11'h00)
				next_state = wait_both_high;
			else
				next_state = s_shift;
		end
	end
	s_shift:
	begin
		next_state = wait_clk_high;
		next_data_s = frame[10];
		next_frame = {frame[9:0], 1'b0};
	end
	wait_clk_high:
	begin
		if(ps2_clk_posedge)
			next_state = wait_clk_low;
	end
	wait_both_high:
	begin
		if(ps2_clk && ps2_data)
			next_state = s_trig;
	end
	default: ;
	endcase
end
endmodule
