module KEY_MATRIX(input logic[7:0] row_select, key_code, output logic[7:0] key_out);
logic[7:0] column_exp, row_exp;
logic[2:0] column, row;
assign column = key_code[6:4];
assign row = key_code[2:0];
always_comb
begin
	unique case(column)
	3'h0: column_exp = 8'b11111110;
	3'h1: column_exp = 8'b11111101;
	3'h2: column_exp = 8'b11111011;
	3'h3: column_exp = 8'b11110111;
	3'h4: column_exp = 8'b11101111;
	3'h5: column_exp = 8'b11011111;
	3'h6: column_exp = 8'b10111111;
	3'h7: column_exp = 8'b01111111;
	endcase
	
	unique case(row)
	3'h0: row_exp = 8'b11111110;
	3'h1: row_exp = 8'b11111101;
	3'h2: row_exp = 8'b11111011;
	3'h3: row_exp = 8'b11110111;
	3'h4: row_exp = 8'b11101111;
	3'h5: row_exp = 8'b11011111;
	3'h6: row_exp = 8'b10111111;
	3'h7: row_exp = 8'b01111111;
	endcase
	
	if(row_exp == row_select)
		key_out = column_exp;
	else
		key_out = 8'hff;
end
endmodule