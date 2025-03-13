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
        dataW.ra1 = dataM.ra1;
        dataW.ra2 = dataM.ra2;
        dataW.ctl = dataM.ctl;
    end

    word_t writedata1;
    muxword muxword_writedata (
        .choose(dataM.ctl.memread),
        .muxin0(dataM.aluout),
        .muxin1(dataM.readdata),
        .muxout(writedata1)
    );
    assign dataW.writedata = (dataM.dst != '0) ? writedata1 : '0;
endmodule


`endif
