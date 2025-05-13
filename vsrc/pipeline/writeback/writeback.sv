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
        dataW.valid = dataM.raw_instr != '0;
        dataW.pc = dataM.pc;
        dataW.raw_instr = dataM.raw_instr;
        dataW.dst = dataM.dst;
        dataW.ra1 = dataM.ra1;
        dataW.ra2 = dataM.ra2;
        dataW.ctl = dataM.ctl;
        dataW.writedata = dataM.writedata;
        dataW.csrdata = dataM.csrdata;
        dataW.memaddr = dataM.memaddr;
        dataW.csraddr = dataM.csraddr;
        dataW.excep = dataM.excep;
        dataW.priviledgeMode = dataM.priviledgeMode;
    end
endmodule


`endif
