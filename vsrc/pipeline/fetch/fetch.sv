`ifndef __FETCH_SV
`define __FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/decoder.sv"
`else

`endif 

module fetch 
    import common::*;
    import pipes::*;(

    output fetch_data_t dataF,
    input u32 raw_instr,
    input u64 pc
);

    creg_addr_t ra1, ra2, rdst;
    control_t ctl;
    word_t rd1, rd2, imm;

    decoder decoder (
        .raw_instr,
        .ctl,
        .ra1,
        .ra2,
        .rdst,
        .imm
    );
    assign dataF.valid = '1;
    assign dataF.raw_instr = raw_instr;
    assign dataF.pc = pc;

    assign dataF.ctl = ctl;
    assign dataF.ra1 = ra1;
    assign dataF.ra2 = ra2;
    assign dataF.dst = rdst;
    assign dataF.imm = imm;

endmodule

`endif
