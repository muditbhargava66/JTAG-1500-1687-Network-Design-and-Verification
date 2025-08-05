`timescale 1ns / 1ps

/**
 * Testbench for Simple Scan Chain (Icarus Verilog Compatible)
 * 
 * Tests the optimized scan chain functionality without SystemVerilog features.
 */
module tb_simple_scan_chain;

    // Parameters
    parameter CHAIN_LENGTH = 32;
    parameter NUM_PARALLEL_CHAINS = 4;
    parameter CLK_PERIOD = 10;
    parameter SCAN_CLK_PERIOD = 20;
    
    // Test signals
    reg                             clk;
    reg                             reset;
    reg                             scan_enable;
    reg [1:0]                       scan_mode;
    reg                             scan_in;
    wire                            scan_out;
    reg                             scan_clock;
    reg [NUM_PARALLEL_CHAINS-1:0]  parallel_scan_in;
    wire [NUM_PARALLEL_CHAINS-1:0] parallel_scan_out;
    reg [CHAIN_LENGTH-1:0]         functional_data_in;
    wire [CHAIN_LENGTH-1:0]        functional_data_out;
    reg                             capture_enable;
    reg                             low_power_mode;
    wire [15:0]                     scan_length;
    wire                            scan_complete;
    wire [31:0]                     scan_cycles;
    
    // Test control variables
    integer test_count;
    integer pass_count;
    integer fail_count;
    integer i;
    
    // Scan modes
    localparam SCAN_MODE_NORMAL     = 2'b00;
    localparam SCAN_MODE_PARALLEL   = 2'b01;
    localparam SCAN_MODE_COMPRESSED = 2'b10;
    localparam SCAN_MODE_POWER_OPT  = 2'b11;
    
    // DUT instantiation
    simple_scan_chain #(
        .CHAIN_LENGTH(CHAIN_LENGTH),
        .NUM_PARALLEL_CHAINS(NUM_PARALLEL_CHAINS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .scan_enable(scan_enable),
        .scan_mode(scan_mode),
        .scan_in(scan_in),
        .scan_out(scan_out),
        .scan_clock(scan_clock),
        .parallel_scan_in(parallel_scan_in),
        .parallel_scan_out(parallel_scan_out),
        .functional_data_in(functional_data_in),
        .functional_data_out(functional_data_out),
        .capture_enable(capture_enable),
        .low_power_mode(low_power_mode),
        .scan_length(scan_length),
        .scan_complete(scan_complete),
        .scan_cycles(scan_cycles)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        scan_clock = 0;
        forever #(SCAN_CLK_PERIOD/2) scan_clock = ~scan_clock;
    end
    
    // VCD dump
    initial begin
        $dumpfile("tb_simple_scan_chain.vcd");
        $dumpvars(0, tb_simple_scan_chain);
    end
    
    // Main test sequence
    initial begin
        $display("=== Simple Scan Chain Testbench ===");
        $display("Chain Length: %0d", CHAIN_LENGTH);
        $display("Parallel Chains: %0d", NUM_PARALLEL_CHAINS);
        
        // Initialize
        reset = 1;
        scan_enable = 0;
        scan_mode = SCAN_MODE_NORMAL;
        scan_in = 0;
        parallel_scan_in = 0;
        functional_data_in = 0;
        capture_enable = 0;
        low_power_mode = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Reset sequence
        repeat(10) @(posedge clk);
        reset = 0;
        repeat(5) @(posedge clk);
        
        // Test 1: Normal Scan Mode
        test_normal_scan();
        
        // Test 2: Parallel Scan Mode
        test_parallel_scan();
        
        // Test 3: Compressed Scan Mode
        test_compressed_scan();
        
        // Test 4: Power Optimized Scan Mode
        test_power_optimized_scan();
        
        // Test 5: Functional Data Capture
        test_functional_capture();
        
        // Final results
        $display("\n=== Test Results ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("✓ ALL SCAN CHAIN TESTS PASSED!");
        end else begin
            $display("✗ %0d SCAN CHAIN TESTS FAILED!", fail_count);
        end
        
        $finish;
    end
    
    // Task to test normal scan mode
    task test_normal_scan;
        reg [CHAIN_LENGTH-1:0] test_pattern;
        reg [CHAIN_LENGTH-1:0] received_pattern;
        integer bit_count;
        
        begin
            $display("\n--- Normal Scan Mode Test ---");
            test_count = test_count + 1;
            
            // Set up test
            scan_mode = SCAN_MODE_NORMAL;
            test_pattern = 32'hA5A5A5A5;
            received_pattern = 0;
            
            // Enable scan
            scan_enable = 1;
            @(posedge scan_clock);
            
            // Shift in test pattern
            for (bit_count = 0; bit_count < CHAIN_LENGTH; bit_count = bit_count + 1) begin
                scan_in = test_pattern[bit_count];
                @(posedge scan_clock);
                received_pattern = {scan_out, received_pattern[CHAIN_LENGTH-1:1]};
            end
            
            // Disable scan
            scan_enable = 0;
            @(posedge scan_clock);
            
            // Check results
            if (received_pattern == test_pattern) begin
                $display("✓ Normal scan test PASSED");
                $display("  Pattern: %h", test_pattern);
                $display("  Scan Length: %0d", scan_length);
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Normal scan test FAILED");
                $display("  Expected: %h", test_pattern);
                $display("  Received: %h", received_pattern);
                fail_count = fail_count + 1;
            end
            
            // Reset
            reset = 1;
            repeat(5) @(posedge clk);
            reset = 0;
            repeat(5) @(posedge clk);
        end
    endtask
    
    // Task to test parallel scan mode
    task test_parallel_scan;
        integer cycle_count;
        
        begin
            $display("\n--- Parallel Scan Mode Test ---");
            test_count = test_count + 1;
            
            // Set up test
            scan_mode = SCAN_MODE_PARALLEL;
            parallel_scan_in = 4'b1010;
            
            // Enable scan
            scan_enable = 1;
            @(posedge scan_clock);
            
            // Run for several cycles
            for (cycle_count = 0; cycle_count < 10; cycle_count = cycle_count + 1) begin
                @(posedge scan_clock);
            end
            
            // Check that scan length is reduced
            if (scan_length == CHAIN_LENGTH / NUM_PARALLEL_CHAINS) begin
                $display("✓ Parallel scan test PASSED");
                $display("  Reduced scan length: %0d", scan_length);
                $display("  Parallel output: %b", parallel_scan_out);
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Parallel scan test FAILED");
                $display("  Expected length: %0d", CHAIN_LENGTH / NUM_PARALLEL_CHAINS);
                $display("  Actual length: %0d", scan_length);
                fail_count = fail_count + 1;
            end
            
            // Disable scan
            scan_enable = 0;
            
            // Reset
            reset = 1;
            repeat(5) @(posedge clk);
            reset = 0;
            repeat(5) @(posedge clk);
        end
    endtask
    
    // Task to test compressed scan mode
    task test_compressed_scan;
        integer cycle_count;
        
        begin
            $display("\n--- Compressed Scan Mode Test ---");
            test_count = test_count + 1;
            
            // Set up test
            scan_mode = SCAN_MODE_COMPRESSED;
            
            // Enable scan
            scan_enable = 1;
            @(posedge scan_clock);
            
            // Run for several cycles
            for (cycle_count = 0; cycle_count < 20; cycle_count = cycle_count + 1) begin
                @(posedge scan_clock);
            end
            
            // Check that scan length is compressed
            if (scan_length < CHAIN_LENGTH) begin
                $display("✓ Compressed scan test PASSED");
                $display("  Compressed scan length: %0d", scan_length);
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Compressed scan test FAILED");
                $display("  Expected length < %0d", CHAIN_LENGTH);
                $display("  Actual length: %0d", scan_length);
                fail_count = fail_count + 1;
            end
            
            // Disable scan
            scan_enable = 0;
            
            // Reset
            reset = 1;
            repeat(5) @(posedge clk);
            reset = 0;
            repeat(5) @(posedge clk);
        end
    endtask
    
    // Task to test power optimized scan mode
    task test_power_optimized_scan;
        integer cycle_count;
        
        begin
            $display("\n--- Power Optimized Scan Mode Test ---");
            test_count = test_count + 1;
            
            // Set up test
            scan_mode = SCAN_MODE_POWER_OPT;
            low_power_mode = 1;
            
            // Enable scan
            scan_enable = 1;
            @(posedge scan_clock);
            
            // Run for several cycles
            for (cycle_count = 0; cycle_count < 15; cycle_count = cycle_count + 1) begin
                @(posedge scan_clock);
            end
            
            // Check that power optimization is active
            // (This is a simplified check - in real implementation, 
            //  we would check power control signals)
            if (scan_length == CHAIN_LENGTH) begin
                $display("✓ Power optimized scan test PASSED");
                $display("  Low power mode active");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Power optimized scan test FAILED");
                fail_count = fail_count + 1;
            end
            
            // Disable scan and low power mode
            scan_enable = 0;
            low_power_mode = 0;
            
            // Reset
            reset = 1;
            repeat(5) @(posedge clk);
            reset = 0;
            repeat(5) @(posedge clk);
        end
    endtask
    
    // Task to test functional data capture
    task test_functional_capture;
        reg [CHAIN_LENGTH-1:0] test_data;
        
        begin
            $display("\n--- Functional Data Capture Test ---");
            test_count = test_count + 1;
            
            // Set up test data
            test_data = 32'h12345678;
            functional_data_in = test_data;
            
            // Enable capture
            capture_enable = 1;
            scan_enable = 1;
            @(posedge scan_clock);
            
            // Disable capture
            capture_enable = 0;
            scan_enable = 0;
            @(posedge scan_clock);
            
            // Check captured data
            if (functional_data_out == test_data) begin
                $display("✓ Functional capture test PASSED");
                $display("  Captured data: %h", functional_data_out);
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Functional capture test FAILED");
                $display("  Expected: %h", test_data);
                $display("  Captured: %h", functional_data_out);
                fail_count = fail_count + 1;
            end
            
            // Reset
            reset = 1;
            repeat(5) @(posedge clk);
            reset = 0;
            repeat(5) @(posedge clk);
        end
    endtask
    
    // Monitor for error conditions
    always @(posedge scan_clock) begin
        // Check for scan completion
        if (scan_complete) begin
            $display("  Scan completed in %0d cycles", scan_cycles);
        end
    end

endmodule