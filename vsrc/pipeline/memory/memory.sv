`ifndef __MEMORY_SV

`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/muxword.sv"
`else

`endif

module memory
    import common::*;
    import pipes::*;(
    input execute_data_t dataE,
    output memory_data_t dataM
);

    assign dataM.valid = '1;
    assign dataM.pc = dataE.pc;
    assign dataM.raw_instr = dataE.raw_instr;
    assign dataM.dst = dataE.dst;
    assign dataM.writedata = dataE.aluout;
    assign dataM.ctl = dataE.ctl;

endmodule


`endif
