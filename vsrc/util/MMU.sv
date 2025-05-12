`ifndef __MMU_SV
`define __MMU_SV

`ifdef VERILATOR
`include "include/common.sv"
`else

`endif

module MMU
    import common::*;(
    input logic clk, reset,
    
    // 输入虚拟地址请求
    input cbus_req_t ireq,
    output cbus_resp_t iresp,
    
    // 输出物理地址请求
    output cbus_req_t oreq,
    input cbus_resp_t oresp,
    
    // 页表基址寄存器
    input word_t satp
);
    // 页表转换状态
    typedef enum logic [2:0] {
        MMU_IDLE,
        MMU_L1_FETCH,
        MMU_L1_WAIT,
        MMU_L2_FETCH,
        MMU_L2_WAIT,
        MMU_L3_FETCH,
        MMU_L3_WAIT,
        MMU_TRANSLATE
    } mmu_state_t;
    
    mmu_state_t state, next_state;
    logic [63:0] l1_entry, l2_entry, l3_entry;
    addr_t l1_addr, l2_addr, l3_addr, translated_addr;
    addr_t current_vaddr;
    logic mmu_active;
    logic translation_done;
    
    // 保存原始请求
    cbus_req_t saved_req;
    
    // 判断是否启用MMU
    assign mmu_active = satp[63]; // MODE字段为1表示启用Sv39
    
    // 页表转换逻辑
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= MMU_IDLE;
            l1_entry <= '0;
            l2_entry <= '0;
            l3_entry <= '0;
            translated_addr <= '0;
            translation_done <= '0;
            saved_req <= '0;
            current_vaddr <= '0;
        end else begin
            state <= next_state;
            
            case (state)
                MMU_IDLE: begin
                    if (ireq.valid && mmu_active) begin
                        // 保存原始请求
                        saved_req <= ireq;
                        current_vaddr <= ireq.addr;
                        translation_done <= '0;
                        
                        // 计算一级页表项地址
                        // 第一级页表基地址 = {satp[43:0], 12'b0}
                        // 页表项地址 = 页表基地址 + 虚拟地址[38:30] * 8
                        l1_addr <= {satp[43:0], 12'b0} + ({55'b0, ireq.addr[38:30]} << 3);
                    end
                end
                
                MMU_L1_WAIT: begin
                    if (oresp.ready && oresp.last) begin
                        // 保存一级页表项
                        l1_entry <= oresp.data;
                        
                        // 检查页表项是否有效
                        if (oresp.data[0]) begin
                            // 检查是否是大页(1GB)
                            if (oresp.data[3:1] != 0) begin
                                // 直接翻译为物理地址 (1GB页)
                                translated_addr <= {oresp.data[53:30], current_vaddr[29:0]};
                                translation_done <= 1'b1;
                            end else begin
                                // 计算二级页表项地址
                                l2_addr <= {oresp.data[53:10], 12'b0} + ({55'b0, current_vaddr[29:21]} << 3);
                            end
                        end else begin
                            // 页表项无效，页错误
                            translation_done <= 1'b1;
                            // 这里应该设置页错误标志，但简化处理
                        end
                    end
                end
                
                MMU_L2_WAIT: begin
                    if (oresp.ready && oresp.last) begin
                        // 保存二级页表项
                        l2_entry <= oresp.data;
                        
                        // 检查页表项是否有效
                        if (oresp.data[0]) begin
                            // 检查是否是中页(2MB)
                            if (oresp.data[3:1] != 0) begin
                                // 直接翻译为物理地址 (2MB页)
                                translated_addr <= {oresp.data[53:21], current_vaddr[20:0]};
                                translation_done <= 1'b1;
                            end else begin
                                // 计算三级页表项地址
                                l3_addr <= {oresp.data[53:10], 12'b0} + ({55'b0, current_vaddr[20:12]} << 3);
                            end
                        end else begin
                            // 页表项无效，页错误
                            translation_done <= 1'b1;
                            // 这里应该设置页错误标志，但简化处理
                        end
                    end
                end
                
                MMU_L3_WAIT: begin
                    if (oresp.ready && oresp.last) begin
                        // 保存三级页表项
                        l3_entry <= oresp.data;
                        
                        // 检查页表项是否有效
                        if (oresp.data[0]) begin
                            // 计算最终物理地址 (4KB页)
                            translated_addr <= {oresp.data[53:10], current_vaddr[11:0]};
                        end
                        
                        // 无论如何都完成翻译
                        translation_done <= 1'b1;
                    end
                end
                
                MMU_TRANSLATE: begin
                    // 保持translation_done信号
                    translation_done <= 1'b1;
                end
            endcase
        end
    end
    
    // 页表转换状态机
    always_comb begin
        next_state = state;
        
        case (state)
            MMU_IDLE: begin
                if (ireq.valid && mmu_active) begin
                    next_state = MMU_L1_FETCH;
                end
            end
            
            MMU_L1_FETCH: begin
                next_state = MMU_L1_WAIT;
            end
            
            MMU_L1_WAIT: begin
                if (oresp.ready && oresp.last) begin
                    // 检查页表项是否有效
                    if (oresp.data[0]) begin
                        // 检查是否是大页(1GB)
                        if (oresp.data[3:1] != 0) begin
                            next_state = MMU_TRANSLATE;
                        end else begin
                            next_state = MMU_L2_FETCH;
                        end
                    end else begin
                        // 页表项无效，页错误
                        next_state = MMU_TRANSLATE;
                    end
                end
            end
            
            MMU_L2_FETCH: begin
                next_state = MMU_L2_WAIT;
            end
            
            MMU_L2_WAIT: begin
                if (oresp.ready && oresp.last) begin
                    // 检查页表项是否有效
                    if (oresp.data[0]) begin
                        // 检查是否是中页(2MB)
                        if (oresp.data[3:1] != 0) begin
                            next_state = MMU_TRANSLATE;
                        end else begin
                            next_state = MMU_L3_FETCH;
                        end
                    end else begin
                        // 页表项无效，页错误
                        next_state = MMU_TRANSLATE;
                    end
                end
            end
            
            MMU_L3_FETCH: begin
                next_state = MMU_L3_WAIT;
            end
            
            MMU_L3_WAIT: begin
                if (oresp.ready && oresp.last) begin
                    next_state = MMU_TRANSLATE;
                end
            end
            
            MMU_TRANSLATE: begin
                if (!ireq.valid) begin
                    next_state = MMU_IDLE;
                end
            end
        endcase
    end
    
    // 内存请求生成
    always_comb begin
        // 默认值
        oreq = '0;
        iresp = '0;
        
        case (state)
            MMU_L1_FETCH: begin
                // 发起一级页表项读取请求
                oreq.valid = 1'b1;
                oreq.is_write = 1'b0;
                oreq.addr = l1_addr;
                oreq.size = 3'b011; // 8字节
                oreq.strobe = 8'hFF; // 读取所有字节
                oreq.len = 4'b0000; // 单次突发
                oreq.burst = AXI_BURST_FIXED;
            end
            
            MMU_L2_FETCH: begin
                // 发起二级页表项读取请求
                oreq.valid = 1'b1;
                oreq.is_write = 1'b0;
                oreq.addr = l2_addr;
                oreq.size = 3'b011; // 8字节
                oreq.strobe = 8'hFF; // 读取所有字节
                oreq.len = 4'b0000; // 单次突发
                oreq.burst = AXI_BURST_FIXED;
            end
            
            MMU_L3_FETCH: begin
                // 发起三级页表项读取请求
                oreq.valid = 1'b1;
                oreq.is_write = 1'b0;
                oreq.addr = l3_addr;
                oreq.size = 3'b011; // 8字节
                oreq.strobe = 8'hFF; // 读取所有字节
                oreq.len = 4'b0000; // 单次突发
                oreq.burst = AXI_BURST_FIXED;
            end
            
            MMU_TRANSLATE: begin
                if (translation_done) begin
                    // 转发原始请求，但使用转换后的地址
                    oreq = saved_req;
                    oreq.addr = translated_addr;
                    
                    // 将内存响应传回给原始请求者
                    iresp = oresp;
                end
            end
            
            default: begin
                if (!mmu_active && ireq.valid) begin
                    // 如果MMU未启用，直接转发请求
                    oreq = ireq;
                    iresp = oresp;
                end
            end
        endcase
    end
    
endmodule

`endif