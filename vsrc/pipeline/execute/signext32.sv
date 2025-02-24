`ifndef __SIGNEXT32_SV
`define __SIGNEXT32_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module signext32
    import common::*;
    import pipes::*;(
    input u32 imm32,
    output word_t imm
);
    assign imm = {{32{imm32[31]}}, imm32};
endmodule


`endif
