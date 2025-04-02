`ifndef __BRANCH_SV
`define __BRANCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module branch
    import common::*;
    import pipes::*;(
    input branchfunc_t branchfunc,
    output u1 branch_enable,
    input word_t src1, src2, pc, aluoutj
);
    always_comb begin
        if(pc != aluoutj)
            case(branchfunc)
                BRH_NEV: branch_enable = '0;
                BRH_AWS: branch_enable = 1'b1;
                BRH_EQL: branch_enable = (src1 == src2);
                BRH_NEQ: branch_enable = (src1 != src2);
                BRH_LST: branch_enable = ($signed(src1) < $signed(src2));
                BRH_LSTU: branch_enable = ($unsigned(src1) < $unsigned(src2));
                BRH_GOE: branch_enable = ($signed(src1) >= $signed(src2));
                BRH_GOEU: branch_enable = ($unsigned(src1) >= $unsigned(src2));
                default: branch_enable = '0;
            endcase
        else branch_enable = '0;
    end

endmodule


`endif
