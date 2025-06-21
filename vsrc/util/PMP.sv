`ifndef __PMP_SV
`define __PMP_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module PMP
    import common::*;
    import pipes::*;(
    input logic clk, reset,
    input cbus_req_t ireq,
    output cbus_resp_t iresp,
    output cbus_req_t oreq,
    input cbus_resp_t oresp,
    input word_t pmpaddr0,
    input word_t pmpcfg0,
    input u2 priviledgeMode
);

    // PMP configuration fields from pmpcfg0
    logic [1:0] pmp_a;     // Address matching mode (bits 4:3)
    logic pmp_x;           // Execute permission (bit 2)
    logic pmp_w;           // Write permission (bit 1)
    logic pmp_r;           // Read permission (bit 0)
    logic pmp_l;           // Lock bit (bit 7)
    
    // Extract PMP configuration fields
    assign pmp_r = pmpcfg0[0];
    assign pmp_w = pmpcfg0[1];
    assign pmp_x = pmpcfg0[2];
    assign pmp_a = pmpcfg0[4:3];
    assign pmp_l = pmpcfg0[7];
    
    // PMP address calculation (pmpaddr0 is in granules of 4 bytes)
    addr_t pmp_base_addr;
    addr_t pmp_top_addr;
    logic pmp_match;
    logic pmp_permission_ok;
    logic pmp_violation;
    
    // Address matching logic
    always_comb begin
        pmp_base_addr = '0;
        pmp_top_addr = '0;
        pmp_match = 1'b0;
        
        case (pmp_a)
            2'b00: begin // OFF - PMP entry is disabled
                pmp_match = 1'b0;
            end
            2'b01: begin // TOR (Top of Range)
                // For entry 0, base is 0, top is pmpaddr0 << 2
                pmp_base_addr = 64'h0;
                pmp_top_addr = pmpaddr0 << 2;
                pmp_match = (ireq.addr >= pmp_base_addr) && (ireq.addr < pmp_top_addr);
            end
            2'b10: begin // NA4 (Naturally aligned 4-byte region)
                pmp_base_addr = pmpaddr0 << 2;
                pmp_top_addr = pmp_base_addr + 4;
                pmp_match = (ireq.addr >= pmp_base_addr) && (ireq.addr < pmp_top_addr);
            end
            2'b11: begin // NAPOT (Naturally aligned power-of-two region)
                // Find the size by counting trailing 1s in pmpaddr0
                logic [63:0] mask;
                logic [5:0] size_bits;
                
                // Simple NAPOT implementation for common sizes
                if (pmpaddr0[0] == 1'b0) begin
                    // 8-byte region
                    mask = 64'hFFFFFFFFFFFFFFF8;
                    size_bits = 3;
                end else if (pmpaddr0[1:0] == 2'b01) begin
                    // 16-byte region  
                    mask = 64'hFFFFFFFFFFFFFFF0;
                    size_bits = 4;
                end else if (pmpaddr0[2:0] == 3'b011) begin
                    // 32-byte region
                    mask = 64'hFFFFFFFFFFFFFFE0;
                    size_bits = 5;
                end else begin
                    // Default to 4KB page
                    mask = 64'hFFFFFFFFFFFFF000;
                    size_bits = 12;
                end
                
                pmp_base_addr = (pmpaddr0 << 2) & mask;
                pmp_top_addr = pmp_base_addr + (1 << size_bits);
                pmp_match = (ireq.addr >= pmp_base_addr) && (ireq.addr < pmp_top_addr);
            end
        endcase
    end
    
    // Permission checking logic
    always_comb begin
        pmp_permission_ok = 1'b1; // Default allow
        pmp_violation = 1'b0;
        
        // Only check permissions if PMP entry matches and is enabled
        if (pmp_match && pmp_a != 2'b00) begin
            // Machine mode bypasses PMP unless locked
            if (priviledgeMode == 2'b11 && !pmp_l) begin
                pmp_permission_ok = 1'b1;
            end else begin
                // Check specific permissions based on access type
                if (ireq.is_write) begin
                    // Write access
                    pmp_permission_ok = pmp_w;
                end else begin
                    // Read access (including instruction fetch)
                    pmp_permission_ok = pmp_r;
                end
            end
            
            pmp_violation = !pmp_permission_ok;
        end
    end
    
    // Output logic
    always_comb begin
        if (pmp_violation && ireq.valid) begin
            // Block the request and return error response
            oreq = '0;
            iresp.ready = 1'b1;
            iresp.last = 1'b1;
            iresp.data = '0;
        end else begin
            // Pass through the request
            oreq = ireq;
            iresp = oresp;
        end
    end
    
endmodule

`endif