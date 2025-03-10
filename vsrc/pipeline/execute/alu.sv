`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module alu
    import common::*;
    import pipes::*;(
    input alufunc_t alufunc,
    output word_t aluout,
    input word_t src1, src2
);
    always_comb begin
        case(alufunc)
            ALU_ADD: aluout = src1 + src2;
            ALU_SUB: aluout = src1 - src2;
            //ALU_MUL: aluout = src1 * src2;
            //ALU_DIV: aluout = src1 / src2;
            ALU_AND: aluout = src1 & src2;
            ALU_OR: aluout = src1 | src2;
            ALU_XOR: aluout = src1 ^ src2;
            //ALU_SLL: aluout = src1 << src2;
            //ALU_SRL: aluout = src1 >> src2;
            //ALU_SRA: aluout = src1 >>> src2;
            //ALU_SLT: aluout = (src1 < src2) ? 1 : 0;
            //ALU_SLTU: aluout = (src1 < src2) ? 1 : 0;
            default: aluout = '0;
        endcase
    end

endmodule


`endif
