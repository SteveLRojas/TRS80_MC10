module MC10(
		input logic RST,
		input logic Clk,
		input logic TAPE_IN,
		input logic[3:0] button,
		output logic TAPE_OUT,
		output logic[3:0] SEG_SEL,
		output logic[3:0] LED,
		output logic[6:0] HEX_OUT,
		output logic beep, R, G, B, HSYNC, VSYNC,
		output logic audio,
		input wire ps2_clk, ps2_data,
		
		output wire SDRAM_CLK,
		output wire SDRAM_CKE,
		output wire SDRAM_CSn,
		output wire SDRAM_WREn,
		output wire SDRAM_CASn,
		output wire SDRAM_RASn,
		output wire[11:0] SDRAM_A,
		output wire[1:0] SDRAM_BA,
		output wire[1:0] SDRAM_DQM,
		inout wire[15:0] SDRAM_DQ);

logic reset, TAPE_S;
logic rw;
logic vdg_clk_25, clk_50, cpu_clk;
logic E_CLK;
logic[15:0] CPU_address;
logic[7:0] DATA_IN, DATA_OUT, DD, PORT_A_OUT;
logic[4:0] PORT_B_OUT;
logic[13:0] DA;
logic[7:0] key_code, key_out;
logic spec_key;
logic[5:0] VDG_control;
logic[7:0] debug;
logic[3:0] button_s;
logic ps2_clk_s, ps2_data_s;

always_ff @ (posedge clk_50)
begin
	reset <= ~RST;
	TAPE_S <= TAPE_IN;
	button_s <= button;
	ps2_clk_s <= ps2_clk;
	ps2_data_s <= ps2_data;
end

assign audio = VDG_control[5];
assign beep = 1'b1;	//silence the thing
assign LED[3]=TAPE_S;
assign LED[2:0] = 3'b111;
assign spec_key = (PORT_A_OUT[0]|key_code[3])&(PORT_A_OUT[2]|button_s[0])&(PORT_A_OUT[7]|key_code[7]);
assign TAPE_OUT = PORT_B_OUT[0];
	
PLL0 PLL_inst(.inclk0(Clk), .c0(cpu_clk), .c1(vdg_clk_25), .c2(clk_50), .c3(SDRAM_CLK));

//************MEMORY SUBSYSTEM***************************************************************************************************************************
//logic[15:0] system_address;
//logic[7:0] arbiter_ram_out, memory_data_out, ram_q, rom_q;
//logic RAM_W, ROM_E, RAM_E, VDG_E, KBD_E, RW_out;
//assign RAM_W = RW_out&((system_address[14]&(~system_address[15]))|(system_address[15]&(~system_address[14])&(~system_address[13])&(~system_address[12])));
//assign ROM_E = E_CLK & CPU_address[14] & CPU_address[15];
//assign RAM_E = E_CLK & ((CPU_address[14]&(~CPU_address[15]))|(CPU_address[15]&(~CPU_address[14])&(~CPU_address[13])&(~CPU_address[12])));
//assign VDG_E = E_CLK & CPU_address[15]&(~CPU_address[14])&(CPU_address[13]|CPU_address[12])&(~rw);
//assign KBD_E = E_CLK & CPU_address[15]&(~CPU_address[14])&(CPU_address[13]|CPU_address[12])&rw;
//
//always_ff @(posedge clk_50)
//begin
//	if(VDG_E)
//		VDG_control <= DATA_OUT[7:2];
//end
//
//always_comb
//begin
//	if(RAM_E)
//		DATA_IN = arbiter_ram_out;
//	else if(ROM_E)
//		DATA_IN = rom_q;
//	else if(KBD_E)
//		DATA_IN = {2'b11, key_out[5:0]};
//	else
//		DATA_IN = system_address[7:0];
//end
//
//RAM RAM_inst(.address({~system_address[14], system_address[13:0]}), .clock(clk_50), .data(memory_data_out), .wren(RAM_W), .q(ram_q));
//ROM ROM_inst(.address(CPU_address[12:0]), .clock(clk_50), .q(rom_q));
//bus_arbiter_gen2 arbiter_inst(
//	.clk(clk_50),
//	.RW_in(~rw & E_CLK),
//	.VDG_address({1'b0, 1'b1, DA}),
//	.CPU_address,
//	.RAM_data_in(ram_q),
//	.CPU_data_in(DATA_OUT),
//	.system_address,
//	.RAM_data_out(arbiter_ram_out),
//	.VDG_data_out(DD), 
//	.memory_data_out, 
//	.RW_out);

