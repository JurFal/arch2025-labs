`ifndef __MMU_SV
`define __MMU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module MMU
    import common::*;
    import pipes::*;(
    input logic clk, reset, request_valid,
    input cbus_req_t ireq,
    output cbus_resp_t iresp,
    output cbus_req_t oreq,
    input cbus_resp_t oresp,
    input satp_t satp,
    input u2 priviledgeMode
);
    typedef enum logic [2:0] {
        MMU_IDLE,
        MMU_L1_WAIT,
        MMU_L2_WAIT,
        MMU_L3_WAIT,
        MMU_TRANSLATE
    } mmu_state_t;
    
    mmu_state_t state, next_state;
    logic [63:0] l1_entry, l2_entry, l3_entry;
    addr_t l1_addr, l2_addr, l3_addr, translated_addr;
    addr_t current_vaddr;
    logic mmu_active;
    logic translation_done;
    cbus_req_t saved_req;
    logic oresp_ok, oresp_ok_d, oresp_ok_end;
    
    assign oresp_ok = oresp.ready & oresp.last;
    assign oresp_ok_end = oresp_ok_d & !oresp_ok;
    assign mmu_active = satp[63] & (priviledgeMode == 2'b00);

    always_ff @(posedge clk) begin
        if (reset) begin
            oresp_ok_d <= '0;
        end else begin
            oresp_ok_d <= oresp_ok;
        end
    end

    
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
                        saved_req <= ireq;
                        current_vaddr <= ireq.addr;
                        translation_done <= '0;
                        l1_addr <= {8'b0, satp.ppn, 12'b0} + ({55'b0, ireq.addr[38:30]} << 3);
                    end
                end
                
                MMU_L1_WAIT: begin
                    if (oresp_ok) begin
                        l1_entry <= oresp.data;
                        if (oresp.data[0]) begin
                            l2_addr <= {8'b0, oresp.data[53:10], 12'b0} + ({55'b0, current_vaddr[29:21]} << 3);
                        end else begin
                            translation_done <= 1'b1;
                            translated_addr <= current_vaddr;
                        end
                    end
                end
                
                MMU_L2_WAIT: begin
                    if (oresp_ok) begin
                        l2_entry <= oresp.data;
                        if (oresp.data[0]) begin
                            l3_addr <= {8'b0, oresp.data[53:10], 12'b0} + ({55'b0, current_vaddr[20:12]} << 3);
                        end else begin
                            translation_done <= 1'b1;
                            translated_addr <= current_vaddr;
                        end
                    end
                end
                
                MMU_L3_WAIT: begin
                    if (oresp_ok) begin
                        l3_entry <= oresp.data;
                        translation_done <= 1'b1;
                        translated_addr <= {8'b0, oresp.data[53:10], current_vaddr[11:0]};
                        //translated_addr <= current_vaddr;
                    end
                end

                default: begin
                    translation_done <= translation_done;
                end
            endcase
        end
    end
    
    always_comb begin
        next_state = state;
        
        case (state)
            MMU_IDLE: begin
                if (ireq.valid && mmu_active) begin
                    next_state = MMU_L1_WAIT;
                end
            end
            
            MMU_L1_WAIT: begin
                if (oresp_ok_end) begin
                    next_state = MMU_L2_WAIT;
                end
            end
            
            MMU_L2_WAIT: begin
                if (oresp_ok_end) begin
                    next_state = MMU_L3_WAIT;
                end
            end
            
            MMU_L3_WAIT: begin
                if (oresp_ok_end) begin
                    next_state = MMU_TRANSLATE;
                end
            end
            
            MMU_TRANSLATE: begin
                if (!ireq.valid | iresp.last) begin
                    next_state = MMU_IDLE;
                end
            end

            default: begin
                next_state = MMU_IDLE;
            end
        endcase
    end
    
    always_comb begin
        oreq = '0;
        iresp = '0;
        if(request_valid)
            case (state)
                MMU_L1_WAIT: begin
                    oreq.valid = 1'b1;
                    oreq.is_write = 1'b0;
                    oreq.addr = l1_addr;
                    oreq.size = MSIZE8;
                    oreq.strobe = 8'hFF;
                    oreq.len = MLEN1;
                    oreq.burst = AXI_BURST_FIXED;
                end
                
                MMU_L2_WAIT:  begin
                    oreq.valid = 1'b1;
                    oreq.is_write = 1'b0;
                    oreq.addr = l2_addr;
                    oreq.size = MSIZE8;
                    oreq.strobe = 8'hFF;
                    oreq.len = MLEN1;
                    oreq.burst = AXI_BURST_FIXED;
                end
                
                MMU_L3_WAIT:  begin
                    oreq.valid = 1'b1;
                    oreq.is_write = 1'b0;
                    oreq.addr = l3_addr;
                    oreq.size = MSIZE8;
                    oreq.strobe = 8'hFF;
                    oreq.len = MLEN1;
                    oreq.burst = AXI_BURST_FIXED;
                end
                
                MMU_TRANSLATE: begin
                    if (translation_done) begin
                        oreq = saved_req;
                        oreq.addr = translated_addr;
                        iresp = oresp;
                    end
                end
                
                default: begin
                    if (!mmu_active && ireq.valid) begin
                        oreq = ireq;
                        iresp = oresp;
                    end
                end
            endcase
    end
    
endmodule

`endif