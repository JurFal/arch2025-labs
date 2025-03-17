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
    input u1 clk, reset,
    input execute_data_t dataE,
    output memory_data_t dataM,
    output dbus_req_t dreq,
    input dbus_resp_t dresp,
    output u1 stallmem
);

    u3 float;
    assign float = dataE.aluout[2:0];
    always_comb begin
        dataM.valid = '1;
        dataM.pc = dataE.pc;
        dataM.raw_instr = dataE.raw_instr;
        dataM.dst = dataE.dst;
        dataM.ra1 = dataE.ra1;
        dataM.ra2 = dataE.ra2;
        dataM.aluout = dataE.aluout;
        dataM.ctl = dataE.ctl;
        dataM.readdata = dresp.data;
        stallmem = ~((dresp.addr_ok & dresp.data_ok) | (~(dataE.ctl.memread | dataE.ctl.memwrite)));
        
    end

    always_ff @(posedge clk) begin
        if(reset) dreq <= '0;
        else if((dresp.addr_ok & dresp.data_ok)) dreq <= '0;
        else if((dataE.ctl.memread | dataE.ctl.memwrite) & ~dreq.valid) begin
            dreq.valid <= '1;
            dreq.addr <= dataE.aluout;
            dreq.size <= dataE.ctl.memsize;
            if(dataE.ctl.memwrite) begin
                dreq.data <= dataE.memwd << (float << 8);
                case(dataE.ctl.memsize)
                    MSIZE1: dreq.strobe <= 8'h01 << float;
                    MSIZE2: dreq.strobe <= 8'h03 << float;
                    MSIZE4: dreq.strobe <= 8'h0f << float;
                    MSIZE8: dreq.strobe <= 8'hff << float;
                    default: dreq.strobe <= '0;
                endcase
            end
        end
    end

    word_t writedata1;
    muxword muxword_writedata (
        .choose(dataE.ctl.memread),
        .muxin0(dataE.aluout),
        .muxin1(dresp.data),
        .muxout(writedata1)
    );
    assign dataM.writedata = (dataE.dst != '0) ? writedata1 : '0;

endmodule


`endif
