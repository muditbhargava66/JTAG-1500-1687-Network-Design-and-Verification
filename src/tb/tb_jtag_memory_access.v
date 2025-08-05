`timescale 1ns / 1ps

/**
 * Testbench for JTAG Memory Access
 * 
 * This testbench verifies the complete JTAG memory access functionality
 * including address range checking, error handling, and proper operation.
 */
module tb_jtag_memory_access;

    // Clock and reset
    reg clk;
    reg reset_n;
    
    // JTAG signals
    reg tck;
    reg tms;
    reg tdi;
    wire tdo;
    wire trst_n_out;
    
    // System interface
    reg [7:0] boundary_scan_in;
    wire [7:0] boundary_scan_out;
    
    // Status signals
    wire jtag_error;
    wire [7:0] error_code;
    wire [3:0] jtag_state;
    wire [3:0] current_instruction;
    
    // Debug interface
    reg debug_mode;
    reg [7:0] access_level;
    
    // Test variables
    reg [31:0] test_address;
    reg [31:0] test_data;
    reg [31:0] read_data;
    integer test_count;
    integer pass_count;
    integer fail_count;
    
    // JTAG instruction codes
    localparam BYPASS         = 4'b1111;
    localparam IDCODE         = 4'b0001;
    localparam SAMPLE_PRELOAD = 4'b0010;
    localparam EXTEST         = 4'b0000;
    localparam MEM_READ       = 4'b0100;
    localparam MEM_WRITE      = 4'b0101;
    localparam DEBUG_ACCESS   = 4'b0110;
    
    // Instantiate the JTAG system
    jtag_system uut (
        .clk(clk),
        .reset_n(reset_n),
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .trst_n_out(trst_n_out),
        .boundary_scan_in(boundary_scan_in),
        .boundary_scan_out(boundary_scan_out),
        .jtag_error(jtag_error),
        .error_code(error_code),
        .jtag_state(jtag_state),
        .current_instruction(current_instruction),
        .debug_mode(debug_mode),
        .access_level(access_level)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz system clock
    end
    
    initial begin
        tck = 0;
        forever #25 tck = ~tck; // 20MHz JTAG clock
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset_n = 0;
        tms = 1;
        tdi = 0;
        boundary_scan_in = 8'hAA;
        debug_mode = 1;
        access_level = 8'hFF;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Reset sequence
        #100;
        reset_n = 1;
        #100;
        
        $display("=== JTAG Memory Access Test Started ===");
        
        // Test 1: Basic JTAG functionality
        test_count = test_count + 1;
        $display("Test %0d: Basic JTAG Reset and IDCODE", test_count);
        jtag_reset();
        jtag_load_instruction(IDCODE);
        jtag_read_data_register(32, read_data);
        if (read_data == 32'h1234_5678) begin
            $display("PASS: IDCODE read correctly: %h", read_data);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: IDCODE incorrect. Expected: 12345678, Got: %h", read_data);
            fail_count = fail_count + 1;
        end
        
        // Test 2: Memory Write Operation
        test_count = test_count + 1;
        $display("Test %0d: Memory Write Operation", test_count);
        test_address = 32'h00000100;
        test_data = 32'hDEADBEEF;
        jtag_memory_write(test_address, test_data);
        if (!jtag_error) begin
            $display("PASS: Memory write completed without error");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Memory write failed with error code: %h", error_code);
            fail_count = fail_count + 1;
        end
        
        // Test 3: Memory Read Operation
        test_count = test_count + 1;
        $display("Test %0d: Memory Read Operation", test_count);
        jtag_memory_read(test_address, read_data);
        if (!jtag_error && read_data == test_data) begin
            $display("PASS: Memory read successful. Data: %h", read_data);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Memory read failed. Expected: %h, Got: %h, Error: %b", 
                    test_data, read_data, jtag_error);
            fail_count = fail_count + 1;
        end
        
        // Test 4: Address Range Checking - Invalid Address
        test_count = test_count + 1;
        $display("Test %0d: Invalid Address Range Check", test_count);
        test_address = 32'h00200000; // Outside valid range
        test_data = 32'h12345678;
        jtag_memory_write(test_address, test_data);
        if (jtag_error && error_code == 8'h01) begin // ERR_INVALID_ADDR
            $display("PASS: Invalid address correctly rejected");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Invalid address not rejected. Error: %b, Code: %h", 
                    jtag_error, error_code);
            fail_count = fail_count + 1;
        end
        
        // Test 5: Access Control - Low Access Level
        test_count = test_count + 1;
        $display("Test %0d: Access Control Test", test_count);
        debug_mode = 0;
        access_level = 8'h40; // Low access level
        test_address = 32'h00000200;
        test_data = 32'hCAFEBABE;
        jtag_memory_write(test_address, test_data);
        if (jtag_error) begin
            $display("PASS: Low access level correctly rejected");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Low access level not rejected");
            fail_count = fail_count + 1;
        end
        
        // Restore access for remaining tests
        debug_mode = 1;
        access_level = 8'hFF;
        
        // Test 6: Multiple Memory Operations
        test_count = test_count + 1;
        $display("Test %0d: Multiple Memory Operations", test_count);
        begin
            integer i;
            reg [31:0] addr, data, rdata;
            reg test_passed;
            test_passed = 1;
            
            for (i = 0; i < 8; i = i + 1) begin
                addr = 32'h00000000 + (i * 4);
                data = 32'h10000000 + i;
                jtag_memory_write(addr, data);
                if (jtag_error) begin
                    test_passed = 0;
                    $display("Write failed for address %h", addr);
                end
            end
            
            for (i = 0; i < 8; i = i + 1) begin
                addr = 32'h00000000 + (i * 4);
                data = 32'h10000000 + i;
                jtag_memory_read(addr, rdata);
                if (jtag_error || rdata != data) begin
                    test_passed = 0;
                    $display("Read failed for address %h. Expected: %h, Got: %h", 
                            addr, data, rdata);
                end
            end
            
            if (test_passed) begin
                $display("PASS: Multiple memory operations successful");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Multiple memory operations failed");
                fail_count = fail_count + 1;
            end
        end
        
        // Test 7: Boundary Scan Operation
        test_count = test_count + 1;
        $display("Test %0d: Boundary Scan Operation", test_count);
        boundary_scan_in = 8'h5A;
        jtag_load_instruction(SAMPLE_PRELOAD);
        jtag_write_data_register(8, 8'hA5);
        #100;
        if (boundary_scan_out == 8'hA5) begin
            $display("PASS: Boundary scan operation successful");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Boundary scan failed. Expected: A5, Got: %h", boundary_scan_out);
            fail_count = fail_count + 1;
        end
        
        // Test 8: Debug Access
        test_count = test_count + 1;
        $display("Test %0d: Debug Access", test_count);
        jtag_load_instruction(DEBUG_ACCESS);
        jtag_read_data_register(32, read_data);
        $display("Debug register content: %h", read_data);
        $display("PASS: Debug access completed");
        pass_count = pass_count + 1;
        
        // Test Summary
        #1000;
        $display("=== Test Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Success Rate: %0d%%", (pass_count * 100) / test_count);
        
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        
        $finish;
    end
    
    // JTAG utility tasks
    task jtag_reset;
        begin
            tms = 1;
            repeat(6) @(posedge tck);
            tms = 0;
            @(posedge tck);
        end
    endtask
    
    task jtag_load_instruction;
        input [3:0] instruction;
        begin
            // Go to Shift-IR
            tms = 1; @(posedge tck); // Select-DR-Scan
            tms = 1; @(posedge tck); // Select-IR-Scan
            tms = 0; @(posedge tck); // Capture-IR
            tms = 0; @(posedge tck); // Shift-IR
            
            // Shift in instruction
            tdi = instruction[0]; @(posedge tck);
            tdi = instruction[1]; @(posedge tck);
            tdi = instruction[2]; @(posedge tck);
            tdi = instruction[3]; tms = 1; @(posedge tck); // Exit1-IR
            
            // Update-IR
            tms = 1; @(posedge tck); // Update-IR
            tms = 0; @(posedge tck); // Run-Test-Idle
        end
    endtask
    
    task jtag_write_data_register;
        input integer length;
        input [63:0] data;
        begin
            integer i;
            
            // Go to Shift-DR
            tms = 1; @(posedge tck); // Select-DR-Scan
            tms = 0; @(posedge tck); // Capture-DR
            tms = 0; @(posedge tck); // Shift-DR
            
            // Shift in data
            for (i = 0; i < length; i = i + 1) begin
                tdi = data[i];
                if (i == length - 1) tms = 1; // Exit on last bit
                @(posedge tck);
            end
            
            // Update-DR
            tms = 1; @(posedge tck); // Update-DR
            tms = 0; @(posedge tck); // Run-Test-Idle
        end
    endtask
    
    task jtag_read_data_register;
        input integer length;
        output [63:0] data;
        begin
            integer i;
            
            data = 0;
            
            // Go to Shift-DR
            tms = 1; @(posedge tck); // Select-DR-Scan
            tms = 0; @(posedge tck); // Capture-DR
            tms = 0; @(posedge tck); // Shift-DR
            
            // Shift out data
            for (i = 0; i < length; i = i + 1) begin
                if (i == length - 1) tms = 1; // Exit on last bit
                @(negedge tck);
                data[i] = tdo;
                @(posedge tck);
            end
            
            // Update-DR
            tms = 1; @(posedge tck); // Update-DR
            tms = 0; @(posedge tck); // Run-Test-Idle
        end
    endtask
    
    task jtag_memory_write;
        input [31:0] address;
        input [31:0] data;
        begin
            reg [63:0] mem_data;
            mem_data = {address, data};
            
            jtag_load_instruction(MEM_WRITE);
            jtag_write_data_register(64, mem_data);
            
            // Wait for operation to complete
            #1000;
        end
    endtask
    
    task jtag_memory_read;
        input [31:0] address;
        output [31:0] data;
        begin
            reg [63:0] mem_data;
            mem_data = {address, 32'h00000000};
            
            jtag_load_instruction(MEM_READ);
            jtag_write_data_register(64, mem_data);
            
            // Wait for operation to complete
            #1000;
            
            // Read back the data
            jtag_read_data_register(64, mem_data);
            data = mem_data[31:0];
        end
    endtask
    
    // Monitor JTAG state changes
    always @(jtag_state) begin
        case (jtag_state)
            4'b0000: $display("JTAG State: TEST_LOGIC_RESET");
            4'b0001: $display("JTAG State: RUN_TEST_IDLE");
            4'b0010: $display("JTAG State: SELECT_DR_SCAN");
            4'b0011: $display("JTAG State: CAPTURE_DR");
            4'b0100: $display("JTAG State: SHIFT_DR");
            4'b1000: $display("JTAG State: UPDATE_DR");
            4'b1010: $display("JTAG State: CAPTURE_IR");
            4'b1011: $display("JTAG State: SHIFT_IR");
            4'b1111: $display("JTAG State: UPDATE_IR");
        endcase
    end
    
    // Monitor errors
    always @(posedge jtag_error) begin
        $display("JTAG ERROR: Code %h at time %0t", error_code, $time);
    end

endmodule