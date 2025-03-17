`ifndef __FWD_SV
`define __FWD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module fwd 
    import common::*;
    import pipes::*;(
    input word_t a_pc, b_pc,
    input creg_addr_t src, dst,
    input u1 regwrite,
    input word_t fwddata,
    output fwd_data_t fwd
);
    always_comb begin
        fwd = '0;
        if(a_pc != b_pc & regwrite & (dst != 5'b0) & (src == dst)) begin
            fwd.enable = '1;
            fwd.data = fwddata;
        end
    end
endmodule

`endif