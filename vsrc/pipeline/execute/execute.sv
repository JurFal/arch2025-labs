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
    input fwd_data_t fwda, fwdb,
    output execute_data_t dataE
);

    control_t ctl;
    assign ctl = dataD.ctl;
    
    word_t src1_reg, src1;
    word_t src2_reg, src2;
    word_t aluout, aluoutw;
    
    muxword muxword_fwdsrca (
        .choose(fwda.enable),
        .muxin0(dataD.srca),
        .muxin1(fwda.data),
        .muxout(src1_reg)
    );
    
    muxword muxword_fwdsrcb (
        .choose(fwdb.enable),
        .muxin0(dataD.srcb),
        .muxin1(fwdb.data),
        .muxout(src2_reg)
    );

    muxword muxword_alusrca (
        .choose(ctl.pcsrc),
        .muxin0(src1_reg),
        .muxin1(dataD.pc),
        .muxout(src1)
    );

    muxword muxword_alusrcb (
        .choose(ctl.immsrc),
        .muxin0(src2_reg),
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
    assign dataE.ra1 = dataD.ra1;
    assign dataE.ra2 = dataD.ra2;
    assign dataE.dst = dataD.dst;
    assign dataE.ctl = ctl;
    assign dataE.memwd = src2_reg;

endmodule


`endif
