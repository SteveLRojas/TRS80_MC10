module MC6847_gen3(
			input logic clk_25,
			input logic reset,
			input logic AG,
			input logic SA,
			input logic INV,
			input logic[7:0] DD,
			output logic[13:0] DA,
			output logic R, G, B,
			output logic HSYNC, VSYNC);
logic[13:0] next_DA;
logic[7:0] DD_s;
logic[7:0] MCM_data, MCM_data_s;
logic[9:0] pixel_count, next_pixel_count;	//0 to 799 horizontal position in physical display
logic[9:0] line_count, next_line_count;	//0 to 524 vertical position in physical siplay
logic next_R, next_G, next_B, next_HSYNC, next_VSYNC;	//output register to prevent glitches from being displayed.
logic[7:0] col_count, next_col_count;	//0 to 255 horizontal position in virtual display
logic[7:0] row_count, next_row_count;	//0 to 191 vertical position in virtual display
logic[3:0] cell_line, next_cell_line;	//0 to 11 line position in current cell
logic[3:0] cell_count, next_cell_count;	//0 to 15 vertical cell position
logic active_rows, next_active_rows;
logic active_area, next_active_area, active_area_s;
logic R4, G4, B4, H4, E4, R3, G3, B3;
logic[1:0] pair;
logic AG_s, SA_s, INV_s;
logic[2:0] horiz_scaler;
logic[2:0] vert_scaler, next_vert_scaler;
logic horiz_advance;

