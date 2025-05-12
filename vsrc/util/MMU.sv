`ifndef __MMU_SV
`define __MMU_SV

`ifdef VERILATOR
`include "include/common.sv"
`else

`endif

module MMU
    import common::*;(
    input logic clk, reset,
    
    // 输入虚拟地址
    input addr_t virtual_addr,
    input logic enable,
    input logic request_valid,
    
    // 输出物理地址
    output addr_t physical_addr,
    output logic translation_done,
    
    // 页表基址寄存器
    input word_t satp
);
    // 页表转换状态
    typedef enum logic [1:0] {
        MMU_IDLE,
        MMU_L1_ACCESS,
        MMU_L2_ACCESS,
        MMU_L3_ACCESS
    } mmu_state_t;
    
    mmu_state_t mmu_state, mmu_next_state;
    logic [63:0] l1_entry, l2_entry, l3_entry;
    logic mmu_active;
    
    // 判断是否启用MMU
    assign mmu_active = enable && satp[63];
    
    // 页表转换逻辑
    always_ff @(posedge clk) begin
        if (reset) begin
            mmu_state <= MMU_IDLE;
            l1_entry <= '0;
            l2_entry <= '0;
            l3_entry <= '0;
            physical_addr <= '0;
            translation_done <= '0;
        end else begin
            mmu_state <= mmu_next_state;
            
            case (mmu_state)
                MMU_IDLE: begin
                    if (mmu_active && request_valid) begin
                        // 开始页表转换
                        translation_done <= '0;
                    end
                end
                
                MMU_L1_ACCESS: begin
                    // 模拟从内存读取一级页表项
                    l1_entry <= 64'h0000_0000_1000_0000 | ({55'b0, virtual_addr[38:30]} << 3);
                end
                
                MMU_L2_ACCESS: begin
                    // 模拟从内存读取二级页表项
                    l2_entry <= 64'h0000_0000_2000_0000 | ({55'b0, virtual_addr[29:21]} << 3);
                end
                
                MMU_L3_ACCESS: begin
                    // 模拟从内存读取三级页表项
                    l3_entry <= 64'h0000_0000_3000_0000 | ({55'b0, virtual_addr[20:12]} << 3);
                    // 计算最终物理地址
                    physical_addr <= {8'b0, l3_entry[53:10], virtual_addr[11:0]};
                    translation_done <= '1;
                end
            endcase
        end
    end
    
    // 页表转换状态机
    always_comb begin
        mmu_next_state = mmu_state;
        
        case (mmu_state)
            MMU_IDLE: begin
                if (mmu_active && request_valid) begin
                    mmu_next_state = MMU_L1_ACCESS;
                end
            end
            
            MMU_L1_ACCESS: begin
                mmu_next_state = MMU_L2_ACCESS;
            end
            
            MMU_L2_ACCESS: begin
                mmu_next_state = MMU_L3_ACCESS;
            end
            
            MMU_L3_ACCESS: begin
                mmu_next_state = MMU_IDLE;
            end
        endcase
    end
    
endmodule

`endif