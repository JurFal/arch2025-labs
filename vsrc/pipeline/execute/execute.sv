`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`include "pipeline/muxword.sv"
`include "pipeline/execute/signext32.sv"
`else

`endif

module execute
    import common::*;
    import pipes::*;(
    input decode_data_t dataD,
    output execute_data_t dataE
);

    control_t ctl = dataD.ctl;
    word_t src1 = dataD.srca;
    word_t src2;
    word_t aluout, aluoutw;
    
    muxword muxword_alusrcb (
        .choose(ctl.alusrc),
        .muxin0(dataD.srcb),
        .muxin1(dataD.imm),
        .muxout(src2)
    );

    alu alu (
        .alufunc(ctl.alufunc),
        .aluout,
        .src1,
        .src2
    );
    
    signext32 signext32 (
        .imm32(aluout[31:0]),
        .imm(aluoutw)
    );

    muxword muxword_aluout (
        .choose(ctl.aluext),
        .muxin0(aluout),
        .muxin1(aluoutw),
        .muxout(dataE.aluout)
    );

    assign dataE.valid = '1;
    assign dataE.pc = dataD.pc;
    assign dataE.raw_instr = dataD.raw_instr;
    assign dataE.dst = dataD.dst;
    assign dataE.ctl = ctl;
    assign dataE.memwd = dataD.srcb;

endmodule


`endif