always_ff @(posedge clk_25)
begin
	if(reset)
	begin
		pixel_count <= 0;
		line_count <= 0;
		active_rows <= 0;
		active_area <= 0;
		horiz_scaler <= 0;
	end
	else
	begin
		pixel_count <= next_pixel_count;
		line_count <= next_line_count;
		active_rows <= next_active_rows;
		active_area <= next_active_area;
		if(horiz_scaler == 3'b100)
			horiz_scaler <= 3'b000;
		else
			horiz_scaler <= horiz_scaler + 3'b001;
	end
	HSYNC <= next_HSYNC;
	VSYNC <= next_VSYNC;
	R <= next_R;
	G <= next_G;
	B <= next_B;
end

always_comb
begin
// virtual advance logic
	horiz_advance = (horiz_scaler == 3'b000) | (horiz_scaler == 3'b010);
// line and pixel counters
	if(pixel_count == 10'd799)
		next_pixel_count = 10'h00;
	else
		next_pixel_count = pixel_count + 10'h01;
	if(pixel_count == 10'd799)
	begin
		if(line_count == 10'd524)
			next_line_count = 1'h00;
		else
			next_line_count = line_count + 10'h01;
	end
	else
		next_line_count = line_count;
// HSYNC and VSYNC logic
	if(pixel_count <= 10'd751 && pixel_count >= 10'd656)
		next_HSYNC = 1'b0;
	else
		next_HSYNC = 1'b1;
	if(line_count == 10'd491 || line_count == 10'd492)
		next_VSYNC = 1'b0;
	else
		next_VSYNC = 1'b1;
// active area logic
	if(line_count == 10'h00)
		next_active_rows = 1'b1;
	else if(line_count == 10'd480)
		next_active_rows = 1'b0;
	else
		next_active_rows = active_rows;
	if(active_rows && pixel_count == 10'd798)
		next_active_area = 1'b1;
	else if(pixel_count == 10'd638)
		next_active_area = 1'b0;
	else
		next_active_area = active_area;
end

always_ff @(posedge clk_25)
begin
	if(reset)
	begin
		col_count <= 0;
		cell_line <= 0;
		cell_count <= 0;
		row_count <= 0;
		vert_scaler <= 0;
	end
	else if(horiz_advance)
	begin
		col_count <= next_col_count;
		cell_line <= next_cell_line;
		cell_count <= next_cell_count;
		row_count <= next_row_count;
		vert_scaler <= next_vert_scaler;
	end
	if(horiz_advance)
	begin
		DA <= next_DA;
		if(col_count[2:0] == 3'b111)
		begin
			DD_s <= DD;
			AG_s <= AG;
			SA_s <= SA;
			INV_s <= INV;
			MCM_data_s <= MCM_data;
		end
		active_area_s <= active_area;
	end
end

always_comb
begin
// col_count, row_count, cell_line, and cell_count counter logic
	if(active_area)
	begin
		next_col_count = col_count + 8'h01;
		if(col_count == 8'd255)
		begin
			if(vert_scaler == 3'b100)
				next_vert_scaler = 3'b000;
			else
				next_vert_scaler = vert_scaler + 3'b001;
			if((vert_scaler == 3'b010) | (vert_scaler == 3'b100))
			begin
				if(row_count == 8'd191)
					next_row_count = 0;
				else
					next_row_count = row_count + 8'h01;
				if(cell_line == 4'd11)
				begin
					next_cell_line = 4'h0;
					next_cell_count = cell_count + 4'h1;
				end
				else
				begin
					next_cell_line = cell_line + 4'h1;
					next_cell_count = cell_count;
				end
			end
			else
			begin
				next_row_count = row_count;
				next_cell_line = cell_line;
				next_cell_count = cell_count;
			end
		end
		else
		begin
			next_cell_line = cell_line;
			next_cell_count = cell_count;
			next_row_count = row_count;
			next_vert_scaler = vert_scaler;
		end
	end
	else if(active_rows)
	begin
		next_col_count = 8'h07;	// col_count must be maintained 7 counts ahead of the actual column value.
// this will cause the 3 LSBs of col_count to roll over at the start of each cell, so the right data is latched but the address points to the next cell.
		next_cell_line = cell_line;
		next_cell_count = cell_count;
		next_row_count = row_count;
		next_vert_scaler = vert_scaler;
	end
	else
	begin
		next_cell_line = 0;
		next_col_count = 0;
		next_row_count = 0;
		next_col_count = 8'h07;
		next_cell_count = 0;
		next_vert_scaler = 0;
	end
//memory address logic
	if(AG_s)
		next_DA = {2'b00, row_count[7:1], col_count[7:3]};	//color graphics 3
	else
		next_DA = {5'h00, cell_count, col_count[7:3]};	//alphanumeric internal
// RGB logic
	if(~active_area_s)
	begin
		next_R = 1'b0;
		next_G = 1'b0;
		next_B = 1'b0;
	end
	else if(AG_s)	//color graphics 3
	begin
		next_R=R3;
		next_G=G3;
		next_B=B3;
	end
	else if(SA_s)	//semigraphics 4
	begin
		next_R = R4 & E4;
		next_G = G4 & E4;
		next_B = B4 & E4;
	end
	else	//alphanumeric internal
	begin
		next_R = 0;
		next_B = 0;
		case(col_count[2:0])
			3'b000: next_G = MCM_data_s[7] ^ (INV_s);
			3'b001: next_G = MCM_data_s[6] ^ (INV_s);
			3'b010: next_G = MCM_data_s[5] ^ (INV_s);
			3'b011: next_G = MCM_data_s[4] ^ (INV_s);
			3'b100: next_G = MCM_data_s[3] ^ (INV_s);
			3'b101: next_G = MCM_data_s[2] ^ (INV_s);
			3'b110: next_G = MCM_data_s[1] ^ (INV_s);
			3'b111: next_G = MCM_data_s[0] ^ (INV_s);
		endcase
	end
	unique case(DD_s[6:4])
		3'h0:
		begin
			R4 = 0;
			G4 = 1'b1;
			B4 = 0;
		end
		3'h1:
		begin
			R4 = 1'b1;
			G4 = 1'b1;
			B4 = 0;
		end
		3'h2:
		begin
			R4 = 0;
			G4 = 0;
			B4 = 1'b1;
		end
		3'h3:
		begin
			R4 = 1'b1;
			G4 = 0;
			B4 = 0;
		end
		3'h4:
		begin
			R4 = 1'b1;
			G4 = 1'b1;
			B4 = 1'b1;
		end
		3'h5:
		begin
			R4 = 0;
			G4 = 1'b1;
			B4 = 1'b1;
		end
		3'h6:
		begin
			R4 = 1'b1;
			G4 = 0;
			B4 = 1'b1;
		end
		3'h7:
		begin
			R4 = 1'b1;
			G4 = 1'b1;
			B4 = 0;
		end
	endcase
	H4 = (cell_line[2]&cell_line[1])|cell_line[3];
	E4 = (DD_s[0]&col_count[2]&H4)|(DD_s[1]&(~col_count[2])&H4)|(DD_s[2]&col_count[2]&(~H4))|(DD_s[3]&(~col_count[2])&(~H4));
	
	unique case(col_count[2:1])
	2'b00: pair=DD_s[7:6];
	2'b01: pair=DD_s[5:4];
	2'b10: pair=DD_s[3:2];
	2'b11: pair=DD_s[1:0];
	endcase
	
	unique case(pair)
	2'b00:
	begin
		R3=0;
		G3=1'b1;
		B3=0;
	end
	2'b01:
	begin
		R3=1'b1;
		G3=1'b1;
		B3=0;
	end
	2'b10:
	begin
		R3=0;
		G3=0;
		B3=1'b1;
	end
	2'b11:
	begin
		R3=1'b1;
		G3=0;
		B3=0;
	end
	endcase
end

CHR_ROM CHR_inst(.address({DD[5:0], cell_line[3:0]}), .clock(clk_25), .q(MCM_data));

endmodule
