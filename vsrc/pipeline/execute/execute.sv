`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/branch.sv"
`include "pipeline/muxword.sv"
`include "pipeline/execute/signext32.sv"
`else

`endif

module execute
    import common::*;
    import pipes::*;(
    input decode_data_t dataD,
    input fwd_data_t fwda, fwdb,
    output execute_data_t dataE,
    output u1 branch_enable,
    output word_t branch_target,
    output u2 priviledgeMode
);

    control_t ctl;
    assign ctl = dataD.ctl;
    
    word_t src1_reg, src1_orig, src1_pc, src1;
    word_t src2_reg, src2_orig, src2;
    word_t aluout, aluoutw, aluoute, branch_target_j, branch_target_j_csr, branch_target_csr;
    
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

    muxword muxword_alusrca_pc (
        .choose(ctl.pcsrc),
        .muxin0(src1_reg),
        .muxin1(dataD.pc),
        .muxout(src1_pc)
    );

    muxword muxword_alusrca (
        .choose(ctl.csrsrc),
        .muxin0(src1_pc),
        .muxin1(dataD.csrdata),
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
        .muxout(aluoute)
    );

    muxword muxword_branch_target_j (
        .choose(ctl.jalr),
        .muxin0(aluout),
        .muxin1(aluout & (64'hfffffffffffffffe)),
        .muxout(branch_target_j)
    );

    muxword muxword_branch_target_j_csr (
        .choose(ctl.mret | ctl.exception),
        .muxin0(branch_target_j),
        .muxin1(dataD.csrdata),
        .muxout(branch_target_j_csr)
    );

    muxword muxword_branch_target_csr (
        .choose(ctl.csrsrc && !(ctl.mret | ctl.exception)),
        .muxin0(branch_target_j_csr),
        .muxin1(dataD.pc + 4),
        .muxout(branch_target_csr)
    );

    branch branch (
        .branchfunc(ctl.branchfunc),
        .branch_enable,
        .src1(src1_reg),
        .src2(src2_reg),
        .branch_target_csr,
        .pc(dataD.pc + 4),
        .is_csr(ctl.csrsrc)
    );

    always_comb begin
        dataE.excep = dataD.excep;
        dataE.priviledgeMode = dataD.priviledgeMode;
        if(ctl.exception) begin
            dataE.excep.mstatus.sd = dataD.extramstatus.sd;
            dataE.excep.mstatus.sxl = dataD.extramstatus.sxl;
            dataE.excep.mstatus.uxl = dataD.extramstatus.uxl;
            dataE.excep.mstatus.tsr = dataD.extramstatus.tsr;
            dataE.excep.mstatus.tw = dataD.extramstatus.tw;
            dataE.excep.mstatus.tvm = dataD.extramstatus.tvm;
            dataE.excep.mstatus.mxr = dataD.extramstatus.mxr;
            dataE.excep.mstatus.sum = dataD.extramstatus.sum;
            dataE.excep.mstatus.mprv = dataD.extramstatus.mprv;
            dataE.excep.mstatus.xs = dataD.extramstatus.xs;
            dataE.excep.mstatus.fs = dataD.extramstatus.fs;
            dataE.excep.mstatus.mpp = dataD.priviledgeMode; // set mpp
            dataE.excep.mstatus.spp = dataD.extramstatus.spp;
            dataE.excep.mstatus.mpie = dataD.extramstatus.mie; // set mpie
            dataE.excep.mstatus.spie = dataD.extramstatus.spie;
            dataE.excep.mstatus.upie = dataD.extramstatus.upie;
            dataE.excep.mstatus.mie = 1'b0; // set mie
            dataE.excep.mstatus.sie = dataD.extramstatus.sie;
            dataE.excep.mstatus.uie = dataD.extramstatus.uie;
            dataE.priviledgeMode = 2'b0;
        end
        if(ctl.mret) begin
            dataE.excep.mstatus.sd = dataD.extramstatus.sd;
            dataE.excep.mstatus.sxl = dataD.extramstatus.sxl;
            dataE.excep.mstatus.uxl = dataD.extramstatus.uxl;
            dataE.excep.mstatus.tsr = dataD.extramstatus.tsr;
            dataE.excep.mstatus.tw = dataD.extramstatus.tw;
            dataE.excep.mstatus.tvm = dataD.extramstatus.tvm;
            dataE.excep.mstatus.mxr = dataD.extramstatus.mxr;
            dataE.excep.mstatus.sum = dataD.extramstatus.sum;
            dataE.excep.mstatus.mprv = dataD.extramstatus.mprv;
            dataE.excep.mstatus.xs = dataD.extramstatus.xs;
            dataE.excep.mstatus.fs = dataD.extramstatus.fs;
            dataE.excep.mstatus.mpp = dataD.extramstatus.mpp;
            dataE.excep.mstatus.spp = dataD.extramstatus.spp;
            dataE.excep.mstatus.mpie = dataD.extramstatus.mpie;
            dataE.excep.mstatus.spie = dataD.extramstatus.spie;
            dataE.excep.mstatus.upie = dataD.extramstatus.upie;
            dataE.excep.mstatus.mie = dataD.extramstatus.mpie; // copy mpie
            dataE.excep.mstatus.sie = dataD.extramstatus.sie;
            dataE.excep.mstatus.uie = dataD.extramstatus.uie;
            dataE.priviledgeMode = dataD.extramstatus.mpp;
        end
    end

    assign dataE.aluout = (ctl.jal | ctl.jalr) ? (dataD.pc + 4) : aluoute;
    assign dataE.valid = dataD.valid;
    assign dataE.pc = dataD.pc;
    assign dataE.raw_instr = dataD.valid ? dataD.raw_instr : '0;
    assign dataE.ra1 = dataD.ra1;
    assign dataE.ra2 = dataD.ra2;
    assign dataE.csrdata = dataD.csrdata;
    assign dataE.dst = dataD.dst;
    assign dataE.ctl = dataD.valid ? ctl : '0;
    assign dataE.memwd = src2_reg;
    assign dataE.csraddr = dataD.csraddr;
    assign branch_target = branch_enable ? branch_target_csr : 0;

endmodule


`endif
