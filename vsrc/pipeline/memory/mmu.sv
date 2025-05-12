`ifndef __MMU_SV
`define __MMU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module mmu
    import common::*;
    import pipes::*;(
    input logic clk, reset,
    
    // 数据访存接口
    input word_t d_vaddr,      // 数据虚拟地址输入
    input u1 d_en,             // 数据访存使能信号
    input u1 d_is_write,       // 是否为写操作
    input word_t d_write_data, // 写入数据
    input msize_t d_mem_size,  // 数据内存操作大小
    output word_t d_paddr,     // 翻译后的数据物理地址
    output u1 d_miss,          // 数据缺页异常信号
    output u1 d_done,          // 数据翻译完成信号
    
    // 指令访存接口
    input word_t i_vaddr,      // 指令虚拟地址输入
    input u1 i_en,             // 指令访存使能信号
    output word_t i_paddr,     // 翻译后的指令物理地址
    output u1 i_miss,          // 指令缺页异常信号
    output u1 i_done,          // 指令翻译完成信号
    
    // CSR寄存器
    input csr_t csr,           // CSR寄存器，包含SATP
    
    // 内存接口
    output dbus_req_t  dreq,
    input  dbus_resp_t dresp
);

    // 状态定义
    typedef enum logic [3:0] {
        IDLE,       // 空闲状态
        I_LEVEL1,   // 指令访问第一级页表
        I_LEVEL2,   // 指令访问第二级页表
        I_LEVEL3,   // 指令访问第三级页表
        I_DONE,     // 指令翻译完成
        I_ERROR,    // 指令翻译错误
        D_LEVEL1,   // 数据访问第一级页表
        D_LEVEL2,   // 数据访问第二级页表
        D_LEVEL3,   // 数据访问第三级页表
        D_DONE,     // 数据翻译完成
        D_ERROR     // 数据翻译错误
    } state_t;
    
    state_t state, state_nxt;
    
    // 寄存器
    word_t base_addr;        // 当前页表基地址
    word_t page_entry;       // 当前页表项内容
    u44 final_ppn;           // 最终物理页号
    
    // 页表项标志位
    u1 valid, readable, writable, executable;
    
    // 当前处理的虚拟地址和相关参数
    word_t vaddr;
    u1 is_write;
    word_t write_data;
    msize_t mem_size;
    
    // 索引计算
    u9 idx1, idx2, idx3;
    
    // 根据当前处理的虚拟地址计算索引
    assign idx1 = vaddr[38:30];  // L2索引
    assign idx2 = vaddr[29:21];  // L1索引
    assign idx3 = vaddr[20:12];  // L0索引
    
    // 当前访问的页表项地址
    word_t entry_addr;
    
    // 用于计算字节偏移和strobe
    u3 offset;
    word_t offset1;
    assign offset = vaddr[2:0];
    assign offset1 = {61'b0, offset} << 3;
    
    // 仲裁逻辑 - 选择当前处理的请求
    always_comb begin
        // 默认处理数据请求
        vaddr = d_vaddr;
        is_write = d_is_write;
        write_data = d_write_data;
        mem_size = d_mem_size;
        
        // 状态机处于指令相关状态时，使用指令地址
        if (state == I_LEVEL1 || state == I_LEVEL2 || state == I_LEVEL3 || 
            state == I_DONE || state == I_ERROR) begin
            vaddr = i_vaddr;
            is_write = 1'b0;  // 指令访存总是读操作
            write_data = '0;
            mem_size = MSIZE4; // 指令通常是4字节
        end
    end
    
    // 状态机逻辑
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            base_addr <= '0;
            page_entry <= '0;
            final_ppn <= '0;
        end else begin
            state <= state_nxt;
            
            // 根据状态更新寄存器
            case (state)
                IDLE: begin
                    if ((i_en || d_en) && csr.satp[63:60] != 0) begin  // 检查是否启用分页
                        base_addr <= {8'b0, csr.satp[43:0], 12'b0};  // 根页表基地址
                    end
                end
                
                I_LEVEL1, D_LEVEL1: begin
                    if (dresp.data_ok) begin
                        page_entry <= dresp.data;
                        // 解析页表项标志位
                        valid <= dresp.data[0];
                        readable <= dresp.data[1];
                        writable <= dresp.data[2];
                        executable <= dresp.data[3];
                        
                        // 如果是叶节点(大页)，直接获取PPN
                        if (dresp.data[3]) begin  // Leaf node check (R,W,X bits)
                            final_ppn <= dresp.data[53:10];
                        end else begin
                            base_addr <= {8'b0, dresp.data[53:10], 12'b0};
                        end
                    end
                end
                
                I_LEVEL2, D_LEVEL2: begin
                    if (dresp.data_ok) begin
                        page_entry <= dresp.data;
                        valid <= dresp.data[0];
                        readable <= dresp.data[1];
                        writable <= dresp.data[2];
                        executable <= dresp.data[3];
                        
                        if (dresp.data[3]) begin
                            final_ppn <= dresp.data[53:10];
                        end else begin
                            base_addr <= {8'b0, dresp.data[53:10], 12'b0};
                        end
                    end
                end
                
                I_LEVEL3, D_LEVEL3: begin
                    if (dresp.data_ok) begin
                        page_entry <= dresp.data;
                        valid <= dresp.data[0];
                        readable <= dresp.data[1];
                        writable <= dresp.data[2];
                        executable <= dresp.data[3];
                        
                        final_ppn <= dresp.data[53:10];
                    end
                end
                
                default: begin
                    // 保持当前值
                end
            endcase
        end
    end
    
    // 下一状态逻辑
    always_comb begin
        state_nxt = state;
        
        case (state)
            IDLE: begin
                if (i_en) begin  // 优先处理指令请求
                    if (csr.satp[63:60] == 0) begin
                        // 如果分页未启用，直接完成
                        state_nxt = I_DONE;
                    end else begin
                        // 开始页表遍历
                        state_nxt = I_LEVEL1;
                    end
                end else if (d_en) begin  // 其次处理数据请求
                    if (csr.satp[63:60] == 0) begin
                        // 如果分页未启用，直接完成
                        state_nxt = D_DONE;
                    end else begin
                        // 开始页表遍历
                        state_nxt = D_LEVEL1;
                    end
                end
            end
            
            I_LEVEL1: begin
                if (dresp.data_ok) begin
                    if (~page_entry[0]) begin
                        // 无效页表项
                        state_nxt = I_ERROR;
                    end else if (page_entry[3]) begin
                        // 叶节点，翻译完成
                        state_nxt = I_DONE;
                    end else begin
                        // 继续下一级
                        state_nxt = I_LEVEL2;
                    end
                end
            end
            
            I_LEVEL2: begin
                if (dresp.data_ok) begin
                    if (~page_entry[0]) begin
                        state_nxt = I_ERROR;
                    end else if (page_entry[3]) begin
                        state_nxt = I_DONE;
                    end else begin
                        state_nxt = I_LEVEL3;
                    end
                end
            end
            
            I_LEVEL3: begin
                if (dresp.data_ok) begin
                    if (~page_entry[0]) begin
                        state_nxt = I_ERROR;
                    end else begin
                        state_nxt = I_DONE;
                    end
                end
            end
            
            D_LEVEL1: begin
                if (dresp.data_ok) begin
                    if (~page_entry[0]) begin
                        // 无效页表项
                        state_nxt = D_ERROR;
                    end else if (page_entry[3]) begin
                        // 叶节点，翻译完成
                        state_nxt = D_DONE;
                    end else begin
                        // 继续下一级
                        state_nxt = D_LEVEL2;
                    end
                end
            end
            
            D_LEVEL2: begin
                if (dresp.data_ok) begin
                    if (~page_entry[0]) begin
                        state_nxt = D_ERROR;
                    end else if (page_entry[3]) begin
                        state_nxt = D_DONE;
                    end else begin
                        state_nxt = D_LEVEL3;
                    end
                end
            end
            
            D_LEVEL3: begin
                if (dresp.data_ok) begin
                    if (~page_entry[0]) begin
                        state_nxt = D_ERROR;
                    end else begin
                        state_nxt = D_DONE;
                    end
                end
            end
            
            I_DONE, I_ERROR: begin
                if (~i_en) begin
                    state_nxt = IDLE;
                end
            end
            
            D_DONE, D_ERROR: begin
                if (~d_en) begin
                    state_nxt = IDLE;
                end
            end
            
            default: state_nxt = IDLE;
        endcase
    end
    
    // 内存请求逻辑
    always_comb begin
        dreq.valid = 1'b0;
        dreq.addr = '0;
        dreq.size = MSIZE8;
        dreq.strobe = 8'b0;
        dreq.data = '0;
        
        case (state)
            I_LEVEL1: begin
                dreq.valid = 1'b1;
                dreq.addr = base_addr + ({55'b0, idx1} << 3);  // 基地址 + 索引*8
            end
            
            I_LEVEL2: begin
                dreq.valid = 1'b1;
                dreq.addr = base_addr + ({55'b0, idx2} << 3);
            end
            
            I_LEVEL3: begin
                dreq.valid = 1'b1;
                dreq.addr = base_addr + ({55'b0, idx3} << 3);
            end
            
            D_LEVEL1: begin
                dreq.valid = 1'b1;
                dreq.addr = base_addr + ({55'b0, idx1} << 3);  // 基地址 + 索引*8
            end
            
            D_LEVEL2: begin
                dreq.valid = 1'b1;
                dreq.addr = base_addr + ({55'b0, idx2} << 3);
            end
            
            D_LEVEL3: begin
                dreq.valid = 1'b1;
                dreq.addr = base_addr + ({55'b0, idx3} << 3);
            end
            
            I_DONE: begin
                // 在I_DONE状态时，如果启用了指令访存，设置适当的strobe和size
                if (i_en) begin
                    dreq.valid = 1'b1;
                    dreq.addr = i_paddr;  // 使用翻译后的物理地址
                    dreq.size = MSIZE4;   // 指令通常是4字节
                    dreq.data = '0;
                    dreq.strobe = '0;     // 指令访存是读操作
                end
            end
            
            D_DONE: begin
                // 在D_DONE状态时，如果启用了数据访存，设置适当的strobe和size
                if (d_en) begin
                    dreq.valid = 1'b1;
                    dreq.addr = d_paddr;  // 使用翻译后的物理地址
                    dreq.size = mem_size;
                    
                    // 处理写请求和读请求的不同设置
                    if (is_write) begin
                        dreq.data = write_data << (offset << 3);
                        case(mem_size)
                            MSIZE1: dreq.strobe = 8'h01 << offset;
                            MSIZE2: dreq.strobe = 8'h03 << offset;
                            MSIZE4: dreq.strobe = 8'h0f << offset;
                            MSIZE8: dreq.strobe = 8'hff << offset;
                            default: dreq.strobe = '0;
                        endcase
                    end else begin
                        dreq.data = '0;
                        dreq.strobe = '0;
                    end
                end
            end
            
            default: begin
                dreq.valid = 1'b0;
            end
        endcase
    end
    
    // 输出逻辑 - 指令访存
    assign i_done = (state == I_DONE);
    assign i_miss = (state == I_ERROR);
    
    // 输出逻辑 - 数据访存
    assign d_done = (state == D_DONE);
    assign d_miss = (state == D_ERROR);
    
    // 物理地址组合 - 指令访存
    always_comb begin
        if (state == I_DONE && csr.satp[63:60] != 0) begin
            // 分页启用时的地址转换
            i_paddr = {8'b0, final_ppn, i_vaddr[11:0]};
        end else begin
            // 分页未启用时直接使用虚拟地址
            i_paddr = i_vaddr;
        end
    end
    
    // 物理地址组合 - 数据访存
    always_comb begin
        if (state == D_DONE && csr.satp[63:60] != 0) begin
            // 分页启用时的地址转换
            d_paddr = {8'b0, final_ppn, d_vaddr[11:0]};
        end else begin
            // 分页未启用时直接使用虚拟地址
            d_paddr = d_vaddr;
        end
    end

endmodule

`endif