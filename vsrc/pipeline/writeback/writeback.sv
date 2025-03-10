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

    always_comb begin
        dataW.valid = '1;
        dataW.pc = dataM.pc;
        dataW.raw_instr = dataM.raw_instr;
        dataW.dst = dataM.dst;
        dataW.ctl = dataM.ctl;
    end
    muxword muxword_writedata (
        .choose(dataM.ctl.memread),
        .muxin0(dataM.aluout),
        .muxin1(dataM.readdata),
        .muxout(dataW.writedata)
    );
endmodule


`endif
