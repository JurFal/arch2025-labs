`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/regfile.sv"
`include "pipeline/decode/csrfile.sv"
`else

`endif

module decode
    import common::*;
    import pipes::*;(
    input clk, reset,
    input fetch_data_t dataF,
    output decode_data_t dataD,
    input u1 wen,
    input creg_addr_t wa,
    input word_t wd,
    input u1 csr_wen,
    input u12 csr_wa,
    input word_t csr_wd,
    output u64 REG[31:0],
    output csr_t CSR,
    input u1 stall,
    input excep_data_t excep_wdata
);

    word_t rd1, rd2;
	
	regfile regfile(
		.clk, .reset,
		.ra1(dataF.ra1),
		.ra2(dataF.ra2),
		.rd1,
		.rd2,
		.wen,
		.wa,
		.wd,
        .REG
	);

	csrfile csrfile(
		.clk, .reset,
		.csr_ra(dataF.csraddr),
        .csr_out(dataD.csrdata),
		.csr_wen,
		.csr_wa,
		.csr_wd,
        .excep_wdata,
        .excep_readstatus(dataF.ctl.exception || dataF.ctl.mret),
        .excep_mstatus(dataD.extramstatus),
        .CSR
	);

    assign dataD.valid = '1;
    assign dataD.pc = dataF.pc;
    assign dataD.raw_instr = ~stall ? dataF.raw_instr : '0;
    assign dataD.ctl = ~stall ? dataF.ctl : '0;
    assign dataD.ra1 = dataF.ra1;
    assign dataD.ra2 = dataF.ra2;
    assign dataD.dst = dataF.dst;
    assign dataD.imm = dataF.imm;
    assign dataD.csraddr = dataF.csraddr;
    assign dataD.excep = dataF.excep;
    assign dataD.priviledgeMode = dataF.priviledgeMode;
    assign dataD.srca = rd1;
    assign dataD.srcb = rd2;
    
endmodule


`endif
