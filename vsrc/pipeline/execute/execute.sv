`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/decode/decoder.sv"
`else

`endif

module decode
    import common::*;
    import pipes::*;(
    input decode_data_t dataD,
    output execute_data_t dataE,
    
    output creg_addr_t ra1, ra2, wa,
    input word_t rd1, rd2, wd
);

    control_t ctl;

    decoder decoder (
        .raw_instr(dataF.raw_instr),
        .ctl,
        .ra1,
        .ra2,
        .wa
    );


    assign dataD.ctl = ctl;
    assign dataD.dst = dataF.raw_instr[11:7];

    assign dataD.srca = rd1;
    assign dataD.srcb = rd2;
    
endmodule


`endif
