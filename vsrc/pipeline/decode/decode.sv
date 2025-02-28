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

    creg_addr_t ra1, ra2, rdst;
    control_t ctl;
    word_t rd1, rd2, imm;

    decoder decoder (
        .raw_instr(dataF.raw_instr),
        .ctl,
        .ra1,
        .ra2,
        .rdst,
        .imm
    );
	
	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,
		.rd2,
		.wen,
		.wa,
		.wd,
        .next_reg
	);

    assign dataD.valid = '1;
    assign dataD.pc = dataF.pc;
    assign dataD.raw_instr = dataF.raw_instr;
    assign dataD.ctl = ctl;
    assign dataD.dst = rdst;

    assign dataD.srca = rd1;
    assign dataD.srcb = rd2;
    assign dataD.imm = imm;
    
endmodule


`endif
