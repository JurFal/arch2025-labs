`ifndef __MEMORY_SV

`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/muxword.sv"
`include "pipeline/memory/mmu.sv"
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
    input csr_t CSR,
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

    word_t physical_addr;
    u1 page_fault, mmu_done;
    dbus_req_t mmu_dreq;
    // 在memory模块中添加MMU实例的连接
    // 注意：这里只连接数据访存部分，指令访存将在core.sv中连接
    mmu mmu_inst (
        .clk(clk),
        .reset(reset),
        
        // 数据访存接口
        .d_vaddr(dataE.aluout),  // 使用ALU计算出的地址作为虚拟地址
        .d_en(dataE.ctl.memread | dataE.ctl.memwrite),  // 内存读写时启用MMU
        .d_is_write(dataE.ctl.memwrite),
        .d_write_data(dataE.aluout),
        .d_mem_size(dataE.ctl.memsize),
        .d_paddr(physical_addr),  // 翻译后的物理地址
        .d_miss(page_fault),      // 页错误信号
        .d_done(mmu_done),        // MMU完成信号
        
        // 指令访存接口 - 在memory模块中不使用，设为0
        .i_vaddr('0),
        .i_en(1'b0),
        .i_paddr(),
        .i_miss(),
        .i_done(),
        
        // CSR寄存器
        .csr(CSR),
        
        // 连接到内存总线
        .dreq(mmu_dreq),
        .dresp
    );

    // 根据MMU状态决定是否发送内存请求
    assign dreq = mmu_done ? mmu_dreq : '0;

    // 处理页错误
    /*always_comb begin
        if (page_fault) begin
            // 设置异常信息
            dataM.excep.valid = 1'b1;
            dataM.excep.code = dataE.ctl.memwrite ? EXCEP_STORE_PAGE_FAULT : EXCEP_LOAD_PAGE_FAULT;
            dataM.excep.tval = dataE.alu_result;  // 保存导致异常的地址
        end
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
    end*/

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
