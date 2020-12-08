`include "6801_types.sv"
module cpu01(	
		input logic clk,
		input logic rst,
		output logic rw,
		output logic vma,
		output logic[15:0]address,
		input logic[7:0] data_in,
		output logic[7:0] data_out,
		input logic hold,
		input logic halt,
		input logic irq,
		input logic nmi,
		input logic irq_icf,
		input logic irq_ocf,
		input logic irq_tof,
		input logic irq_sci);

logic[7:0] op_code;
logic[7:0] acca;
logic[7:0] accb;
logic[7:0] cc;
logic[7:0] cc_out;
logic[15:0] xreg;
logic[15:0] sp;
logic[15:0] ea;
logic[15:0] pc;
logic[15:0] md;
logic[15:0] left;
logic[15:0] right;
logic[15:0] out_alu;
logic[2:0] iv;
logic nmi_req;
logic nmi_ack;

pc_type pc_ctrl;
ea_type ea_ctrl; 
op_type op_ctrl;
md_type md_ctrl;
acca_type acca_ctrl;
accb_type accb_ctrl;
ix_type ix_ctrl;
cc_type cc_ctrl;
sp_type sp_ctrl;
iv_type iv_ctrl;
left_type left_ctrl;
right_type right_ctrl;
alu_type alu_ctrl;
addr_type addr_ctrl;
dout_type dout_ctrl;
nmi_type nmi_ctrl;

////////////////////////////////////
//
// Detect Edge of NMI interrupt
//
////////////////////////////////////
always_ff @(posedge clk)
begin
    if (hold == 1'b1)
	   nmi_req <= nmi_req;
	 else if (rst==1'b1)
	   nmi_req <= 1'b0;
    else if (nmi==1'b1 && nmi_ack==1'b0)
	    nmi_req <= 1'b1;
	 else if (nmi==1'b0 && nmi_ack==1'b1)
	    nmi_req <= 1'b0;
	 else
	    nmi_req <= nmi_req;
end

//// Address bus multiplexer
address_bus_multiplexer abm(addr_ctrl, iv, ea, pc, sp, address, vma, rw);

//// Data Bus output
data_bus_output dbo(md,	acca, accb,	xreg,	cc, pc, dout_ctrl, data_out);

//// Program Counter Control
program_counter_6801 PC01(clk, hold, pc_ctrl, ea, data_in, pc);

//// Effective Address  Control
effective_address_6801 EA01(clk, hold, ea_ctrl, accb, ea, data_in, xreg);

//// Accumulator A
accumulator_a_6801 acca_inst(clk, hold, acca_ctrl, data_in, out_alu, acca);

//// Accumulator B
accumulator_b_6801 accb_inst(clk, hold, accb_ctrl, data_in, out_alu, accb);

//// X Index register
XREG_6801 XREG_inst(clk, hold, ix_ctrl, out_alu, data_in, xreg);

//// stack pointer
SP_6801 SP_inst(clk, hold, sp_ctrl, out_alu, sp);

//// Memory Data
data_fetch_6801 data_fetch_01(clk, hold, md_ctrl, data_in, out_alu, md);

//// Condition Codes
CC_6801 CC01(clk, hold, cc_ctrl, data_in, cc_out, cc);

//// interrupt vector
IV_control_6801 IV_inst(clk, hold, iv_ctrl, iv);

//// op code fetch
opcode_fetch_6801 opcode_fetch_01(clk, hold, op_ctrl, data_in, op_code);

//// Left Mux
left_mux_6801 left_mux01(left_ctrl, acca, accb, xreg, sp, md, left);

//// Right Mux
right_mux_6801 right_mux01(right_ctrl, accb, md, right);

//// Arithmetic Logic Unit
ALU6801 ALU01(.alu_ctrl, .cc, .cc_out, .left, .right, .out_alu);

// Nmi mux
NMI_mux_6801 NMI_mux_inst(clk, hold, nmi_ctrl, nmi_ack);

// state sequencer
state_sequencer_6801 state_sequencer01(
			clk,
			rst,
			halt,
			hold,
			ea,
			op_code,
			cc,
			nmi_req,
			nmi_ack,
			irq,
			irq_icf,
			irq_ocf,
			irq_tof,
			irq_sci,
			pc_ctrl,
			ea_ctrl, 
			op_ctrl,
			md_ctrl,
			acca_ctrl,
			accb_ctrl,
			ix_ctrl,
			cc_ctrl,
			sp_ctrl,
			iv_ctrl,
			left_ctrl,
			right_ctrl,
			alu_ctrl,
			addr_ctrl,
			dout_ctrl,
			nmi_ctrl);
			
endmodule
