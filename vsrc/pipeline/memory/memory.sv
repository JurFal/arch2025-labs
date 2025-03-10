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
    output memory_data_t dataM,
    output dbus_req_t dreq,
    input dbus_resp_t dresp
);

    u3 float;
    assign float = dataE.aluout[2:0];
    always_comb begin
        dataM.valid = '1;
        dataM.pc = dataE.pc;
        dataM.raw_instr = dataE.raw_instr;
        dataM.dst = dataE.dst;
        dataM.aluout = dataE.aluout;
        dreq = '0;
        dataM.ctl = dataE.ctl;
        if(dataE.ctl.memread || dataE.ctl.memwrite) begin
            dreq.valid = '1;
            dreq.addr = dataE.aluout;
            dreq.size = dataE.ctl.memsize;
            if(dataE.ctl.memwrite) begin
                dreq.data = dataE.memwd << (float << 8);
                case(dataE.ctl.memsize)
                    MSIZE1: dreq.strobe = 8'h01 << float;
                    MSIZE2: dreq.strobe = 8'h03 << float;
                    MSIZE4: dreq.strobe = 8'h0f << float;
                    MSIZE8: dreq.strobe = 8'hff << float;
                    default: dreq.strobe = '0;
                endcase
            end
        end
        dataM.readdata = dresp.data;
    end

endmodule


`endif
