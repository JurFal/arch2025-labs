`ifndef __SIGNEXT20_SV
`define __SIGNEXT20_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module signext20
    import common::*;
    import pipes::*;(
    input u20 imm20,
    output word_t imm20ext
);
    
    assign imm20ext = {{44{imm20[19]}}, imm20} << 12;
endmodule


`endif
