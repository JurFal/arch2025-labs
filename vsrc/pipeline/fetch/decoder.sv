`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/signext12.sv"
`include "pipeline/fetch/shamtzeroext.sv"
`include "pipeline/fetch/signext20.sv"
`include "pipeline/muxword.sv"
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
    wire [5:0] f6 = raw_instr[31:26];


    always_comb begin
        ctl = '0;
        ra1 = '0;
        ra2 = '0;
        rdst = '0;
        unique case (op)
            OP_R_OPS: begin
                ctl.regwrite = 1'b1;
                ctl.branchfunc = BRH_NEV;
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
                    F3_OP_SLE: begin
                        ctl.op = SLL;
                        ctl.alufunc = ALU_SLL;
                    end
                    F3_OP_SLT: begin
                        ctl.op = SLT;
                        ctl.alufunc = ALU_SLT;
                    end
                    F3_OP_SLU: begin
                        ctl.op = SLTU;
                        ctl.alufunc = ALU_SLTU;
                    end
                    F3_OP_XOR: begin
                        ctl.op = XOR;
                        ctl.alufunc = ALU_XOR;
                    end
                    F3_OP_SRG: begin
                        if (f7 == 7'b0000000) begin
                            ctl.op = SRL;
                            ctl.alufunc = ALU_SRL;
                        end
                        else if (f7 == 7'b0100000) begin
                            ctl.op = SRA;
                            ctl.alufunc = ALU_SRA;
                        end
                        else begin
                            ctl.op = UNKNOWN;
                            ctl.alufunc = ALU_ADD;
                        end
                    end
                    F3_OP_ORR: begin
                        ctl.op = OR;
                        ctl.alufunc = ALU_OR;
                    end
                    F3_OP_AND: begin
                        ctl.op = AND;
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
                ctl.branchfunc = BRH_NEV;
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
                    F3_OP_SLE: begin
                        ctl.op = SLLW;
                        ctl.alufunc = ALU_SLLW;
                    end
                    F3_OP_SRG: begin
                        if (f7 == 7'b0000000) begin
                            ctl.op = SRLW;
                            ctl.alufunc = ALU_SRLW;
                        end
                        else if (f7 == 7'b0100000) begin
                            ctl.op = SRAW;
                            ctl.alufunc = ALU_SRAW;
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
                ctl.branchfunc = BRH_NEV;
                ra1 = raw_instr[19:15];
                rdst = raw_instr[11:7];
                unique case (f3)
                    F3_OP_ADD: begin
                        imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
                        ctl.op = ADDI;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_OP_SLE: begin                        
                        if (f6 == 6'b000000) begin
                            imm = {58'b0, raw_instr[25:20]};
                            ctl.op = SLLI;
                            ctl.alufunc = ALU_SLL;
                        end
                        else begin
                            ctl.op = UNKNOWN;
                            ctl.alufunc = ALU_ADD;
                        end
                    end
                    F3_OP_SLT: begin
                        imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
                        ctl.op = SLTI;
                        ctl.alufunc = ALU_SLT;
                    end
                    F3_OP_SLU: begin
                        imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
                        ctl.op = SLTIU;
                        ctl.alufunc = ALU_SLTU;
                    end
                    F3_OP_XOR: begin
                        imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
                        ctl.op = XORI;
                        ctl.alufunc = ALU_XOR;
                    end
                    F3_OP_ORR: begin
                        imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
                        ctl.op = ORI;
                        ctl.alufunc = ALU_OR;
                    end
                    F3_OP_SRG: begin
                        if (f6 == 6'b000000) begin
                            imm = {58'b0, raw_instr[25:20]};
                            ctl.op = SRLI;
                            ctl.alufunc = ALU_SRL;
                        end
                        else if (f6 == 6'b010000) begin
                            imm = {58'b0, raw_instr[25:20]};
                            ctl.op = SRAI;
                            ctl.alufunc = ALU_SRA;
                        end
                        else begin
                            ctl.op = UNKNOWN;
                            ctl.alufunc = ALU_ADD;
                        end
                    end
                    F3_OP_AND: begin
                        imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
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
                ctl.branchfunc = BRH_NEV;
                ra1 = raw_instr[19:15];
                rdst = raw_instr[11:7];
                unique case (f3)
                    F3_OP_ADD: begin
                        imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
                        ctl.op = ADDIW;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_OP_SLE: begin
                        if (f6 == 6'b000000) begin
                            imm = {58'b0, raw_instr[25:20]};
                            ctl.op = SLLIW;
                            ctl.alufunc = ALU_SLLW;
                        end
                        else begin
                            ctl.op = UNKNOWN;
                            ctl.alufunc = ALU_ADD;
                        end
                    end
                    F3_OP_SRG: begin
                        if (f6 == 6'b000000) begin
                            imm = {58'b0, raw_instr[25:20]};
                            ctl.op = SRLIW;
                            ctl.alufunc = ALU_SRLW;
                        end
                        else if (f6 == 6'b010000) begin
                            imm = {58'b0, raw_instr[25:20]};
                            ctl.op = SRAIW;
                            ctl.alufunc = ALU_SRAW;
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
            OP_I_LIM: begin
                ctl.regwrite = 1'b1;
                ctl.immsrc = 1'b1;
                ctl.memread = 1'b1;
                ctl.alufunc = ALU_ADD;
                ctl.branchfunc = BRH_NEV;
                ra1 = raw_instr[19:15];
                rdst = raw_instr[11:7];
                imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
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
            OP_I_JLR: begin
                ctl.jalr = 1'b1;
                ctl.immsrc = 1'b1;
                ctl.regwrite = 1'b1;
                ctl.alufunc = ALU_ADD;
                ctl.branchfunc = BRH_AWS;
                ra1 = raw_instr[19:15];
                rdst = raw_instr[11:7];
                imm = {{52{raw_instr[31]}}, raw_instr[31:20]};
                unique case (f3)
                    F3_JL_JLR: begin
                        ctl.op = JALR;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                    end
                endcase
            end
            OP_B_BRH: begin                
                ctl.immsrc = 1'b1;
                ctl.pcsrc = 1'b1;
                ctl.alufunc = ALU_ADD;
                ra1 = raw_instr[19:15];
                ra2 = raw_instr[24:20];
                unique case (f3)
                    F3_BR_BEQ: begin
                        ctl.op = BEQ;
                        ctl.branchfunc = BRH_EQL;
                    end
                    F3_BR_BNE: begin
                        ctl.op = BNE;
                        ctl.branchfunc = BRH_NEQ;
                    end
                    F3_BR_BLT: begin
                        ctl.op = BLT;
                        ctl.branchfunc = BRH_LST;
                    end
                    F3_BR_BGE: begin
                        ctl.op = BGE;
                        ctl.branchfunc = BRH_GOE;
                    end
                    F3_BR_BLU: begin
                        ctl.op = BLTU;
                        ctl.branchfunc = BRH_LSTU;
                    end
                    F3_BR_BGU: begin
                        ctl.op = BGEU;
                        ctl.branchfunc = BRH_GOEU;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.branchfunc = BRH_NEV;
                    end
                endcase
                imm = {{52{raw_instr[31]}}, raw_instr[7], raw_instr[30:25], raw_instr[11:8], 1'b0};
            end
            OP_J_JAL: begin
                ctl.jal = 1'b1;
                ctl.immsrc = 1'b1;
                ctl.pcsrc = 1'b1;
                ctl.regwrite = 1'b1;
                ctl.alufunc = ALU_ADD;
                ctl.branchfunc = BRH_AWS;
                rdst = raw_instr[11:7];
                imm = {{44{raw_instr[31]}}, raw_instr[19:12], raw_instr[20], raw_instr[30:21], 1'b0};
                ctl.op = JAL;
            end
            OP_S_SIM: begin
                ctl.immsrc = 1'b1;
                ctl.memwrite = 1'b1;
                ctl.alufunc = ALU_ADD;
                ctl.branchfunc = BRH_NEV;
                ra1 = raw_instr[19:15];
                ra2 = raw_instr[24:20];
                imm = {{52{raw_instr[31]}}, raw_instr[31:25], raw_instr[11:7]};
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
            OP_U_LUI: begin
                ctl.regwrite = 1'b1;
                ctl.immsrc = 1'b1;
                ctl.alufunc = ALU_ADD;
                ctl.branchfunc = BRH_NEV;
                rdst = raw_instr[11:7];
                imm = {{32{raw_instr[31]}}, raw_instr[31:12], 12'b0};
            end
            OP_U_APC: begin
                ctl.regwrite = 1'b1;
                ctl.immsrc = 1'b1;
                ctl.pcsrc = 1'b1;
                ctl.alufunc = ALU_ADD;
                ctl.branchfunc = BRH_NEV;
                rdst = raw_instr[11:7];
                imm = {{32{raw_instr[31]}}, raw_instr[31:12], 12'b0};
            end
            
            default: begin
                
            end
        endcase
        
    end

endmodule


`endif
