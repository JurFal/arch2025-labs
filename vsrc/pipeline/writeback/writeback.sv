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
    input memory_data_t dataM,
    output writeback_data_t dataW
);

    assign dataW.valid = '1;
    assign dataW.pc = dataM.pc;
    assign dataW.raw_instr = dataM.raw_instr;
    assign dataW.dst = dataM.dst;
    assign dataW.writedata = (dataM.dst == '0) ? 0 : dataM.writedata;
    assign dataW.ctl = dataM.ctl;

endmodule


`endif
