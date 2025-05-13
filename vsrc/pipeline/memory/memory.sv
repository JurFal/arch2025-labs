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

    u3 offset;
    word_t rd0, rd1, rd1sg, rd, offset1;
    assign offset = dataE.aluout[2:0];
    assign offset1 = {61'b0, offset} << 3;
    always_comb begin
        dataM.valid = '1;
        dataM.pc = dataE.pc;
        dataM.raw_instr = dataE.raw_instr;
        dataM.dst = dataE.dst;
        dataM.ra1 = dataE.ra1;
        dataM.ra2 = dataE.ra2;
        dataM.ctl = dataE.ctl;
        dataM.excep = dataE.excep;
        dataM.priviledgeMode = dataE.priviledgeMode_new;
        rd0 = '0;
        rd1 = '0;
        rd1sg = '0;
        if(dataE.ctl.memread) begin
            rd0 = dresp.data >> offset1;
            case(dataE.ctl.memsize)
                MSIZE1: begin
                    rd1 = rd0 & 64'hff;
                    rd1sg = {{56{rd1[7]}}, rd1[7:0]};
                end
                MSIZE2: begin
                    rd1 = rd0 & 64'hffff;
                    rd1sg = {{48{rd1[15]}}, rd1[15:0]};
                end
                MSIZE4: begin
                    rd1 = rd0 & 64'hffffffff;
                    rd1sg = {{32{rd1[31]}}, rd1[31:0]};
                end
                MSIZE8: begin
                    rd1 = rd0;
                    rd1sg = rd1;
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
                dreq.data <= dataE.memwd << offset1;
                case(dataE.ctl.memsize)
                    MSIZE1: dreq.strobe <= 8'h01 << offset;
                    MSIZE2: dreq.strobe <= 8'h03 << offset;
                    MSIZE4: dreq.strobe <= 8'h0f << offset;
                    MSIZE8: dreq.strobe <= 8'hff << offset;
                    default: dreq.strobe <= '0;
                endcase
            end
        end
    end

    word_t writedata1, writedata2;

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

    muxword muxword_csrwritedata (
        .choose(dataE.ctl.csrsrc),
        .muxin0(writedata1),
        .muxin1(dataE.csrdata),
        .muxout(writedata2)
    );

    assign dataM.writedata = (dataE.ctl.regwrite & dataE.dst != '0) ? writedata2 : '0;
    assign dataM.csrdata = (dataE.ctl.csrsrc) ? writedata1 : '0;
    assign dataM.memaddr = (dataE.ctl.memread | dataE.ctl.memwrite) ? dataE.aluout : '0;
    assign dataM.csraddr = dataE.csraddr;

endmodule


`endif
