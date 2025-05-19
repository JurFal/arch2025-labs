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
    input u64 pc,
    input u1 stall,
    input u1 pc_misaligned,
    input u1 mem_misaligned,
	input word_t mem_mcause,
    input u2 priviledgeMode,
    input u1 interrupted,
    input word_t interrupt_mcause
);

    creg_addr_t ra1, ra2, rdst;
    control_t ctl;
    word_t rd1, rd2, imm;
    u12 csraddr;
    excep_data_t excep;

    decoder decoder (
        .raw_instr,
        .ctl,
        .ra1,
        .ra2,
        .rdst,
        .imm,
        .csraddr,
        .pc,
        .excep,
        .pc_misaligned,
        .mem_misaligned,
        .mem_mcause,
        .priviledgeMode,
        .interrupted,
        .interrupt_mcause
    );
    assign dataF.valid = '1;
    assign dataF.raw_instr = ~stall ? raw_instr : 0;
    assign dataF.pc = pc;
    assign dataF.ctl = ~stall ? ctl : 0;
    assign dataF.ra1 = ra1;
    assign dataF.ra2 = ra2;
    assign dataF.dst = rdst;
    assign dataF.imm = imm;
    assign dataF.csraddr = csraddr;
    assign dataF.excep = excep;
    assign dataF.priviledgeMode = priviledgeMode;

endmodule

`endif
