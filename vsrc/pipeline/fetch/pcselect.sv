`ifndef __PCSELECT_SV
`define __PCSELECT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif 

module pcselect 
    import common::*;
    import pipes::*;(

    output u64 pc_out,
    input u64 pcp4
);

    assign pc_out = pcp4;

endmodule



`endif
