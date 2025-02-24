`ifndef __DECODER_SV
`define __DECODER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module decoder
    import common::*;
    import pipes::*;(
    input u32 raw_instr,
    output control_t ctl,
    output creg_addr_t ra1, ra2, wa,
    output u64 imm
);

    wire [6:0] op = raw_instr[6:0];
    wire [2:0] f3 = raw_instr[14:12];
    wire [6:0] f7 = raw_instr[31:25];

    always_comb begin
        ctl = '0;
        ra1 = '0;
        ra2 = '0;
        wa = '0;
        unique case (op)
            OP_R_ALL32: begin
                ctl.regwrite = 1'b1;
                ra1 = raw_instr[19:15];
                ra2 = raw_instr[24:20];
                wa = raw_instr[11:7];
                unique case (f3)
                    F3_ADD: begin
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
                    F3_XOR: begin
                        ctl.op = XORI;
                        ctl.alufunc = ALU_XOR;
                    end
                    F3_OR: begin
                        ctl.op = ORI;
                        ctl.alufunc = ALU_OR;
                    end
                    F3_AND: begin
                        ctl.op = ANDI;
                        ctl.alufunc = ALU_AND;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                endcase
            end
            OP_R_ALL64: begin
                ctl.regwrite = 1'b1;
                ra1 = raw_instr[19:15];
                ra2 = raw_instr[24:20];
                wa = raw_instr[11:7];
                unique case (f3)
                    F3_ADD: begin
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
            OP_I_MAT32: begin
                ctl.regwrite = 1'b1;
                ra1 = raw_instr[19:15];
                wa = raw_instr[11:7];
                unique case (f3)
                    F3_ADD: begin
                        ctl.op = ADDI;
                        ctl.alufunc = ALU_ADD;
                    end
                    F3_XOR: begin
                        ctl.op = XORI;
                        ctl.alufunc = ALU_XOR;
                    end
                    F3_OR: begin
                        ctl.op = ORI;
                        ctl.alufunc = ALU_OR;
                    end
                    F3_AND: begin
                        ctl.op = ANDI;
                        ctl.alufunc = ALU_AND;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                endcase
            end
            OP_I_MAT64: begin
                ctl.regwrite = 1'b1;
                ra1 = raw_instr[19:15];
                ra2 = '0;
                wa = raw_instr[11:7];
                unique case (f3)
                    F3_ADD: begin
                        ctl.op = ADDIW;
                        ctl.alufunc = ALU_ADD;
                    end
                    default: begin
                        ctl.op = UNKNOWN;
                        ctl.alufunc = ALU_ADD;
                    end
                endcase
            end
            default: begin

            end
        endcase
        
    end

    
endmodule


`endif
