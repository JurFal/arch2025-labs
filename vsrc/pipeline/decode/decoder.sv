`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/signext12.sv"
`else

`endif

module decoder
    import common::*;
    import pipes::*;(
    input u32 raw_instr,
    output control_t ctl,
    output creg_addr_t ra1, ra2, rdst,
    output word_t imm
);

    wire [6:0] op = raw_instr[6:0];
    wire [2:0] f3 = raw_instr[14:12];
    wire [6:0] f7 = raw_instr[31:25];

    u12 imm12;

    always_comb begin
        ctl = '0;
        ra1 = '0;
        ra2 = '0;
        rdst = '0;
        imm12 = '0;
        unique case (op)
            OP_R_OPS: begin
                ctl.regwrite = 1'b1;
                ra1 = raw_instr[19:15];
                ra2 = raw_instr[24:20];
                rdst = raw_instr[11:7];
                unique case (f3)
                    F3_OP_ADD: begin
                        if (f7 == 7'b0000000) begin
                            ctl.op = ADD;
                            ctl.alufunc = ALU_ADD;
                        end
                        else if (f7 == 7'b0100000) begin
                            ctl.op = SUB;
                            ctl.alufunc = ALU_SUB;
                        end
                        else begin
                            ctl.op = UNKNOWN;
                            ctl.alufunc = ALU_ADD;
                        end
                    end
                    F3_OP_XOR: begin
                        ctl.op = XORI;
                        ctl.alufunc = ALU_XOR;
                    end
                    F3_OP_ORR: begin
                        ctl.op = ORI;
                        ctl.alufunc = ALU_OR;
                    end
                    F3_OP_AND: begin
                        ctl.op = ANDI;
                        ctl.alufunc = ALU_AND;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                endcase
            end
            OP_R_OPW: begin
                ctl.regwrite = 1'b1;
                ctl.aluext = 1'b1;
                ra1 = raw_instr[19:15];
                ra2 = raw_instr[24:20];
                rdst = raw_instr[11:7];
                unique case (f3)
                    F3_OP_ADD: begin
                        if (f7 == 7'b0000000) begin
                            ctl.op = ADDW;
                            ctl.alufunc = ALU_ADD;
                        end
                        else if (f7 == 7'b0100000) begin
                            ctl.op = SUBW;
                            ctl.alufunc = ALU_SUB;
                        end
                        else begin
                            ctl.op = UNKNOWN;
                            ctl.alufunc = ALU_ADD;
                        end
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                endcase
            end
            OP_I_OPS: begin
                ctl.regwrite = 1'b1;
                ctl.immsrc = 1'b1;
                ra1 = raw_instr[19:15];
                rdst = raw_instr[11:7];
                imm12 = raw_instr[31:20];
                unique case (f3)
                    F3_OP_ADD: begin
                        ctl.op = ADDI;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_OP_XOR: begin
                        ctl.op = XORI;
                        ctl.alufunc = ALU_XOR;
                    end
                    F3_OP_ORR: begin
                        ctl.op = ORI;
                        ctl.alufunc = ALU_OR;
                    end
                    F3_OP_AND: begin
                        ctl.op = ANDI;
                        ctl.alufunc = ALU_AND;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                endcase
            end
            OP_I_OPW: begin
                ctl.regwrite = 1'b1;
                ctl.immsrc = 1'b1;
                ctl.aluext = 1'b1;
                ra1 = raw_instr[19:15];
                rdst = raw_instr[11:7];
                imm12 = raw_instr[31:20];
                unique case (f3)
                    F3_OP_ADD: begin
                        ctl.op = ADDIW;
                        ctl.alufunc = ALU_ADD;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                endcase
            end
            OP_I_LIM: begin
                ctl.regwrite = 1'b1;
                ctl.immsrc = 1'b1;
                ctl.memread = 1'b1;
                ctl.alufunc = ALU_ADD;
                ra1 = raw_instr[19:15];
                rdst = raw_instr[11:7];
                imm12 = raw_instr[31:20];
                unique case (f3)
                    F3_MM_QWS: begin
                        ctl.op = LB;
                        ctl.memsize = MSIZE1;
                    end
                    F3_MM_HWS: begin
                        ctl.op = LH;
                        ctl.memsize = MSIZE2;
                    end
                    F3_MM_SWS: begin
                        ctl.op = LW;
                        ctl.memsize = MSIZE4;
                    end
                    F3_MM_DWS: begin
                        ctl.op = LD;
                        ctl.memsize = MSIZE8;
                    end
                    F3_MM_QWU: begin
                        ctl.op = LBU;
                        ctl.memsize = MSIZE1;
                        ctl.zeroextwb = 1'b1;
                    end
                    F3_MM_HWU: begin
                        ctl.op = LHU;
                        ctl.memsize = MSIZE2;
                        ctl.zeroextwb = 1'b1;
                    end
                    F3_MM_SWU: begin
                        ctl.op = LWU;
                        ctl.memsize = MSIZE4;
                        ctl.zeroextwb = 1'b1;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                    end
                endcase
            end
            OP_S_SIM: begin
                ctl.immsrc = 1'b1;
                ctl.memwrite = 1'b1;
                ctl.alufunc = ALU_ADD;
                ra1 = raw_instr[19:15];
                ra2 = raw_instr[24:20];
                imm12 = {raw_instr[31:25], raw_instr[11:7]};
                unique case (f3)
                    F3_MM_QWS: begin
                        ctl.op = SB;
                        ctl.memsize = MSIZE1;
                    end
                    F3_MM_HWS: begin
                        ctl.op = SH;
                        ctl.memsize = MSIZE2;
                    end
                    F3_MM_SWS: begin
                        ctl.op = SW;
                        ctl.memsize = MSIZE4;
                    end
                    F3_MM_DWS: begin
                        ctl.op = SD;
                        ctl.memsize = MSIZE8;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                    end
                endcase
            end
            default: begin
                
            end
        endcase
        
    end

    signext12 signext12 (
        .imm12,
        .imm
    );
    
endmodule


`endif
