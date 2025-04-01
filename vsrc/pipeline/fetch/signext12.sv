`ifndef __SIGNEXT12_SV
`define __SIGNEXT12_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module signext12
    import common::*;
    import pipes::*;(
    input u12 imm12,
    output word_t imm12ext
);
    assign imm12ext = {{52{imm12[11]}}, imm12};
endmodule


`endif
