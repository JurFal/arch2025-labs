`ifndef __FWDMUX_SV
`define __FWDMUX_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/muxword.sv"
`include "pipeline/fwd.sv"
`else

`endif

module fwdmux
    import common::*;
    import pipes::*;(
    input decode_data_t dataD,
    input execute_data_t dataE,
    input memory_data_t dataM,
    input writeback_data_t dataW,
    output fwd_data_t fwd_srca, fwd_srcb
);
    
	fwd_data_t fwd_op1_srca, fwd_op1_srcb;
	fwd_data_t fwd_op2_srca, fwd_op2_srcb;

	fwd fwdop1a (
		.src(dataD.ra1),
		.dst(dataE.dst),
		.regwrite(dataE.ctl.regwrite),
		.fwddata(dataE.aluout),
		.fwd(fwd_op1_srca)
	);

	fwd fwdop1b (
		.src(dataD.ra2),
		.dst(dataE.dst),
		.regwrite(dataE.ctl.regwrite),
		.fwddata(dataE.aluout),
		.fwd(fwd_op1_srcb)
	);
	
	/*word_t fwd_mdata;

	muxword fwdmdata (
		.choose(dataM.ctl.memread),
		.muxin0(dataM.aluout),
		.muxin1(dataM.readdata),
		.muxout(fwd_mdata)
	);*/

	fwd fwdop2a (
		.src(dataD.ra1),
		.dst(dataW.dst),
		.regwrite(dataW.ctl.regwrite),
		.fwddata(dataW.writedata),
		.fwd(fwd_op2_srca)
	);

	fwd fwdop2b (
		.src(dataD.ra2),
		.dst(dataW.dst),
		.regwrite(dataW.ctl.regwrite),
		.fwddata(dataW.writedata),
		.fwd(fwd_op2_srcb)
	);

    
	assign fwd_srca = fwd_op1_srca.enable ? fwd_op1_srca : fwd_op2_srca;
    assign fwd_srcb = fwd_op1_srcb.enable ? fwd_op1_srcb : fwd_op2_srcb;
	
endmodule

`endif