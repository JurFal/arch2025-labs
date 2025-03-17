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
    word_t rd1, rd1sg, rd;
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
        if(dataE.ctl.memread) begin
            case(dataE.ctl.memsize)
                MSIZE1: begin
                    rd1 = (dresp.data) & 64'hff;
                    rd1sg = {{56{rd1[7]}}, rd1[7:0]};
                end
                MSIZE2: begin
                    rd1 = (dresp.data) & 64'hffff;
                    rd1sg = {{48{rd1[15]}}, rd1[15:0]};
                end
                MSIZE4: begin
                    rd1 = (dresp.data) & 64'hffffffff;
                    rd1sg = {{32{rd1[31]}}, rd1[31:0]};
                end
                default: begin
                    rd1 = '0;
                    rd1sg = '0;
                end
            endcase
        end
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

    muxword muxword_rdext (
        .choose(dataE.ctl.zeroextwb),
        .muxin0(rd1sg),
        .muxin1(rd1),
        .muxout(rd)
    );

    muxword muxword_writedata (
        .choose(dataE.ctl.memread),
        .muxin0(dataE.aluout),
        .muxin1(rd),
        .muxout(writedata1)
    );
    assign dataM.writedata = (dataE.dst != '0) ? writedata1 : '0;

endmodule


`endif
