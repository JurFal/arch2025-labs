// Simple testbench for PMP functionality
`timescale 1ns / 1ps

module test_pmp;
    logic clk, reset;
    
    // Test signals
    cbus_req_t ireq, oreq;
    cbus_resp_t iresp, oresp;
    word_t pmpaddr0, pmpcfg0;
    logic [1:0] priviledgeMode;
    
    // Instantiate PMP module
    PMP dut (
        .clk(clk),
        .reset(reset),
        .ireq(ireq),
        .iresp(iresp),
        .oreq(oreq),
        .oresp(oresp),
        .pmpaddr0(pmpaddr0),
        .pmpcfg0(pmpcfg0),
        .priviledgeMode(priviledgeMode)
    );
    
    // Clock generation
    always #5 clk = ~clk;
    
    initial begin
        // Initialize
        clk = 0;
        reset = 1;
        ireq = '0;
        oresp = '0;
        pmpaddr0 = 64'h1000; // 4KB boundary
        pmpcfg0 = 8'b00001111; // TOR mode, RWX permissions
        priviledgeMode = 2'b00; // User mode
        
        #10 reset = 0;
        
        // Test 1: Access within PMP range (should pass)
        #10;
        ireq.valid = 1;
        ireq.addr = 64'h0800; // Within range [0, 0x4000)
        ireq.is_write = 0;
        oresp.ready = 1;
        oresp.last = 1;
        oresp.data = 64'hDEADBEEF;
        
        #10;
        $display("Test 1 - Access 0x%x: oreq.valid=%b, iresp.ready=%b", 
                 ireq.addr, oreq.valid, iresp.ready);
        
        // Test 2: Access outside PMP range (should be blocked)
        ireq.addr = 64'h5000; // Outside range
        
        #10;
        $display("Test 2 - Access 0x%x: oreq.valid=%b, iresp.ready=%b", 
                 ireq.addr, oreq.valid, iresp.ready);
        
        // Test 3: Machine mode access (should bypass PMP)
        priviledgeMode = 2'b11; // Machine mode
        
        #10;
        $display("Test 3 - Machine mode access 0x%x: oreq.valid=%b, iresp.ready=%b", 
                 ireq.addr, oreq.valid, iresp.ready);
        
        $finish;
    end
    
endmodule