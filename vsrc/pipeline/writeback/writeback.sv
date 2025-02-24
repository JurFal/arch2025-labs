`ifndef __WRITEBACK_SV
`define __WRITEBACK_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/muxword.sv"
`else

`endif

module writeback
    import common::*;
    import pipes::*;(
    input execute_data_t dataE,
    output writeback_data_t dataW
);

    assign dataW.dst = dataE.dst;
    assign dataW.writedata = dataE.aluout;
    assign dataW.ctl = dataE.ctl;

endmodule


`endif
