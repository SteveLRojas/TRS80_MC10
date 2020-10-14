create_clock -period 20ns [get_ports Clk]
derive_pll_clocks
derive_clock_uncertainty
set_false_path -from * -to [get_ports {LED* beep audio SEG_SEL* HEX_OUT*}]
set_input_delay -clock PLL_inst|altpll_component|auto_generated|pll1|clk[2] -max 3 [all_inputs]
set_input_delay -clock PLL_inst|altpll_component|auto_generated|pll1|clk[2] -min 2 [all_inputs]
set_output_delay -clock PLL_inst|altpll_component|auto_generated|pll1|clk[2] -max 3 [all_outputs]
set_output_delay -clock PLL_inst|altpll_component|auto_generated|pll1|clk[2] -min 2 [all_outputs]
#set_false_path -from MC6803_gen2:CPU0|cpu01:cpu01_inst|md* -to bus_arbiter_gen2:arbiter_inst|memory_data_out*
#set_false_path -from MC6803_gen2:CPU0|cpu01:cpu01_inst|state.pulb_state -to bus_arbiter_gen2:arbiter_inst|memory_data_out*
#set_false_path -from MC6803_gen2:CPU0|cpu01:cpu01_inst|accb* -to bus_arbiter_gen2:arbiter_inst|memory_data_out*
#set_false_path -from MC6803_gen2:CPU0|cpu01:cpu01_inst|acca* -to bus_arbiter_gen2:arbiter_inst|memory_data_out*
#set_false_path -from MC6803_gen2:CPU0|cpu01:cpu01_inst|pc* -to bus_arbiter_gen2:arbiter_inst|memory_data_out*
#set_false_path -from MC6803_gen2:CPU0|cpu01:cpu01_inst|cc* -to bus_arbiter_gen2:arbiter_inst|memory_data_out*
#set_false_path -from MC6803_gen2:CPU0|cpu01:cpu01_inst|sp* -to bus_arbiter_gen2:arbiter_inst|system_address*