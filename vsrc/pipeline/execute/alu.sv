`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/mul_div_unit.sv"
`else

`endif

module alu
    import common::*;
    import pipes::*;(
    input alufunc_t alufunc,
    output word_t aluout,
    input word_t src1, src2
);

    word_t mul_div_result;

    mul_div_unit mul_div_inst (
        .alufunc(alufunc),
        .src1(src1),
        .src2(src2),
        .result(mul_div_result)
    );

    always_comb begin
        case(alufunc)
            ALU_SRC1: aluout = src1;
            ALU_SRC2: aluout = src2;
            ALU_ADD: aluout = src1 + src2;
            ALU_SUB: aluout = src1 - src2;
            //ALU_MUL: aluout = src1 * src2;
            //ALU_DIV: aluout = src1 / src2;
            ALU_AND: aluout = src1 & src2;
            ALU_NAND: aluout = src1 & (~src2);
            ALU_OR: aluout = src1 | src2;
            ALU_XOR: aluout = src1 ^ src2;
            ALU_SLL: aluout = src1 << src2[5:0];
            ALU_SLLW: aluout = {32'b0, src1[31:0] << src2[4:0]};
            ALU_SRL: aluout = src1 >> src2[5:0];
            ALU_SRLW: aluout = {32'b0, src1[31:0] >> src2[4:0]};
            ALU_SRA: aluout = $signed(src1) >>> src2[5:0];
            ALU_SRAW: aluout = {32'b0, $signed(src1[31:0]) >>> src2[4:0]};
            ALU_SLT: aluout = ($signed(src1) < $signed(src2)) ? 1 : 0;
            ALU_SLTU: aluout = ($unsigned(src1) < $unsigned(src2)) ? 1 : 0;
	        ALU_MUL, ALU_MULW,
            ALU_DIV, ALU_DIVU, ALU_DIVW, ALU_DIVUW,
            ALU_REM, ALU_REMU, ALU_REMW, ALU_REMUW: aluout = mul_div_result;
            default: aluout = '0;
        endcase
    end

endmodule


`endif
