module Testbench();

timeunit 10ns;
timeprecision 1ns;
logic clk;
logic reset;
logic[7:0] CPU_data_in, CPU_data_out, ROM_data_in, ROM_data_out, RAM_data_in, RAM_data_out;
logic[15:0] CPU_address;
logic[12:0] ROM_address;
logic[14:0] RAM_address;
logic RAM_write;
logic ROM_write;
logic rw, E_CLK;
logic[7:0] key_code;	//key code is the data from the microcontroller
logic spec_key;
logic[7:0] PORT_A_OUT;
logic break_button;	//break key is inverted
logic[7:0] key_out;	//output from key matrix
logic KBD_E;
logic CPU_clk;
logic DISP_E;
logic[6:0] ASCII_CODE;
always_comb
begin
if(CPU_address < 16'h4200 && CPU_address >= 16'h4000 && E_CLK)
	DISP_E = 1'b1;
else
	DISP_E = 1'b0;
ASCII_CODE = {(~CPU_data_out[5]), CPU_data_out[5:0]};
end
assign KBD_E = E_CLK & CPU_address[15]&(~CPU_address[14])&(CPU_address[13]|CPU_address[12])&rw;
assign spec_key = (PORT_A_OUT[0]|key_code[3])&(PORT_A_OUT[2]|break_button)&(PORT_A_OUT[7]|key_code[7]);
//instantiate test ROM
test_rom ROM(
		.address(ROM_address),
		.clock(clk),
		.data(ROM_data_in),
		.wren(ROM_write),
		.q(ROM_data_out));
//instantiate RAM
test_ram RAM(RAM_address, clk, RAM_data_in, RAM_write, RAM_data_out);
//instantiate CPU
MC6803_gen2 CPU0(.clk(CPU_clk), .RST(reset), .hold(1'b0), .halt(1'b0), .nmi(1'b0), .irq(1'b0),
.PORT_A_IN(PORT_A_OUT), .PORT_B_IN({1'b1, 2'b11, spec_key, 1'b1}), .DATA_IN(CPU_data_in), .PORT_A_OUT,
.ADDRESS(CPU_address), .DATA_OUT(CPU_data_out), .E_CLK, .rw);
//instantiate key matrix
KEY_MATRIX MATRIX(.row_select(PORT_A_OUT), .key_code, .key_out);
always_comb
begin
if (KBD_E)
begin
	CPU_data_in = key_out;
	ROM_write = 1'b0;
	RAM_write = 1'b0;
end
else if(CPU_address >= 16'hc000)
begin
	CPU_data_in = ROM_data_out;
	ROM_write = ~rw & E_CLK;
	RAM_write = 1'b0;
end
else if(CPU_address <= 16'h8fff && CPU_address >= 16'h4000)
begin
	CPU_data_in = RAM_data_out;
	ROM_write = 1'b0;
	RAM_write = ~rw & E_CLK;
end
else
begin
	CPU_data_in = CPU_address[7:0];
	ROM_write = 1'b0;
	RAM_write = 1'b0;
end
ROM_address = CPU_address[12:0];
RAM_address = CPU_address[14:0];
ROM_data_in = CPU_data_out;
RAM_data_in = CPU_data_out;
end
always begin: CLOCK_GENERATION
#1 clk =  ~clk;
end
always begin: CPU_CLOCK_GENERATION
#2 CPU_clk = ~CPU_clk;
end
initial begin: CLOCK_INITIALIZATION
	clk = 0;
	CPU_clk = 0;
end

initial begin: TEST_VECTORS
//initial conditions
reset = 1'b1;
break_button = 1'b1;
key_code = 8'hff;

#4 reset = 1'b0;
#2500000 key_code = 8'b10001011;	//c
#100000 key_code = 8'hff;
#100000 key_code = 8'b10011100;	//l
#100000 key_code = 8'hff;
#100000 key_code = 8'b10011111;	//o
#100000 key_code = 8'hff;
#100000 key_code = 8'b10001001;	//a
#100000 key_code = 8'hff;
#100000 key_code = 8'b10001100;	//d
#100000 key_code = 8'hff;
#100000 key_code = 8'b10011101;	//m
#100000 key_code = 8'hff;
#100000 key_code = 8'b10111110;	//enter
#100000 key_code = 8'hff;
end
endmodule
