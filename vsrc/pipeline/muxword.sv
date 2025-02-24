`ifndef __MUXWORD_SV
`define __MUXWORD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module muxword
    import common::*;
    import pipes::*;(
    input u1 choose,
    input word_t muxin0, muxin1,
    output word_t muxout
);
    always_comb begin
        case(choose)
            0: muxout = muxin0;
            1: muxout = muxin1;
            default: muxout = '0;
        endcase
    end
endmodule


`endif
