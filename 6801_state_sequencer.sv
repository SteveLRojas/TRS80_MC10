module state_sequencer_6801(
			input logic clk,
			input logic rst,
			input logic halt,
			input logic hold,
			input logic[15:0] ea,
			input logic[7:0] op_code,
			input logic[7:0] cc,
			input logic nmi_req,
			input logic nmi_ack,
			input logic irq,
			input logic irq_icf,
			input logic irq_ocf,
			input logic irq_tof,
			input logic irq_sci,
			output pc_type pc_ctrl,
			output ea_type ea_ctrl, 
			output op_type op_ctrl,
			output md_type md_ctrl,
			output acca_type acca_ctrl,
			output accb_type accb_ctrl,
			output ix_type ix_ctrl,
			output cc_type cc_ctrl,
			output sp_type sp_ctrl,
			output iv_type iv_ctrl,
			output left_type left_ctrl,
			output right_type right_ctrl,
			output alu_type alu_ctrl,
			output addr_type addr_ctrl,
			output dout_type dout_ctrl,
			output nmi_type nmi_ctrl);

state_type state;
state_type next_state;

always_comb
  	begin
		  case (state)
          reset_state:        //  released from reset
			 begin
			    // reset the registers
             op_ctrl    = reset_op;
				 acca_ctrl  = reset_acca;
				 accb_ctrl  = reset_accb;
				 ix_ctrl    = reset_ix;
		       sp_ctrl    = latch_sp;
		       pc_ctrl    = reset_pc;
	 		    ea_ctrl    = reset_ea;
				 md_ctrl    = reset_md;
				 iv_ctrl    = reset_iv;
				 nmi_ctrl   = reset_nmi;
				 // idle the ALU
             left_ctrl  = acca_left;
				 right_ctrl = zero_right;
				 alu_ctrl   = alu_nop;
             cc_ctrl    = reset_cc;
				 // idle the bus
				 dout_ctrl  = md_lo_dout;
             addr_ctrl  = idle_ad;
	 	       next_state = vect_hi_state;
			end

			 //
			 // Jump via interrupt vector
			 // iv holds interrupt type
			 // fetch PC hi from vector location
			 //
          vect_hi_state:
			 begin
			    // default the registers
             op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             md_ctrl    = latch_md;
             ea_ctrl    = latch_ea;
             iv_ctrl    = latch_iv;
				 // idle the ALU
             left_ctrl  = acca_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
				 // fetch pc low interrupt vector
		       pc_ctrl    = pull_hi_pc;
             addr_ctrl  = int_hi_ad;
             dout_ctrl  = pc_hi_dout;
	 	       next_state = vect_lo_state;
			end
			 //
			 // jump via interrupt vector
			 // iv holds vector type
			 // fetch PC lo from vector location
			 //
          vect_lo_state:
			 begin
			    // default the registers
             op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             md_ctrl    = latch_md;
             ea_ctrl    = latch_ea;
             iv_ctrl    = latch_iv;
				 // idle the ALU
             left_ctrl  = acca_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
				 // fetch the vector low byte
		       pc_ctrl    = pull_lo_pc;
             addr_ctrl  = int_lo_ad;
             dout_ctrl  = pc_lo_dout;
	 	       next_state = fetch_state;
			end

			 //
			 // Here to fetch an instruction
			 // PC points to opcode
			 // Should service interrupt requests at this point
			 // either from the timer
			 // or from the external input.
			 //
          fetch_state:
			 begin
			      case (op_code[7:4])
				   4'b0000,
	                 4'b0001,
	                 4'b0010,  // branch conditional
	                 4'b0011,
	                 4'b0100,  // acca single op
	                 4'b0101,  // accb single op
	                 4'b0110,  // indexed single op
	                 4'b0111: // extended single op
						  begin
					  // idle ALU
                 left_ctrl  = acca_left;
					  right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
					  cc_ctrl    = latch_cc;
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
							end

	            4'b1000, // acca immediate
	                 4'b1001, // acca direct
	                 4'b1010, // acca indexed
                    4'b1011: // acca extended
						  begin
				     case (op_code[3:0])
					  4'b0000: // suba
						begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sub8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						 end
					  4'b0001: // cmpa
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sub8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0010: // sbca
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sbc;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0011: // subd
					  begin
					    left_ctrl   = accd_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sub16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_hi_acca;
						 accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0100: // anda
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_and;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0101: // bita
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_and;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0110: // ldaa
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_ld8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0111: // staa
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_st8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1000: // eora
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_eor;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1001: // adca
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_adc;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1010: // oraa
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_ora;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1011: // adda
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_add8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1100: // cpx
					  begin
					    left_ctrl   = ix_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sub16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1101: // bsr / jsr
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_nop;
						 cc_ctrl     = latch_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1110: // lds
					  begin
					    left_ctrl   = sp_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_ld16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
						 sp_ctrl     = load_sp;
						end
					  4'b1111: // sts
					  begin
					    left_ctrl   = sp_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_st16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  default:
					  begin
					    left_ctrl   = acca_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_nop;
						 cc_ctrl     = latch_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  endcase
					  end
	            4'b1100, // accb immediate
	                 4'b1101, // accb direct
	                 4'b1110, // accb indexed
                    4'b1111: // accb extended
					begin
				     case (op_code[3:0])
					  4'b0000: // subb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sub8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0001: // cmpb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sub8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0010: // sbcb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_sbc;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0011: // addd
					  begin
					    left_ctrl   = accd_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_add16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_hi_acca;
						 accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0100: // andb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_and;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0101: // bitb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_and;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0110: // ldab
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_ld8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b0111: // stab
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_st8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1000: // eorb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_eor;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1001: // adcb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_adc;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1010: // orab
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_ora;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1011: // addb
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_add8;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1100: // ldd
					  begin
					    left_ctrl   = accd_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_ld16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = load_hi_acca;
                   accb_ctrl   = load_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1101: // std
					  begin
					    left_ctrl   = accd_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_st16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  4'b1110: // ldx
					  begin
					    left_ctrl   = ix_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_ld16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = load_ix;
						 sp_ctrl     = latch_sp;
						end
					  4'b1111: // stx
					  begin
					    left_ctrl   = ix_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_st16;
						 cc_ctrl     = load_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  default:
					  begin
					    left_ctrl   = accb_left;
					    right_ctrl  = md_right;
					    alu_ctrl    = alu_nop;
						 cc_ctrl     = latch_cc;
					    acca_ctrl   = latch_acca;
                   accb_ctrl   = latch_accb;
                   ix_ctrl     = latch_ix;
                   sp_ctrl     = latch_sp;
						end
					  endcase
					end
	            default:
					begin
					  left_ctrl   = accd_left;
					  right_ctrl  = md_right;
					  alu_ctrl    = alu_nop;
					  cc_ctrl     = latch_cc;
					  acca_ctrl   = latch_acca;
                 accb_ctrl   = latch_accb;
                 ix_ctrl     = latch_ix;
                 sp_ctrl     = latch_sp;
					 end
              endcase
             md_ctrl    = latch_md;
				 // fetch the op code
			    op_ctrl    = fetch_op;
             ea_ctrl    = reset_ea;
             addr_ctrl  = fetch_ad;
             dout_ctrl  = md_lo_dout;
		  	    iv_ctrl    = latch_iv;
				if (halt == 1'b1)
				begin
					pc_ctrl    = latch_pc;
				   nmi_ctrl   = latch_nmi;
			      next_state = halt_state;
				end
				// service non maskable interrupts
			   else if (nmi_req == 1'b1 && nmi_ack == 1'b0)
				begin
               pc_ctrl    = latch_pc;
				   nmi_ctrl   = set_nmi;
			      next_state = int_pcl_state;
				end
				// service maskable interrupts
			   else
				begin
					//
					// nmi request is not cleared until nmi input goes low
					//
				   if(nmi_req == 1'b0 && nmi_ack==1'b1)
				     nmi_ctrl = reset_nmi;
					else
					  nmi_ctrl = latch_nmi;
					//
					// IRQ is level sensitive
					//
				   if ((irq == 1'b1 || irq_icf == 1'b1 || irq_ocf == 1'b1 || irq_tof == 1'b1 || irq_sci == 1'b1) && cc[IBIT] == 1'b0)
					begin
                 pc_ctrl    = latch_pc;
			        next_state = int_pcl_state;
					end
               else
					begin
				   // Advance the PC to fetch next instruction byte
                 pc_ctrl    = inc_pc;
			        next_state = decode_state;
					end
				end
			end
			 //
			 // Here to decode instruction
			 // and fetch next byte of intruction
			 // whether it be necessary or not
			 //
          decode_state:
			 begin
				 // fetch first byte of address or immediate data
             ea_ctrl    = fetch_first_ea;
             addr_ctrl  = fetch_ad;
             dout_ctrl  = md_lo_dout;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             iv_ctrl    = latch_iv;
			    case (op_code[7:4])
				 4'b0000:
				 begin
				   md_ctrl    = fetch_first_md;
               sp_ctrl    = latch_sp;
               pc_ctrl    = latch_pc;
  	            case (op_code[3:0])
		         4'b0001: // nop
					begin
					  left_ctrl  = accd_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b0100: // lsrd
					begin
					  left_ctrl  = accd_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_lsr16;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = load_hi_acca;
					  accb_ctrl  = load_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b0101: // lsld
					begin
					  left_ctrl  = accd_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_lsl16;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = load_hi_acca;
					  accb_ctrl  = load_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b0110: // tap
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_tap;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b0111: // tpa
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_tpa;
                 cc_ctrl    = latch_cc;
					  acca_ctrl  = load_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b1000: // inx
					begin
					  left_ctrl  = ix_left;
	              right_ctrl = plus_one_right;
					  alu_ctrl   = alu_inx;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = load_ix;
					 end
		         4'b1001: // dex
					begin
					  left_ctrl  = ix_left;
	              right_ctrl = plus_one_right;
					  alu_ctrl   = alu_dex;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = load_ix;
					 end
		         4'b1010: // clv
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_clv;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b1011: // sev
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_sev;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b1100: // clc
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_clc;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b1101: // sec
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_sec;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b1110: // cli
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_cli;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         4'b1111: // sei
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_sei;
                 cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
               default:
					begin
					  left_ctrl  = acca_left;
                 right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = latch_accb;
					  ix_ctrl    = latch_ix;
					 end
		         endcase
					next_state = fetch_state;
				end
				 // acca / accb inherent instructions
	          4'b0001:
				 begin
				   md_ctrl    = fetch_first_md;
               ix_ctrl    = latch_ix;
               sp_ctrl    = latch_sp;
               pc_ctrl    = latch_pc;
					left_ctrl  = acca_left;
	            right_ctrl = accb_right;
	            case (op_code[3:0])
		         4'b0000: // sba
					begin
					  alu_ctrl   = alu_sub8;
					  cc_ctrl    = load_cc;
					  acca_ctrl  = load_acca;
                 accb_ctrl  = latch_accb;
					 end
		         4'b0001: // cba
					begin
					  alu_ctrl   = alu_sub8;
					  cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
					 end
		         4'b0110: // tab
					begin
					  alu_ctrl   = alu_st8;
					  cc_ctrl    = load_cc;
					  acca_ctrl  = latch_acca;
					  accb_ctrl  = load_accb;
					 end
		         4'b0111: // tba
					begin
					  alu_ctrl   = alu_ld8;
					  cc_ctrl    = load_cc;
					  acca_ctrl  = load_acca;
                 accb_ctrl  = latch_accb;
					 end
		         4'b1001: // daa
					begin
					  alu_ctrl   = alu_daa;
					  cc_ctrl    = load_cc;
					  acca_ctrl  = load_acca;
                 accb_ctrl  = latch_accb;
					 end
		         4'b1011: // aba
					begin
					  alu_ctrl   = alu_add8;
					  cc_ctrl    = load_cc;
					  acca_ctrl  = load_acca;
                 accb_ctrl  = latch_accb;
					 end
		         default:
					begin
					  alu_ctrl   = alu_nop;
					  cc_ctrl    = latch_cc;
					  acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
					 end
		         endcase
					next_state = fetch_state;
				end
	          4'b0010: // branch conditional
				 begin
				   md_ctrl    = fetch_first_md;
					acca_ctrl  = latch_acca;
               accb_ctrl  = latch_accb;
               ix_ctrl    = latch_ix;
               sp_ctrl    = latch_sp;
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
					// increment the pc
               pc_ctrl    = inc_pc;
               case (op_code[3:0])
		         4'b0000: // bra
                 next_state = branch_state;
		         4'b0001: // brn
					  next_state = fetch_state;
		         4'b0010: // bhi
					begin
					  if ((cc[CBIT] | cc[ZBIT]) == 1'b0)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b0011: // bls
					begin
					  if ((cc[CBIT] | cc[ZBIT]) == 1'b1)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b0100: // bcc/bhs
					begin
					  if (cc[CBIT] == 1'b0)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b0101: // bcs/blo
					begin
					  if (cc[CBIT] == 1'b1)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					 end
		         4'b0110: // bne
					begin
					  if (cc[ZBIT] == 1'b0)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					 end
		         4'b0111: // beq
					begin
					  if (cc[ZBIT] == 1'b1)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b1000: // bvc
					begin
					  if (cc[VBIT] == 1'b0)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b1001: // bvs
					begin
					  if (cc[VBIT] == 1'b1)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b1010: // bpl
					begin
					  if (cc[NBIT] == 1'b0)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b1011: // bmi
					begin
					  if (cc[NBIT] == 1'b1)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					 end
		         4'b1100: // bge
					begin
					  if ((cc[NBIT] ^ cc[VBIT]) == 1'b0)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b1101: // blt
					begin
					  if ((cc[NBIT] ^ cc[VBIT]) == 1'b1)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b1110: // bgt
					begin
					  if ((cc[ZBIT] | (cc[NBIT] ^ cc[VBIT])) == 1'b0)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         4'b1111: // ble
					begin
					  if ((cc[ZBIT] | (cc[NBIT] ^ cc[VBIT])) == 1'b1)
					    next_state = branch_state;
					  else
					    next_state = fetch_state;
					end
		         default:
					  next_state = fetch_state;
		         endcase
					end
				 //
				 // Single byte stack operators
				 // Do not advance PC
				 //
	          4'b0011:
				 begin
				   md_ctrl    = fetch_first_md;
					acca_ctrl  = latch_acca;
               accb_ctrl  = latch_accb;
               pc_ctrl    = latch_pc;
	            case (op_code[3:0])
		         4'b0000: // tsx
					begin
		            left_ctrl  = sp_left;
		            right_ctrl = plus_one_right;
						alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = load_ix;
                  sp_ctrl    = latch_sp;
						next_state = fetch_state;
					end
		         4'b0001: // ins
					begin
                  left_ctrl  = sp_left;
                  right_ctrl = plus_one_right;
                  alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
                  sp_ctrl    = load_sp;
						next_state = fetch_state;
					end
		         4'b0010: // pula
					begin
                  left_ctrl  = sp_left;
                  right_ctrl = plus_one_right;
                  alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
                  sp_ctrl    = load_sp;
						next_state = pula_state;
					end
		         4'b0011: // pulb
					begin
                  left_ctrl  = sp_left;
                  right_ctrl = plus_one_right;
                  alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
                  sp_ctrl    = load_sp;
						next_state = pulb_state;
					end
		         4'b0100: // des
					begin
                  // decrement sp
                  left_ctrl  = sp_left;
                  right_ctrl = plus_one_right;
                  alu_ctrl   = alu_sub16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
                  sp_ctrl    = load_sp;
						next_state = fetch_state;
					end
		         4'b0101: // txs
					begin
		            left_ctrl  = ix_left;
		            right_ctrl = plus_one_right;
						alu_ctrl   = alu_sub16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = load_sp;
						next_state = fetch_state;
					end
		         4'b0110: // psha
					begin
		            left_ctrl  = sp_left;
		            right_ctrl = zero_right;
						alu_ctrl   = alu_nop;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = latch_sp;
						next_state = psha_state;
					end
		         4'b0111: // pshb
					begin
		            left_ctrl  = sp_left;
		            right_ctrl = zero_right;
						alu_ctrl   = alu_nop;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = latch_sp;
						next_state = pshb_state;
					end
		         4'b1000: // pulx
					begin
                  left_ctrl  = sp_left;
                  right_ctrl = plus_one_right;
                  alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
                  sp_ctrl    = load_sp;
						next_state = pulx_hi_state;
					end
		         4'b1001: // rts
					begin
                  left_ctrl  = sp_left;
                  right_ctrl = plus_one_right;
                  alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
                  sp_ctrl    = load_sp;
						next_state = rts_hi_state;
					end
		         4'b1010: // abx
					begin
		            left_ctrl  = ix_left;
		            right_ctrl = accb_right;
						alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = load_ix;
                  sp_ctrl    = latch_sp;
						next_state = fetch_state;
					end
		         4'b1011: // rti
					begin
                  left_ctrl  = sp_left;
                  right_ctrl = plus_one_right;
                  alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
                  sp_ctrl    = load_sp;
						next_state = rti_cc_state;
					end
		         4'b1100: // pshx
					begin
		            left_ctrl  = sp_left;
		            right_ctrl = zero_right;
						alu_ctrl   = alu_nop;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = latch_sp;
						next_state = pshx_lo_state;
					end
		         4'b1101: // mul
					begin
		            left_ctrl  = acca_left;
		            right_ctrl = accb_right;
						alu_ctrl   = alu_add16;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = latch_sp;
						next_state = mul_state;
					end
		         4'b1110: // wai
					begin
		            left_ctrl  = sp_left;
		            right_ctrl = zero_right;
						alu_ctrl   = alu_nop;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = latch_sp;
						next_state = int_pcl_state;
					end
		         4'b1111: // swi
					begin
		            left_ctrl  = sp_left;
		            right_ctrl = zero_right;
						alu_ctrl   = alu_nop;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = latch_sp;
						next_state = int_pcl_state;
					end
		         default:
					begin
		            left_ctrl  = sp_left;
		            right_ctrl = zero_right;
						alu_ctrl   = alu_nop;
					   cc_ctrl    = latch_cc;
						ix_ctrl    = latch_ix;
						sp_ctrl    = latch_sp;
						next_state = fetch_state;
					end
		         endcase
					end
				 //
				 // Accumulator A Single operand
				 // source = Acc A dest = Acc A
				 // Do not advance PC
				 //
	          4'b0100: // acca single op
				 begin
				   md_ctrl    = fetch_first_md;
               accb_ctrl  = latch_accb;
               pc_ctrl    = latch_pc;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
		         left_ctrl  = acca_left;
	            case (op_code[3:0])
		         4'b0000: // neg
					begin
					  right_ctrl = zero_right;
					  alu_ctrl   = alu_neg;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					 end
 	            4'b0011: // com
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_com;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b0100: // lsr
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_lsr8;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b0110: // ror
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_ror8;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b0111: // asr
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_asr8;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b1000: // asl
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_asl8;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b1001: // rol
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_rol8;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b1010: // dec
					begin
		           right_ctrl = plus_one_right;
					  alu_ctrl   = alu_dec;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b1011: // undefined
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
					  acca_ctrl  = latch_acca;
					  cc_ctrl    = latch_cc;
					end
		         4'b1100: // inc
					begin
		           right_ctrl = plus_one_right;
					  alu_ctrl   = alu_inc;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b1101: // tst
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_tst;
					  acca_ctrl  = latch_acca;
					  cc_ctrl    = load_cc;
					end
		         4'b1110: // jmp
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
					  acca_ctrl  = latch_acca;
					  cc_ctrl    = latch_cc;
					end
		         4'b1111: // clr
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_clr;
					  acca_ctrl  = load_acca;
					  cc_ctrl    = load_cc;
					end
		         default:
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
					  acca_ctrl  = latch_acca;
					  cc_ctrl    = latch_cc;
					end
		         endcase
				   next_state = fetch_state;
					end
				 //
				 // single operand acc b
				 // Do not advance PC
				 //
	          4'b0101:
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
               pc_ctrl    = latch_pc;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
		         left_ctrl  = accb_left;
	            case (op_code[3:0])
		         4'b0000: // neg
					begin
					  right_ctrl = zero_right;
					  alu_ctrl   = alu_neg;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
 	            4'b0011: // com
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_com;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b0100: // lsr
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_lsr8;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b0110: // ror
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_ror8;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b0111: // asr
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_asr8;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b1000: // asl
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_asl8;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b1001: // rol
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_rol8;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b1010: // dec
					begin
		           right_ctrl = plus_one_right;
					  alu_ctrl   = alu_dec;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b1011: // undefined
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
					  accb_ctrl  = latch_accb;
					  cc_ctrl    = latch_cc;
					end
		         4'b1100: // inc
					begin
		           right_ctrl = plus_one_right;
					  alu_ctrl   = alu_inc;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b1101: // tst
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_tst;
					  accb_ctrl  = latch_accb;
					  cc_ctrl    = load_cc;
					end
		         4'b1110: // jmp
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
					  accb_ctrl  = latch_accb;
					  cc_ctrl    = latch_cc;
					end
		         4'b1111: // clr
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_clr;
					  accb_ctrl  = load_accb;
					  cc_ctrl    = load_cc;
					end
		         default:
					begin
		           right_ctrl = zero_right;
					  alu_ctrl   = alu_nop;
					  accb_ctrl  = latch_accb;
					  cc_ctrl    = latch_cc;
					end
		         endcase
				   next_state = fetch_state;
					end
				 //
				 // Single operand indexed
				 // Two byte instruction so advance PC
				 // EA should hold index offset
				 //
	          4'b0110: // indexed single op
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc 
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
				   next_state = indexed_state;
				end
             //
				 // Single operand extended addressing
				 // three byte instruction so advance the PC
				 // Low order EA holds high order address
				 //
	          4'b0111: // extended single op
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
				   next_state = extended_state;
				end

	          4'b1000: // acca immediate
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
				   // increment the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
					case (op_code[3:0])
               4'b0011, // subdd #
					     4'b1100, // cpx #
					     4'b1110: // lds #
					  next_state = immediate16_state;
					4'b1101: // bsr
					  next_state = bsr_state;
					default:
				     next_state = fetch_state;
               endcase
					end

	          4'b1001: // acca direct
				 begin
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               pc_ctrl    = inc_pc;
					case (op_code[3:0])
					4'b0111:  // staa direct
					begin
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_st8;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = load_md;
				     next_state = write8_state;
					end
					4'b1111: // sts direct
					begin
                 left_ctrl  = sp_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_st16;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = load_md;
				     next_state = write16_state;
					end
					4'b1101: // jsr direct
					begin
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_nop;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = fetch_first_md;
					  next_state = jsr_state;
					end
					default:
					begin
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_nop;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = fetch_first_md;
				     next_state = read8_state;
					end
               endcase
					end

	          4'b1010: // acca indexed
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
				   next_state = indexed_state;
				end

             4'b1011: // acca extended
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
				   next_state = extended_state;
				end

	          4'b1100: // accb immediate
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
					case (op_code[3:0])
               4'b0011, // addd #
					     4'b1100, // ldd #
					     4'b1110: // ldx #
					  next_state = immediate16_state;
					default:
				     next_state = fetch_state;
               endcase
					end

	          4'b1101: // accb direct
				 begin
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               pc_ctrl    = inc_pc;
					case (op_code[3:0])
					4'b0111:  // stab direct
					begin
                 left_ctrl  = accb_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_st8;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = load_md;
				     next_state = write8_state;
					end
					4'b1101: // std direct
					begin
                 left_ctrl  = accd_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_st16;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = load_md;
					  next_state = write16_state;
					end
					4'b1111: // stx direct
					begin
                 left_ctrl  = ix_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_st16;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = load_md;
				     next_state = write16_state;
					end
					default:
					begin
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_nop;
					  cc_ctrl    = latch_cc;
				     md_ctrl    = fetch_first_md;
				     next_state = read8_state;
					end
               endcase
					end

	          4'b1110: // accb indexed
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
				   next_state = indexed_state;
				end

             4'b1111: // accb extended
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// increment the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
					cc_ctrl    = latch_cc;
               pc_ctrl    = inc_pc;
				   next_state = extended_state;
				end

	          default:
				 begin
				   md_ctrl    = fetch_first_md;
               acca_ctrl  = latch_acca;
					accb_ctrl  = latch_accb;
				   ix_ctrl    = latch_ix;
				   sp_ctrl    = latch_sp;
					// idle the pc
               left_ctrl  = acca_left;
               right_ctrl = zero_right;
               alu_ctrl   = alu_nop;
  					cc_ctrl    = latch_cc;
               pc_ctrl    = latch_pc;
 		         next_state = fetch_state;
				end
             endcase
				 end

			  immediate16_state:
			  begin
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
			    op_ctrl    = latch_op;
             iv_ctrl    = latch_iv;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 //ea_ctrl		= fetch_next_ea;	//steve
				 // increment pc
             left_ctrl  = acca_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
             pc_ctrl    = inc_pc;
				 // fetch next immediate byte
			    md_ctrl    = fetch_next_md;
             addr_ctrl  = fetch_ad;
             dout_ctrl  = md_lo_dout;
				 next_state = fetch_state;
			end
           //
			  // ea holds 8 bit index offet
			  // calculate the effective memory address
			  // using the alu
			  //
           indexed_state:
			  begin
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             pc_ctrl    = latch_pc;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
				 // calculate effective address from index reg
             // index offest is not sign extended
             ea_ctrl    = add_ix_ea;
				 // idle the bus
             addr_ctrl  = idle_ad;
             dout_ctrl  = md_lo_dout;
				 // work out next state
				 case (op_code[7:4])
				 4'b0110: // single op indexed
				 begin
               md_ctrl    = latch_md;
			      left_ctrl  = acca_left;
				   right_ctrl = zero_right;
				   alu_ctrl   = alu_nop;
               cc_ctrl    = latch_cc;
	            case (op_code[3:0])
		         4'b1011: // undefined
					  next_state = fetch_state;
		         4'b1110: // jmp
					  next_state = jmp_state;
		         default:
					  next_state = read8_state;
		         endcase
					end
	          4'b1010: // acca indexed
				 begin
				   case (op_code[3:0])
					4'b0111:  // staa
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st8;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write8_state;
					end
					4'b1101: // jsr
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = latch_md;
					  next_state = jsr_state;
					end
					4'b1111: // sts
					begin
			        left_ctrl  = sp_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st16;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write16_state;
					end
					default:
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = latch_md;
					  next_state = read8_state;
					  end
					endcase
					end
	          4'b1110: // accb indexed
				 begin
				   case (op_code[3:0])
					4'b0111:  // stab direct
					begin
			        left_ctrl  = accb_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st8;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write8_state;
					end
					4'b1101: // std direct
					begin
			        left_ctrl  = accd_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st16;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
					  next_state = write16_state;
					end
					4'b1111: // stx direct
					begin
			        left_ctrl  = ix_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st16;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write16_state;
					end
					default:
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = latch_md;
					  next_state = read8_state;
					end
					endcase
					end
			    default:
				 begin
               md_ctrl    = latch_md;
			      left_ctrl  = acca_left;
				   right_ctrl = zero_right;
				   alu_ctrl   = alu_nop;
               cc_ctrl    = latch_cc;
					next_state = fetch_state;
				end
			    endcase
				 end
           //
			  // ea holds the low byte of the absolute address
			  // Move ea low byte into ea high byte
			  // load new ea low byte to for absolute 16 bit address
			  // advance the program counter
			  //
			  extended_state: // fetch ea low byte
			  begin
               acca_ctrl  = latch_acca;
               accb_ctrl  = latch_accb;
               ix_ctrl    = latch_ix;
               sp_ctrl    = latch_sp;
               iv_ctrl    = latch_iv;
			      op_ctrl    = latch_op;
				   nmi_ctrl   = latch_nmi;
					// increment pc
               pc_ctrl    = inc_pc;
					// fetch next effective address bytes
					ea_ctrl    = fetch_next_ea;
               addr_ctrl  = fetch_ad;
					dout_ctrl  = md_lo_dout;
					// work out the next state
				 case (op_code[7:4])
				 4'b0111: // single op extended
				 begin
               md_ctrl    = latch_md;
			      left_ctrl  = acca_left;
				   right_ctrl = zero_right;
				   alu_ctrl   = alu_nop;
               cc_ctrl    = latch_cc;
	            case (op_code[3:0])
		         4'b1011: // undefined
					  next_state = fetch_state;
		         4'b1110: // jmp
					  next_state = jmp_state;
		         default:
					  next_state = read8_state;
		         endcase
				end
	          4'b1011: // acca extended
				   case (op_code[3:0])
					4'b0111:  // staa
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st8;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write8_state;
					end
					4'b1101: // jsr
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = latch_md;
					  next_state = jsr_state;
					end
					4'b1111: // sts
					begin
			        left_ctrl  = sp_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st16;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write16_state;
					end
					default:
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = latch_md;
					  next_state = read8_state;
					end
					endcase
	          4'b1111: // accb extended
				   case (op_code[3:0])
					4'b0111:  // stab
					begin
			        left_ctrl  = accb_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st8;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write8_state;
					end
					4'b1101: // std
					begin
			        left_ctrl  = accd_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st16;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
					  next_state = write16_state;
					end
					4'b1111: // stx
					begin
			        left_ctrl  = ix_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_st16;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
				     next_state = write16_state;
					end
					default:
					begin
			        left_ctrl  = acca_left;
				     right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = latch_md;
					  next_state = read8_state;
					end
					endcase
			    default:
				 begin
               md_ctrl    = latch_md;
			      left_ctrl  = acca_left;
				   right_ctrl = zero_right;
				   alu_ctrl   = alu_nop;
               cc_ctrl    = latch_cc;
					next_state = fetch_state;
				end
			    endcase
				 end
           //
			  // here if ea holds low byte (direct page)
			  // can enter here from extended addressing
			  // read memory location
			  // note that reads may be 8 or 16 bits
			  //
			  read8_state: // read data
			  begin
               acca_ctrl  = latch_acca;
               accb_ctrl  = latch_accb;
               ix_ctrl    = latch_ix;
               sp_ctrl    = latch_sp;
               pc_ctrl    = latch_pc;
               iv_ctrl    = latch_iv;
			      op_ctrl    = latch_op;
				   nmi_ctrl   = latch_nmi;
					//
               addr_ctrl  = read_ad;
					dout_ctrl  = md_lo_dout;
					case (op_code[7:4])
					  4'b0110, 4'b0111: // single operand
					  begin
 					      left_ctrl  = acca_left;
					      right_ctrl = zero_right;
					      alu_ctrl   = alu_nop;
                     cc_ctrl    = latch_cc;
				         md_ctrl    = fetch_first_md;
					      ea_ctrl    = latch_ea;
					      next_state = execute_state;
						end

	              4'b1001, 4'b1010, 4'b1011: // acca
				       case (op_code[3:0])
					    4'b0011,  // subd
					         4'b1110,  // lds
					         4'b1100: // cpx
						begin
 					      left_ctrl  = acca_left;
					      right_ctrl = zero_right;
					      alu_ctrl   = alu_nop;
                     cc_ctrl    = latch_cc;
				         md_ctrl    = fetch_first_md;
				         // increment the effective address in case of 16 bit load
					      ea_ctrl    = inc_ea;
					      next_state = read16_state;
						end
					    default:
						 begin
 					      left_ctrl  = acca_left;
					      right_ctrl = zero_right;
					      alu_ctrl   = alu_nop;
                     cc_ctrl    = latch_cc;
				         md_ctrl    = fetch_first_md;
 					      ea_ctrl    = latch_ea;
					      next_state = fetch_state;
						end
					    endcase

	              4'b1101, 4'b1110, 4'b1111: // accb
				       case (op_code[3:0])
					    4'b0011,  // addd
					         4'b1100,  // ldd
					         4'b1110: // ldx
						begin
 					      left_ctrl  = acca_left;
					      right_ctrl = zero_right;
					      alu_ctrl   = alu_nop;
                     cc_ctrl    = latch_cc;
				         md_ctrl    = fetch_first_md;
				         // increment the effective address in case of 16 bit load
					      ea_ctrl    = inc_ea;
					      next_state = read16_state;
						end
					    default:
						 begin
 					      left_ctrl  = acca_left;
					      right_ctrl = zero_right;
					      alu_ctrl   = alu_nop;
                     cc_ctrl    = latch_cc;
				         md_ctrl    = fetch_first_md;
					      ea_ctrl    = latch_ea;
					      next_state = execute_state;
						end
					    endcase
					  default:
					  begin
 					    left_ctrl  = acca_left;
					    right_ctrl = zero_right;
					    alu_ctrl   = alu_nop;
                   cc_ctrl    = latch_cc;
				       md_ctrl    = fetch_first_md;
					    ea_ctrl    = latch_ea;
					    next_state = fetch_state;
						end
					  endcase
					  end

			   read16_state: // read second data byte from ea
				begin
                 // default
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
					  // idle the effective address
                 ea_ctrl    = latch_ea;
					  // read the low byte of the 16 bit data
				     md_ctrl    = fetch_next_md;
                 addr_ctrl  = read_ad;
                 dout_ctrl  = md_lo_dout;
					  next_state = fetch_state;
				end
           //
			  // 16 bit Write state
			  // write high byte of ALU output.
			  // EA hold address of memory to write to
			  // Advance the effective address in ALU
			  //
			  write16_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
				 // increment the effective address
				 left_ctrl  = acca_left;
				 right_ctrl = zero_right;
				 alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
			    ea_ctrl    = inc_ea;
 				 // write the ALU hi byte to ea
             addr_ctrl  = write_ad;
             dout_ctrl  = md_hi_dout;
				 next_state = write8_state;
				end
           //
			  // 8 bit write
			  // Write low 8 bits of ALU output
			  //
			  write8_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // idle the ALU
             left_ctrl  = acca_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
				 // write ALU low byte output
             addr_ctrl  = write_ad;
             dout_ctrl  = md_lo_dout;
				 next_state = fetch_state;
				end

				jmp_state:
				begin
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // load PC with effective address
                 left_ctrl  = acca_left;
					  right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
					  pc_ctrl    = load_ea_pc;
					  // idle the bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
                 next_state = fetch_state;
					end

				jsr_state: // JSR
				begin
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
                 // decrement sp
                 left_ctrl  = sp_left;
                 right_ctrl = plus_one_right;
                 alu_ctrl   = alu_sub16;
                 cc_ctrl    = latch_cc;
                 sp_ctrl    = load_sp;
					  // write pc low
                 addr_ctrl  = push_ad;
					  dout_ctrl  = pc_lo_dout; 
                 next_state = jsr1_state;
					end

				jsr1_state: // JSR
				begin
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 pc_ctrl    = latch_pc;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
                 // decrement sp
                 left_ctrl  = sp_left;
                 right_ctrl = plus_one_right;
                 alu_ctrl   = alu_sub16;
                 cc_ctrl    = latch_cc;
                 sp_ctrl    = load_sp;
					  // write pc hi
                 addr_ctrl  = push_ad;
					  dout_ctrl  = pc_hi_dout; 
                 next_state = jmp_state;
					end

				branch_state: // Bcc
				begin
				     // default registers
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // calculate signed branch
					  left_ctrl  = acca_left;
					  right_ctrl = zero_right;
				     alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
					  pc_ctrl    = add_ea_pc;
					  // idle the bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
                 next_state = fetch_state;
					end

				bsr_state: // BSR
				begin
				     // default
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 pc_ctrl    = latch_pc;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
                 // decrement sp
                 left_ctrl  = sp_left;
                 right_ctrl = plus_one_right;
                 alu_ctrl   = alu_sub16;
                 cc_ctrl    = latch_cc;
                 sp_ctrl    = load_sp;
					  // write pc low
                 addr_ctrl  = push_ad;
					  dout_ctrl  = pc_lo_dout; 
                 next_state = bsr1_state;
					end

				bsr1_state: // BSR
				begin
				     // default registers
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 pc_ctrl    = latch_pc;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
                 // decrement sp
                 left_ctrl  = sp_left;
                 right_ctrl = plus_one_right;
                 alu_ctrl   = alu_sub16;
                 cc_ctrl    = latch_cc;
                 sp_ctrl    = load_sp;
					  // write pc hi
                 addr_ctrl  = push_ad;
					  dout_ctrl  = pc_hi_dout; 
                 next_state = branch_state;
					end

				 rts_hi_state: // RTS
				 begin
				     // default
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 pc_ctrl    = latch_pc;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // increment the sp
                 left_ctrl  = sp_left;
                 right_ctrl = plus_one_right;
                 alu_ctrl   = alu_add16;
                 cc_ctrl    = latch_cc;
                 sp_ctrl    = load_sp;
                 // read pc hi
					  pc_ctrl    = pull_hi_pc;
                 addr_ctrl  = pull_ad;
                 dout_ctrl  = pc_hi_dout;
                 next_state = rts_lo_state;
					end

				rts_lo_state: // RTS1
				begin
				     // default
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 md_ctrl    = latch_md;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // idle the ALU
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
					  // read pc low
					  pc_ctrl    = pull_lo_pc;
                 addr_ctrl  = pull_ad;
                 dout_ctrl  = pc_lo_dout;
                 next_state = fetch_state;
					end

				 mul_state:
				 begin
				     // default
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // move acca to md
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_st16;
                 cc_ctrl    = latch_cc;
                 md_ctrl    = load_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mulea_state;
					end

				 mulea_state:
				 begin
				     // default
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 md_ctrl    = latch_md;
					  // idle ALU
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_nop;
                 cc_ctrl    = latch_cc;
					  // move accb to ea
                 ea_ctrl    = load_accb_ea;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = muld_state;
					end

				 muld_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
                 md_ctrl    = latch_md;
					  // clear accd
                 left_ctrl  = acca_left;
                 right_ctrl = zero_right;
                 alu_ctrl   = alu_ld8;
                 cc_ctrl    = latch_cc;
                 acca_ctrl  = load_hi_acca;
                 accb_ctrl  = load_accb;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul0_state;
					end

				 mul0_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 0 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[0] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul1_state;
					end

				 mul1_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 1 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[1] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul2_state;
					end

				 mul2_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 2 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[2] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul3_state;
					end

				 mul3_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 3 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[3] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul4_state;
					end

				 mul4_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 4 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[4] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul5_state;
					end

				 mul5_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 5 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[5] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul6_state;
					end

				 mul6_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 6 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[6] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = mul7_state;
					end

				 mul7_state:
				 begin
				     // default
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
			        op_ctrl    = latch_op;
				     nmi_ctrl   = latch_nmi;
                 ea_ctrl    = latch_ea;
					  // if bit 7 of ea set, add accd to md
                 left_ctrl  = accd_left;
                 right_ctrl = md_right;
                 alu_ctrl   = alu_add16;
					  if (ea[7] == 1'b1)
					  begin
                   cc_ctrl    = load_cc;
                   acca_ctrl  = load_hi_acca;
                   accb_ctrl  = load_accb;
					  end
					  else
					  begin
                   cc_ctrl    = latch_cc;
                   acca_ctrl  = latch_acca;
                   accb_ctrl  = latch_accb;
					  end
                 md_ctrl    = shiftl_md;
					  // idle bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
				     next_state = fetch_state;
					end

			    execute_state: // execute single operand instruction
				 begin
				   // default
			      op_ctrl    = latch_op;
				   nmi_ctrl   = latch_nmi;
			      case (op_code[7:4])
	            4'b0110, // indexed single op
	                 4'b0111: // extended single op
					begin
                 acca_ctrl  = latch_acca;
                 accb_ctrl  = latch_accb;
                 ix_ctrl    = latch_ix;
                 sp_ctrl    = latch_sp;
                 pc_ctrl    = latch_pc;
                 iv_ctrl    = latch_iv;
                 ea_ctrl    = latch_ea;
					  // idle the bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
	              case (op_code[3:0])
		           4'b0000: // neg
					  begin
                   left_ctrl  = md_left;
					    right_ctrl = zero_right;
					    alu_ctrl   = alu_neg;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
					end
 	              4'b0011: // com
					  begin
                   left_ctrl  = md_left;
		             right_ctrl = zero_right;
					    alu_ctrl   = alu_com;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b0100: // lsr
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_lsr8;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b0110: // ror
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_ror8;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b0111: // asr
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_asr8;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b1000: // asl
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_asl8;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b1001: // rol
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_rol8;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b1010: // dec
					  begin
                   left_ctrl  = md_left;
		             right_ctrl = plus_one_right;
					    alu_ctrl   = alu_dec;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b1011: // undefined
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_nop;
					    cc_ctrl    = latch_cc;
				       md_ctrl    = latch_md;
				       next_state = fetch_state;
						end
		           4'b1100: // inc
					  begin
                   left_ctrl  = md_left;
		             right_ctrl = plus_one_right;
					    alu_ctrl   = alu_inc;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           4'b1101: // tst
					  begin
                   left_ctrl  = md_left;
		             right_ctrl = zero_right;
					    alu_ctrl   = alu_tst;
					    cc_ctrl    = load_cc;
				       md_ctrl    = latch_md;
				       next_state = fetch_state;
						end
		           4'b1110: // jmp
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_nop;
					    cc_ctrl    = latch_cc;
				       md_ctrl    = latch_md;
				       next_state = fetch_state;
						end
		           4'b1111: // clr
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_clr;
					    cc_ctrl    = load_cc;
				       md_ctrl    = load_md;
				       next_state = write8_state;
						end
		           default:
					  begin
                   left_ctrl  = md_left;
						 right_ctrl = zero_right;
					    alu_ctrl   = alu_nop;
					    cc_ctrl    = latch_cc;
				       md_ctrl    = latch_md;
				       next_state = fetch_state;
						end
		           endcase
					  end

	            default:
					begin
					  left_ctrl   = accd_left;
					  right_ctrl  = md_right;
					  alu_ctrl    = alu_nop;
					  cc_ctrl     = latch_cc;
					  acca_ctrl   = latch_acca;
                 accb_ctrl   = latch_accb;
                 ix_ctrl     = latch_ix;
                 sp_ctrl     = latch_sp;
                 pc_ctrl     = latch_pc;
                 md_ctrl     = latch_md;
                 iv_ctrl     = latch_iv;
                 ea_ctrl     = latch_ea;
					  // idle the bus
                 addr_ctrl  = idle_ad;
                 dout_ctrl  = md_lo_dout;
		           next_state = fetch_state;
					end
              endcase
				  end

			  psha_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write acca
             addr_ctrl  = push_ad;
			    dout_ctrl  = acca_dout; 
             next_state = fetch_state;
			end

			  pula_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // idle sp
             left_ctrl  = sp_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
             sp_ctrl    = latch_sp;
				 // read acca
				 acca_ctrl  = pull_acca;
             addr_ctrl  = pull_ad;
             dout_ctrl  = acca_dout;
             next_state = fetch_state;
			end

			  pshb_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write accb
             addr_ctrl  = push_ad;
			    dout_ctrl  = accb_dout; 
             next_state = fetch_state;
			end

			  pulb_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // idle sp
             left_ctrl  = sp_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
             sp_ctrl    = latch_sp;
				 // read accb
				 accb_ctrl  = pull_accb;
             addr_ctrl  = pull_ad;
             dout_ctrl  = accb_dout;
             next_state = fetch_state;
			end

			  pshx_lo_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write ix low
             addr_ctrl  = push_ad;
			    dout_ctrl  = ix_lo_dout; 
             next_state = pshx_hi_state;
			end

			  pshx_hi_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write ix hi
             addr_ctrl  = push_ad;
			    dout_ctrl  = ix_hi_dout; 
             next_state = fetch_state;
			end

		  	  pulx_hi_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // pull ix hi
				 ix_ctrl    = pull_hi_ix;
             addr_ctrl  = pull_ad;
             dout_ctrl  = ix_hi_dout;
             next_state = pulx_lo_state;
			end

		  	  pulx_lo_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // idle sp
             left_ctrl  = sp_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
             sp_ctrl    = latch_sp;
				 // read ix low
				 ix_ctrl    = pull_lo_ix;
             addr_ctrl  = pull_ad;
             dout_ctrl  = ix_lo_dout;
             next_state = fetch_state;
			end

           //
			  // return from interrupt
			  // enter here from bogus interrupts
			  //
			  rti_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             sp_ctrl    = load_sp;
				 // idle address bus
             cc_ctrl    = latch_cc;
             addr_ctrl  = idle_ad;
             dout_ctrl  = cc_dout;
             next_state = rti_cc_state;
			end

			  rti_cc_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             sp_ctrl    = load_sp;
				 // read cc
             cc_ctrl    = pull_cc;
             addr_ctrl  = pull_ad;
             dout_ctrl  = cc_dout;
             next_state = rti_accb_state;
			end

			  rti_accb_state:
			  begin
				 // default registers
             acca_ctrl  = latch_acca;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // read accb
				 accb_ctrl  = pull_accb;
             addr_ctrl  = pull_ad;
             dout_ctrl  = accb_dout;
             next_state = rti_acca_state;
			end

			  rti_acca_state:
			  begin
				 // default registers
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // read acca
				 acca_ctrl  = pull_acca;
             addr_ctrl  = pull_ad;
             dout_ctrl  = acca_dout;
             next_state = rti_ixh_state;
			end

			  rti_ixh_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // read ix hi
				 ix_ctrl    = pull_hi_ix;
             addr_ctrl  = pull_ad;
             dout_ctrl  = ix_hi_dout;
             next_state = rti_ixl_state;
			end

			  rti_ixl_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // read ix low
				 ix_ctrl    = pull_lo_ix;
             addr_ctrl  = pull_ad;
             dout_ctrl  = ix_lo_dout;
             next_state = rti_pch_state;
			end

			  rti_pch_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
	          // increment sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_add16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // pull pc hi
				 pc_ctrl    = pull_hi_pc;
             addr_ctrl  = pull_ad;
             dout_ctrl  = pc_hi_dout;
             next_state = rti_pcl_state;
			end

			  rti_pcl_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // idle sp
             left_ctrl  = sp_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
             sp_ctrl    = latch_sp;
	          // pull pc low
				 pc_ctrl    = pull_lo_pc;
             addr_ctrl  = pull_ad;
             dout_ctrl  = pc_lo_dout;
             next_state = fetch_state;
			end

			  //
			  // here on interrupt
			  // iv register hold interrupt type
			  //
			  int_pcl_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write pc low
             addr_ctrl  = push_ad;
			    dout_ctrl  = pc_lo_dout; 
             next_state = int_pch_state;
			end

			  int_pch_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write pc hi
             addr_ctrl  = push_ad;
			    dout_ctrl  = pc_hi_dout; 
             next_state = int_ixl_state;
			end

			  int_ixl_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write ix low
             addr_ctrl  = push_ad;
			    dout_ctrl  = ix_lo_dout; 
             next_state = int_ixh_state;
			end

			  int_ixh_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write ix hi
             addr_ctrl  = push_ad;
			    dout_ctrl  = ix_hi_dout; 
             next_state = int_acca_state;
			end

			  int_acca_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write acca
             addr_ctrl  = push_ad;
			    dout_ctrl  = acca_dout; 
             next_state = int_accb_state;
			end


			  int_accb_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write accb
             addr_ctrl  = push_ad;
			    dout_ctrl  = accb_dout; 
             next_state = int_cc_state;
			end

			  int_cc_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
             // decrement sp
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_sub16;
             cc_ctrl    = latch_cc;
             sp_ctrl    = load_sp;
				 // write cc
             addr_ctrl  = push_ad;
			    dout_ctrl  = cc_dout;
				 nmi_ctrl   = latch_nmi;
				 //
				 // nmi is edge triggered
				 // nmi_req is cleared when nmi goes low.
				 //
			    if (nmi_req == 1'b1)
				 begin
		  			iv_ctrl    = nmi_iv;
			      next_state = vect_hi_state;
				 end
			    else
				 begin
					//
					// IRQ is level sensitive
					//
				   if ((irq == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = irq_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_icf == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = icf_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_ocf == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = ocf_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_tof == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = tof_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_sci == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = sci_iv;
			        next_state = int_mask_state;
					end
               else
					  case (op_code)
					  8'b00111110: // WAI (wait for interrupt)
					  begin
                   iv_ctrl    = latch_iv;
	                next_state = int_wai_state;
					end
					  8'b00111111: // SWI (Software interrupt)
					  begin
                   iv_ctrl    = swi_iv;
	                next_state = vect_hi_state;
					end
					  default: // bogus interrupt (return)
					  begin
                   iv_ctrl    = latch_iv;
	                next_state = rti_state;
					end
					  endcase
				 end
				 end

			  int_wai_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
			    op_ctrl    = latch_op;
             ea_ctrl    = latch_ea;
             // enable interrupts
             left_ctrl  = sp_left;
             right_ctrl = plus_one_right;
             alu_ctrl   = alu_cli;
             cc_ctrl    = load_cc;
             sp_ctrl    = latch_sp;
				 // idle bus
             addr_ctrl  = idle_ad;
			    dout_ctrl  = cc_dout; 
			    if ((nmi_req == 1'b1) & (nmi_ack==1'b0))
				 begin
		  			iv_ctrl    = nmi_iv;
				   nmi_ctrl   = set_nmi;
			      next_state = vect_hi_state;
				 end
			    else
				 begin
				   //
					// nmi request is not cleared until nmi input goes low
					//
				   if ((nmi_req == 1'b0) & (nmi_ack==1'b1))
				     nmi_ctrl = reset_nmi;
					else
					  nmi_ctrl = latch_nmi;
					//
					// IRQ is level sensitive
					//
				   if ((irq == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = irq_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_icf == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = icf_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_ocf == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = ocf_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_tof == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = tof_iv;
			        next_state = int_mask_state;
					end
               else if ((irq_sci == 1'b1) & (cc[IBIT] == 1'b0))
					begin
		  			  iv_ctrl    = sci_iv;
			        next_state = int_mask_state;
					end
               else
					begin
                 iv_ctrl    = latch_iv;
	              next_state = int_wai_state;
					end
				 end
				 end

			  int_mask_state:
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // Mask IRQ
             left_ctrl  = sp_left;
             right_ctrl = zero_right;
			    alu_ctrl   = alu_sei;
				 cc_ctrl    = load_cc;
             sp_ctrl    = latch_sp;
				 // idle bus cycle
             addr_ctrl  = idle_ad;
             dout_ctrl  = md_lo_dout;
             next_state = vect_hi_state;
			end

			  halt_state: // halt CPU.
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // do nothing in ALU
             left_ctrl  = acca_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
				 // idle bus cycle
             addr_ctrl  = idle_ad;
             dout_ctrl  = md_lo_dout;
				 if (halt == 1'b1)
			      next_state = halt_state;
				 else
				   next_state = fetch_state;
				 end

			  default: // error state halt on undefine states
			  begin
				 // default
             acca_ctrl  = latch_acca;
             accb_ctrl  = latch_accb;
             ix_ctrl    = latch_ix;
             sp_ctrl    = latch_sp;
             pc_ctrl    = latch_pc;
             md_ctrl    = latch_md;
             iv_ctrl    = latch_iv;
			    op_ctrl    = latch_op;
				 nmi_ctrl   = latch_nmi;
             ea_ctrl    = latch_ea;
				 // do nothing in ALU
             left_ctrl  = acca_left;
             right_ctrl = zero_right;
             alu_ctrl   = alu_nop;
             cc_ctrl    = latch_cc;
				 // idle bus cycle
             addr_ctrl  = idle_ad;
             dout_ctrl  = md_lo_dout;
				 next_state = error_state;
			end
		  endcase
end

////////////////////////////////
//
// state machine
//
////////////////////////////////

always_ff @(posedge clk)
begin
	if (rst == 1'b1)
		state <= reset_state;
	else if (hold == 1'b1)
		state <= state;
	else
		state <= next_state;
end
endmodule
