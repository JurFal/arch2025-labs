`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`include "pipeline/regfile/regfile.sv"
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
    output u64 next_reg[31:0]
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
        .REG(next_reg)
	);

    assign dataD.valid = '1;
    assign dataD.pc = dataF.pc;
    assign dataD.raw_instr = dataF.raw_instr;
    assign dataD.ctl = dataF.ctl;
    assign dataD.ra1 = dataF.ra1;
    assign dataD.ra2 = dataF.ra2;
    assign dataD.dst = dataF.dst;
    assign dataD.imm = dataF.imm;

    assign dataD.srca = rd1;
    assign dataD.srcb = rd2;
    
endmodule


`endif
