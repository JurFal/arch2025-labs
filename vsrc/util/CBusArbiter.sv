`ifndef __CBUSARBITER_SV
`define __CBUSARBITER_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "util/MMU.sv"
`else

`endif
/**
 * this implementation is not efficient, since
 * it adds one cycle lantency to all requests.
 */

module CBusArbiter
	import common::*;
	import pipes::*;#(
    parameter int NUM_INPUTS = 2,  // NOTE: NUM_INPUTS >= 1

    localparam int MAX_INDEX = NUM_INPUTS - 1
) (
    input logic clk, reset,

    input  cbus_req_t  [MAX_INDEX:0] ireqs,
    output cbus_resp_t [MAX_INDEX:0] iresps,
    output cbus_req_t  oreq,
    input  cbus_resp_t oresp,
    input u2 priviledgeMode,
    input satp_t satp

);
    logic busy;
    int index, select;
    cbus_req_t saved_req, selected_req;
    cbus_req_t mmu_req;

    logic mmu_enable;
    addr_t physical_addr;
    logic translation_done, translation_done_p;

    MMU mmu_inst(
        .clk,
        .reset,
        .virtual_addr(ireqs[index].addr),
        .enable(mmu_enable),
        .request_valid(busy),
        .physical_addr,
        .translation_done,
        .satp
    );

    assign mmu_enable = satp[63];



    always_ff @(posedge clk)
    if (~reset) begin
        if (oresp.last)
            translation_done_p <= '0;
        else if (translation_done)
                translation_done_p <= 1'b1;
    end else begin
        translation_done_p <= '0;
    end

    
    always_comb begin
        mmu_req.is_write = ireqs[index].is_write;
        mmu_req.size = ireqs[index].size;
        mmu_req.strobe = ireqs[index].strobe;
        mmu_req.data = ireqs[index].data;
        mmu_req.len = ireqs[index].len;
        mmu_req.burst = ireqs[index].burst;
        mmu_req.valid = !mmu_enable | translation_done | translation_done_p;
        mmu_req.addr = (mmu_enable && (translation_done | translation_done_p)) ? physical_addr : ireqs[index].addr;
    end

    // assign oreq = ireqs[index];
    assign oreq = busy ? mmu_req : '0;  // prevent early issue
    assign selected_req = ireqs[select];

    // select a preferred request
    always_comb begin
        select = 0;

        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (ireqs[i].valid) begin
                select = i;
                break;
            end
        end
    end

    // feedback to selected request
    always_comb begin
        iresps = '0;

        if (busy) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (index == i)
                    iresps[i] = oresp;
            end
        end
    end

    always_ff @(posedge clk)
    if (~reset) begin
        if (busy) begin
            if (oresp.last)
                {busy, saved_req} <= '0;
        end else begin
            // if not valid, busy <= 0
            busy <= selected_req.valid;
            index <= select;
            saved_req <= selected_req;
        end
    end else begin
        {busy, index, saved_req} <= '0;
    end

    `UNUSED_OK({saved_req});
endmodule



`endif