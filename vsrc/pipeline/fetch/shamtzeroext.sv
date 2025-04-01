`ifndef __SHAMZEROTEXT_SV
`define __SHAMZEROTEXT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module shamtzeroext
    import common::*;
    import pipes::*;(
    input u6 shamt,
    output word_t shamtext
);
    assign shamtext = {{58'b0}, shamt};
endmodule


`endif
