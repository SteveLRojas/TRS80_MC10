module testbench_VDG();

timeunit 1ns;
timeprecision 1ns;
logic clk_25;
logic reset;

logic[7:0] DD;
logic[13:0] DA;
logic R, G, B;
logic HSYNC, VSYNC;

logic[9:0] pixel_count, next_pixel_count;	//0 to 799 horizontal position in physical display
logic[9:0] line_count, next_line_count;	//0 to 524 vertical position in physical siplay
logic[7:0] col_count, next_col_count;	//0 to 255 horizontal position in virtual display
logic[9:0] row_count, next_row_count, row_count_d;	//0 to 958 vertical position in virtual display
logic[5:0] cell_line, next_cell_line, cell_line_d;	//0 to 58 line position in current cell
logic[3:0] cell_count, next_cell_count;	//0 to 15 vertical cell position
logic active_rows, next_active_rows;
logic active_area, next_active_area, active_area_s;

assign pixel_count = VDG.pixel_count;
assign next_pixel_count = VDG.next_pixel_count;
assign line_count = VDG.line_count;
assign next_line_count = VDG.next_line_count;
assign col_count = VDG.col_count;
assign next_col_count = VDG.next_col_count;
assign row_count = VDG.row_count;
assign next_row_count = VDG.next_row_count;
assign row_count_d = VDG.row_count_d;
assign cell_line = VDG.cell_line;
assign next_cell_line = VDG.next_cell_line;
assign cell_line_d = VDG.cell_line_d;
assign cell_count = VDG.cell_count;
assign next_cell_count = VDG.next_cell_count;
assign active_rows = VDG.active_rows;
assign next_active_rows = VDG.next_active_rows;
assign active_area = VDG.active_area;
assign next_active_area = VDG.next_active_area;
assign active_area_s = VDG.active_area_s;

MC6847_gen3 VDG(.clk_25, .reset, .AG(1'b0), .SA(1'b0), .INV(1'b1), .DD, .DA, .R, .G, .B, .HSYNC, .VSYNC);

always begin: CLOCK_25_GENERATION
#20 clk_25 = ~clk_25;
end

initial begin: CLOCK_INITIALIZATION
	clk_25 = 0;
end

assign DD = DA[7:0];

initial begin: TEST_VECTORS
//initial conditions
reset = 1'b1;
#80 reset = 1'b0;
end
endmodule

