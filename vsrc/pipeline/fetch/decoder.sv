`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/muxword.sv"
`else

`endif

module decoder
    import common::*;
    import pipes::*;(
    input u32 raw_instr,
    output control_t ctl,
    output creg_addr_t ra1, ra2, rdst,
    output word_t imm,
    output u12 csraddr,
    input word_t pc,
    output excep_data_t excep,
    input u1 pc_misaligned,
    input u1 mem_misaligned,
    input word_t mem_mcause,
    input u2 priviledgeMode,
    input u1 interrupted,
    input word_t interrupt_mcause,
    input u1 data_ok
);

    wire [6:0] op = raw_instr[6:0];
    wire [2:0] f3 = raw_instr[14:12];
    wire [6:0] f7 = raw_instr[31:25];
    wire [5:0] f6 = raw_instr[31:26];
    wire [4:0] f5 = raw_instr[24:20];

    always_comb begin
        ctl = '0;
        ra1 = '0;
        ra2 = '0;
        rdst = '0;
        excep = '0;
        if(interrupted) begin
            ctl.csrsrc = 1'b1;
            ctl.exception = 1'b1;
            excep.enable = 1'b1;
            excep.mepc = pc;
            excep.mcause = interrupt_mcause;
            csraddr = CSR_MTVEC;
            ctl.op = UNKNOWN;
        end
        else if(pc_misaligned) begin
            ctl = '0;
            ctl.csrsrc = 1'b1;
            ctl.exception = 1'b1;
            excep.enable = 1'b1;
            excep.mepc = pc;
            excep.mcause = 64'd0;
            csraddr = CSR_MTVEC;
            ctl.op = UNKNOWN;
        end
        else if(mem_misaligned) begin
            ctl = '0;
            ctl.csrsrc = 1'b1;
            ctl.exception = 1'b1;
            excep.enable = 1'b1;
            excep.mepc = pc;
            excep.mcause = mem_mcause;
            csraddr = CSR_MTVEC;
            ctl.op = UNKNOWN;
        end
        else if(data_ok)
            unique case (op)
                OP_R_OPS: begin
                    ctl.regwrite = 1'b1;
                    ctl.branchfunc = BRH_NEV;
                    ra1 = raw_instr[19:15];
                    ra2 = raw_instr[24:20];
                    rdst = raw_instr[11:7];
                    if (f7 == 7'b0000000) 
                        unique case (f3)
                            F3_OP_ADD: begin
                                ctl.op = ADD;
                                ctl.alufunc = ALU_ADD;
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
                                    ctl = '0;
                                    ctl.csrsrc = 1'b1;
                                    ctl.exception = 1'b1;
                                    excep.enable = 1'b1;
                                    excep.mepc = pc;
                                    excep.mcause = 64'd2;
                                    csraddr = CSR_MTVEC;
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
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
                                ctl.op = UNKNOWN;
                                ctl.alufunc = ALU_ADD;
                            end
                        endcase
                    else if (f7 == 7'b0100000) begin
                        unique case (f3)
                            F3_OP_ADD: begin
                                ctl.op = SUB;
                                ctl.alufunc = ALU_SUB;
                            end
                            F3_OP_SRG: begin
                                ctl.op = SRA;
                                ctl.alufunc = ALU_SRA;
                            end
                            default: begin
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
                                ctl.op = UNKNOWN;
                                ctl.alufunc = ALU_ADD;
                            end
                        endcase
                    end
                    else if (f7 == 7'b0000001) begin
                        unique case (f3)
                            F3_OP_ADD: begin
                                ctl.op = MUL;
                                ctl.alufunc = ALU_MUL;
                            end
                            F3_OP_XOR: begin
                                ctl.op = DIV;
                                ctl.alufunc = ALU_DIV;
                            end
                            F3_OP_SRG: begin
                                ctl.op = DIVU;
                                ctl.alufunc = ALU_DIVU;
                            end
                            F3_OP_ORR: begin
                                ctl.op = REM;
                                ctl.alufunc = ALU_REM;
                            end
                            F3_OP_AND: begin
                                ctl.op = REMU;
                                ctl.alufunc = ALU_REMU;
                            end
                            default: begin
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
                                ctl.op = UNKNOWN;
                                ctl.alufunc = ALU_ADD;
                            end
                        endcase
                    end
                    else begin
                        ctl = '0;
                        ctl.csrsrc = 1'b1;
                        ctl.exception = 1'b1;
                        excep.enable = 1'b1;
                        excep.mepc = pc;
                        excep.mcause = 64'd2;
                        csraddr = CSR_MTVEC;
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                end
                OP_R_OPW: begin
                    ctl.regwrite = 1'b1;
                    ctl.aluext = 1'b1;
                    ctl.branchfunc = BRH_NEV;
                    ra1 = raw_instr[19:15];
                    ra2 = raw_instr[24:20];
                    rdst = raw_instr[11:7];
                    if (f7 == 7'b0000000) begin
                        unique case (f3)
                            F3_OP_ADD: begin
                                ctl.op = ADDW;
                                ctl.alufunc = ALU_ADD;
                            end
                            F3_OP_SLE: begin
                                ctl.op = SLLW;
                                ctl.alufunc = ALU_SLLW;
                            end
                            F3_OP_SRG: begin
                                ctl.op = SRLW;
                                ctl.alufunc = ALU_SRLW;
                            end
                            default: begin
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
                                ctl.op = UNKNOWN;
                                ctl.alufunc = ALU_ADD;
                            end 
                        endcase
                    end
                    else if (f7 == 7'b0100000) begin
                        unique case (f3)
                            F3_OP_ADD: begin
                                ctl.op = SUBW;
                                ctl.alufunc = ALU_SUB;
                            end
                            F3_OP_SRG: begin
                                ctl.op = SRAW;
                                ctl.alufunc = ALU_SRAW;
                            end
                            default: begin
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
                                ctl.op = UNKNOWN;
                                ctl.alufunc = ALU_ADD;
                            end
                        endcase
                    end
                    else if (f7 == 7'b0000001) begin
                        unique case (f3)
                            F3_OP_ADD: begin
                                ctl.op = MULW;
                                ctl.alufunc = ALU_MULW;
                            end
                            F3_OP_XOR: begin
                                ctl.op = DIVW;
                                ctl.alufunc = ALU_DIVW;
                            end
                            F3_OP_SRG: begin
                                ctl.op = DIVUW;
                                ctl.alufunc = ALU_DIVUW;
                            end
                            F3_OP_ORR: begin
                                ctl.op = REMW;
                                ctl.alufunc = ALU_REMW;
                            end
                            F3_OP_AND: begin
                                ctl.op = REMUW;
                                ctl.alufunc = ALU_REMUW;
                            end
                            default: begin
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
                                ctl.op = UNKNOWN;
                                ctl.alufunc = ALU_ADD;
                            end
                        endcase
                    end
                    else begin
                        ctl = '0;
                        ctl.csrsrc = 1'b1;
                        ctl.exception = 1'b1;
                        excep.enable = 1'b1;
                        excep.mepc = pc;
                        excep.mcause = 64'd2;
                        csraddr = CSR_MTVEC;
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
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
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
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
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
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
                            ctl = '0;
                            ctl.csrsrc = 1'b1;
                            ctl.exception = 1'b1;
                            excep.enable = 1'b1;
                            excep.mepc = pc;
                            excep.mcause = 64'd2;
                            csraddr = CSR_MTVEC;
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
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
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
                                ctl = '0;
                                ctl.csrsrc = 1'b1;
                                ctl.exception = 1'b1;
                                excep.enable = 1'b1;
                                excep.mepc = pc;
                                excep.mcause = 64'd2;
                                csraddr = CSR_MTVEC;
                                ctl.op = UNKNOWN;
                                ctl.alufunc = ALU_ADD;
                            end
                        end
                        default: begin
                            ctl = '0;
                            ctl.csrsrc = 1'b1;
                            ctl.exception = 1'b1;
                            excep.enable = 1'b1;
                            excep.mepc = pc;
                            excep.mcause = 64'd2;
                            csraddr = CSR_MTVEC;
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
                            ctl = '0;
                            ctl.csrsrc = 1'b1;
                            ctl.exception = 1'b1;
                            excep.enable = 1'b1;
                            excep.mepc = pc;
                            excep.mcause = 64'd2;
                            csraddr = CSR_MTVEC;
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
                    ctl.op = JALR;
                    /*unique case (f3)
                        F3_JL_JLR: begin
                            ctl.op = JALR;
                        end
                        default: begin
                            ctl = '0;
                            ctl.csrsrc = 1'b1;
                            ctl.exception = 1'b1;
                            excep.enable = 1'b1;
                            excep.mepc = pc;
                            excep.mcause = 64'd2;
                            csraddr = CSR_MTVEC;
                            ctl.op = UNKNOWN;
                        end
                    endcase*/
                end
                OP_I_CSR: begin
                    ctl.regwrite = 1'b1;
                    ctl.branchfunc = BRH_NEV;
                    ctl.csrsrc = 1'b1;
                    rdst = raw_instr[11:7];
                    case(f3)
                        F3_CS_ENV: begin
                            case(raw_instr[31:20])
                                12'b000000000000: begin
                                    ctl.op = ECALL;
                                    ctl.exception = 1'b1;
                                    excep.enable = 1'b1;
                                    excep.mepc = pc;
                                    case(priviledgeMode)
                                        2'b00: excep.mcause = 64'd8;
                                        2'b01: excep.mcause = 64'd9;
                                        2'b11: excep.mcause = 64'd11;
                                        default: excep.mcause = 64'd2;
                                    endcase
                                    csraddr = CSR_MTVEC;
                                end
                                12'b001100000010: begin
                                    ctl.op = MRET;
                                    ctl.mret = 1'b1;
                                    csraddr = CSR_MEPC;
                                    excep.enable = 1'b1;
                                    excep.mret = 1'b1;
                                end
                                default: begin
                                    ctl = '0;
                                    ctl.exception = 1'b1;
                                    excep.enable = 1'b1;
                                    excep.mepc = pc;
                                    excep.mcause = 64'd2;
                                    csraddr = CSR_MTVEC;
                                    ctl.op = UNKNOWN;
                                end
                            endcase
                        end
                        F3_CS_RWR: begin
                            ctl.alufunc = ALU_SRC2;
                            ra2 = raw_instr[19:15];
                            csraddr = raw_instr[31:20];
                        end
                        F3_CS_RSR: begin
                            ctl.alufunc = ALU_OR;
                            ra2 = raw_instr[19:15];
                            csraddr = raw_instr[31:20];
                        end
                        F3_CS_RCR: begin
                            ctl.alufunc = ALU_NAND;
                            ra2 = raw_instr[19:15];
                            csraddr = raw_instr[31:20];
                        end
                        F3_CS_RWI: begin
                            ctl.alufunc = ALU_SRC2;
                            ctl.immsrc = 1'b1;
                            imm = {59'b0, raw_instr[19:15]};
                            csraddr = raw_instr[31:20];
                        end
                        F3_CS_RSI: begin
                            ctl.alufunc = ALU_OR;
                            ctl.immsrc = 1'b1;
                            imm = {59'b0, raw_instr[19:15]};
                            csraddr = raw_instr[31:20];
                        end
                        F3_CS_RCI: begin
                            ctl.alufunc = ALU_NAND;
                            ctl.immsrc = 1'b1;
                            imm = {59'b0, raw_instr[19:15]};
                            csraddr = raw_instr[31:20];
                        end
                        default: begin
                            ctl = '0;
                            ctl.exception = 1'b1;
                            excep.enable = 1'b1;
                            excep.mepc = pc;
                            excep.mcause = 64'd2;
                            csraddr = CSR_MTVEC;
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
                            ctl = '0;
                            ctl.csrsrc = 1'b1;
                            ctl.exception = 1'b1;
                            excep.enable = 1'b1;
                            excep.mepc = pc;
                            excep.mcause = 64'd2;
                            csraddr = CSR_MTVEC;
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
                            ctl = '0;
                            ctl.csrsrc = 1'b1;
                            ctl.exception = 1'b1;
                            excep.enable = 1'b1;
                            excep.mepc = pc;
                            excep.mcause = 64'd2;
                            csraddr = CSR_MTVEC;
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
                    ctl = '0;
                    ctl.csrsrc = 1'b1;
                    ctl.exception = 1'b1;
                    excep.enable = 1'b1;
                    excep.mepc = pc;
                    excep.mcause = 64'd2;
                    csraddr = CSR_MTVEC;
                    ctl.op = UNKNOWN;
                end
            endcase
            
    end

endmodule


`endif