logic[15:0] A_data_out, B_data_out;
logic[7:0] ROM_data;
logic[15:0] CPU_address_s;
logic RAM_W, ROM_E, RAM_E, VDG_E, KBD_E;
assign RAM_W = (~rw & E_CLK)&((CPU_address[14]&(~CPU_address[15]))|(CPU_address[15]&(~CPU_address[14])&(~CPU_address[13])&(~CPU_address[12])));
assign ROM_E = E_CLK & CPU_address[14] & CPU_address[15];
assign RAM_E = E_CLK & ((CPU_address[14]&(~CPU_address[15]))|(CPU_address[15]&(~CPU_address[14])&(~CPU_address[13])&(~CPU_address[12])));
assign VDG_E = E_CLK & CPU_address[15]&(~CPU_address[14])&(CPU_address[13]|CPU_address[12])&(~rw);
assign KBD_E = E_CLK & CPU_address[15]&(~CPU_address[14])&(CPU_address[13]|CPU_address[12])&rw;

ROM ROM_inst(.address(CPU_address[12:0]), .clock(clk_50), .q(ROM_data));

always_ff @(posedge clk_50)
begin
	if(VDG_E)
		VDG_control <= DATA_OUT[7:2];
end

always_comb
begin
	if(RAM_E)
		DATA_IN = A_data_out[7:0];
	else if(ROM_E)
		DATA_IN = ROM_data;
	else if(KBD_E)
		DATA_IN = {2'b11, key_out[5:0]};
	else
		DATA_IN = CPU_address[7:0];
end

SDRAM_controller SDRAM_inst(
			.clk(clk_50),
			.reset,
			.HSYNC,
			.A_address({7'h00, ~CPU_address[14], CPU_address[13:0]}),
			.A_write(RAM_W),
			.A_data_out,
			.A_data_in({8'h00, DATA_OUT}),
			.B_address({8'h00, DA}),
			.B_data_out,
			.SDRAM_CKE,
			.SDRAM_CSn,
			.SDRAM_WREn,
			.SDRAM_CASn,
			.SDRAM_RASn,
			.SDRAM_A,
			.SDRAM_BA,
			.SDRAM_DQM,
			.SDRAM_DQ);
assign DD = B_data_out[7:0];
//*******************************************************************************************************************************************************

MULTIPLEXED_HEX_DRIVER multiHEX(.Clk(clk_50), .SEG3(debug[7:4]), .SEG2(debug[3:0]), .SEG1(key_code[7:4]), .SEG0(key_code[3:0]), .SEG_SEL, .HEX_OUT);
PS2_keyboard keyboard(.clk(clk_50), .reset, .ps2_clk(ps2_clk_s), .ps2_data(ps2_data_s), .key_code, .debug);
KEY_MATRIX MATRIX(.row_select(PORT_A_OUT), .key_code, .key_out);

MC6803_gen2 CPU0(
		.clk(cpu_clk),
		.RST(reset | (~button_s[3])),
		.hold(~button_s[2]),
		.halt(1'b0),
		.nmi(~button_s[1]),
		.PORT_A_IN(PORT_A_OUT),
		.PORT_B_IN({TAPE_S, 2'b11, spec_key, 1'b1}),
		.DATA_IN,
		.PORT_A_OUT,
		.PORT_B_OUT,
		.ADDRESS(CPU_address),
		.DATA_OUT,
		.E_CLK,
		.rw,
		.irq(1'b0));

//MC6847_gen2 VDG(.DD, .DA, .clk_25(vdg_clk_25), .clk_10(vdg_clk_10), .reset, .R, .G, .B, .HSYNC, .VSYNC, .AG(VDG_control[3]), .SA(DD[7]), .INV(DD[6]));
MC6847_gen3 VDG(.DD, .DA, .clk_25(vdg_clk_25), .reset, .R, .G, .B, .HSYNC, .VSYNC, .AG(VDG_control[3]), .SA(DD[7]), .INV(DD[6]));

endmodule
