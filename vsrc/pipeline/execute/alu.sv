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
            //MUL: aluout = src1 * src2;
            //DIV: aluout = src1 / src2;
            ALU_AND: aluout = src1 & src2;
            ALU_OR: aluout = src1 | src2;
            ALU_XOR: aluout = src1 ^ src2;
            //SLL: aluout = src1 << src2;
            //SRL: aluout = src1 >> src2;
            //SRA: aluout = src1 >>> src2;
            //SLT: aluout = (src1 < src2) ? 1 : 0;
            //SLTU: aluout = (src1 < src2) ? 1 : 0;
            default: aluout = '0;
        endcase
    end

endmodule


`endif
