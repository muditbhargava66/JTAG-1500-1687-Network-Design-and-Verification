`timescale 1ns / 1ps

/**
 * Updated Testbench for Top Module
 * 
 * This testbench validates the integrated functionality of the complete
 * JTAG/1500/1687 Network, including transitions between different modes
 * and interactions between components.
 */
module tb_top_module;

    // Test signals
    reg         tck;         // Test Clock
    reg         tms;         // Test Mode Select
    reg         tdi;         // Test Data In
    wire        tdo;         // Test Data Out
    reg         trst_n;      // Test Reset (active low)
    
    reg         clk;         // System clock
    reg         reset;       // System reset
    
    reg  [7:0]  loopback_data_in;
    wire [7:0]  loopback_data_out;
    
    reg  [3:0]  bsc_control;
    reg  [7:0]  bsc_data_in;
    wire [7:0]  bsc_data_out;
    
    wire [7:0]  instrument_data;
    wire [3:0]  instrument_addr;
    wire        instrument_enable;
    reg  [7:0]  instrument_status;
    
    // TAP states
    localparam TEST_LOGIC_RESET = 4'b0000;
    localparam RUN_TEST_IDLE    = 4'b0001;
    localparam SELECT_DR_SCAN   = 4'b0010;
    localparam CAPTURE_DR       = 4'b0011;
    localparam SHIFT_DR         = 4'b0100;
    localparam EXIT1_DR         = 4'b0101;
    localparam PAUSE_DR         = 4'b0110;
    localparam EXIT2_DR         = 4'b0111;
    localparam UPDATE_DR        = 4'b1000;
    localparam SELECT_IR_SCAN   = 4'b1001;
    localparam CAPTURE_IR       = 4'b1010;
    localparam SHIFT_IR         = 4'b1011;
    localparam EXIT1_IR         = 4'b1100;
    localparam PAUSE_IR         = 4'b1101;
    localparam EXIT2_IR         = 4'b1110;
    localparam UPDATE_IR        = 4'b1111;
    
    // Instructions
    localparam BYPASS      = 4'b0000;
    localparam EXTEST      = 4'b0001;
    localparam SAMPLE      = 4'b0010;
    localparam IEEE1500    = 4'b0100;
    localparam IEEE1687    = 4'b1000;
    
    // Test variables
    integer     i;
    reg  [3:0]  test_ir;
    reg  [31:0] test_dr;
    reg  [31:0] read_dr;
    integer     errors;
    
    // Instantiate the top module
    top_module uut (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .trst_n(trst_n),
        .clk(clk),
        .reset(reset),
        .loopback_data_in(loopback_data_in),
        .loopback_data_out(loopback_data_out),
        .bsc_control(bsc_control),
        .bsc_data_in(bsc_data_in),
        .bsc_data_out(bsc_data_out),
        .instrument_data(instrument_data),
        .instrument_addr(instrument_addr),
        .instrument_enable(instrument_enable),
        .instrument_status(instrument_status)
    );
    
    // Clock generation for tck and clk
    initial begin
        tck = 0;
        clk = 0;
        forever begin
            #5 tck = ~tck;
            #5 clk = ~clk;
        end
    end
    
    // Task to reset the system
    task reset_system;
        begin
            trst_n = 0;
            reset = 1;
            tms = 1;
            tdi = 0;
            bsc_control = 4'b0000;
            bsc_data_in = 8'h00;
            loopback_data_in = 8'h00;
            instrument_status = 8'h00;
            
            #20;
            trst_n = 1;
            reset = 0;
            #20;
        end
    endtask
    
    // Task to navigate to a specific TAP state
    task goto_state;
        input [3:0] target_state;
        input integer verbose;
        begin
            // First make sure we're in Test-Logic-Reset
            tms = 1;
            repeat (5) @(posedge tck);
            
            case (target_state)
                TEST_LOGIC_RESET: begin
                    // Already in TEST_LOGIC_RESET
                    if (verbose) $display("Already in TEST_LOGIC_RESET");
                end
                
                RUN_TEST_IDLE: begin
                    tms = 0;
                    @(posedge tck);
                    if (verbose) $display("Moved to RUN_TEST_IDLE");
                end
                
                SELECT_DR_SCAN: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    if (verbose) $display("Moved to SELECT_DR_SCAN");
                end
                
                CAPTURE_DR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    if (verbose) $display("Moved to CAPTURE_DR");
                end
                
                SHIFT_DR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    if (verbose) $display("Moved to SHIFT_DR");
                end
                
                EXIT1_DR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    if (verbose) $display("Moved to EXIT1_DR");
                end
                
                UPDATE_DR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    if (verbose) $display("Moved to UPDATE_DR");
                end
                
                SELECT_IR_SCAN: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    if (verbose) $display("Moved to SELECT_IR_SCAN");
                end
                
                CAPTURE_IR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    if (verbose) $display("Moved to CAPTURE_IR");
                end
                
                SHIFT_IR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    if (verbose) $display("Moved to SHIFT_IR");
                end
                
                UPDATE_IR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    if (verbose) $display("Moved to UPDATE_IR");
                end
                
                default: begin
                    $display("Error: Unknown target state %h", target_state);
                    errors = errors + 1;
                end
            endcase
        end
    endtask
    
    // Task to load instruction register
    task load_ir;
        input [3:0] ir_value;
        begin
            // Go to Shift-IR state
            goto_state(SHIFT_IR, 0);
            
            // Shift in IR value (LSB first)
            for (i = 0; i < 4; i = i + 1) begin
                tdi = ir_value[i];
                if (i == 3) tms = 1; // Exit on last bit
                @(posedge tck);
            end
            
            // Go to Update-IR
            tms = 1;
            @(posedge tck);
            
            // Go to Run-Test/Idle
            tms = 0;
            @(posedge tck);
            
            $display("Loaded instruction: %h", ir_value);
        end
    endtask
    
    // Task to shift data through DR
    task shift_dr;
        input  [31:0] data_in;
        output [31:0] data_out;
        input  integer width;
        begin
            // Go to Shift-DR state
            goto_state(SHIFT_DR, 0);
            
            // Initialize data_out
            data_out = 0;
            
            // Shift data
            for (i = 0; i < width; i = i + 1) begin
                tdi = data_in[i];
                if (i == width-1) tms = 1; // Exit on last bit
                @(posedge tck);
                data_out[i] = tdo;
            end
            
            // Go to Update-DR
            tms = 1;
            @(posedge tck);
            
            // Go to Run-Test/Idle
            tms = 0;
            @(posedge tck);
            
            $display("Shifted %0d bits: In=%h, Out=%h", width, data_in, data_out);
        end
    endtask
    
    // Task to test boundary scan chain
    task test_boundary_scan;
        begin
            $display("Testing Boundary Scan Chain");
            
            // Load EXTEST instruction
            load_ir(EXTEST);
            
            // Test different patterns
            test_dr = 32'hA5A5A5A5;
            shift_dr(test_dr, read_dr, 8);
            
            test_dr = 32'h5A5A5A5A;
            shift_dr(test_dr, read_dr, 8);
            
            // Check boundary scan outputs
            if (bsc_data_out !== test_dr[7:0]) begin
                $display("Error: BSC data mismatch. Expected: %h, Got: %h", 
                         test_dr[7:0], bsc_data_out);
                errors = errors + 1;
            end
        end
    endtask
    
    // Task to test IEEE 1687 mode
    task test_ieee1687_mode;
        begin
            $display("Testing IEEE 1687 Network");
            
            // Load IEEE1687 instruction
            load_ir(IEEE1687);
            
            // Set instrument status for readback
            instrument_status = 8'hA5;
            
            // Test instrument access
            test_dr = {4'h3, 8'h5A, 20'h0}; // Addr 3, Data 5A
            shift_dr(test_dr, read_dr, 16);
            
            // Verify instrument signals
            if (instrument_addr !== 4'h3) begin
                $display("Error: Instrument addr mismatch. Expected: 3, Got: %h", 
                         instrument_addr);
                errors = errors + 1;
            end
            
            if (instrument_data !== 8'h5A) begin
                $display("Error: Instrument data mismatch. Expected: 5A, Got: %h", 
                         instrument_data);
                errors = errors + 1;
            end
            
            if (instrument_enable !== 1'b1) begin
                $display("Error: Instrument not enabled");
                errors = errors + 1;
            end
            
            // Read back status
            test_dr = 32'h0;
            shift_dr(test_dr, read_dr, 16);
            
            if ((read_dr & 8'hFF) !== 8'hA5) begin
                $display("Error: Status readback mismatch. Expected: A5, Got: %h", 
                         read_dr & 8'hFF);
                errors = errors + 1;
            end
        end
    endtask
    
    // Task to test IEEE 1500 mode
    task test_ieee1500_mode;
        begin
            $display("Testing IEEE 1500 Wrapper");
            
            // Load IEEE1500 instruction
            load_ir(IEEE1500);
            
            // Test WIR operations
            test_dr = {3'b001, 29'h0}; // EXTEST instruction for WIR
            shift_dr(test_dr, read_dr, 3);
            
            // Test WDR operations with test pattern
            test_dr = {8'hA5, 8'h5A, 16'h0}; // Input A5, Expected output 5A
            shift_dr(test_dr, read_dr, 16);
            
            // Set core input to check wrapper behavior
            loopback_data_in = 8'h33;
            #10;
            
            // Verify core_outputs
            if (loopback_data_out !== 8'h33) begin
                $display("Error: Core output mismatch. Expected: 33, Got: %h", 
                          loopback_data_out);
                errors = errors + 1;
            end
        end
    endtask
    
    // Task to test loopback mode
    task test_loopback;
        begin
            $display("Testing Loopback Module");
            
            // Test different patterns
            loopback_data_in = 8'h55;
            #10;
            if (loopback_data_out !== 8'h55) begin
                $display("Error: Loopback data mismatch. Expected: 55, Got: %h", 
                          loopback_data_out);
                errors = errors + 1;
            end
            
            loopback_data_in = 8'hAA;
            #10;
            if (loopback_data_out !== 8'hAA) begin
                $display("Error: Loopback data mismatch. Expected: AA, Got: %h", 
                          loopback_data_out);
                errors = errors + 1;
            end
            
            loopback_data_in = 8'hFF;
            #10;
            if (loopback_data_out !== 8'hFF) begin
                $display("Error: Loopback data mismatch. Expected: FF, Got: %h", 
                          loopback_data_out);
                errors = errors + 1;
            end
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize test
        errors = 0;
        
        // Display test start
        $display("Starting Top Module Test");
        
        // Reset system
        reset_system();
        
        // Test each component
        test_loopback();
        test_boundary_scan();
        test_ieee1687_mode();
        test_ieee1500_mode();
        
        // Test mode switching
        $display("Testing mode switching");
        
        // Switch between modes
        load_ir(EXTEST);
        #10;
        load_ir(IEEE1687);
        #10;
        load_ir(IEEE1500);
        #10;
        load_ir(BYPASS);
        #10;
        
        // Report results
        if (errors == 0) begin
            $display("All top module tests passed successfully!");
        end else begin
            $display("Top module tests completed with %d errors", errors);
        end
        
        #100;
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time: %0t, tck: %b, tdi: %b, tdo: %b", $time, tck, tdi, tdo);
    end

endmodule