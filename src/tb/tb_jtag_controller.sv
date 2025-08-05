`timescale 1ns / 1ps

/**
 * Enhanced Testbench for JTAG Controller
 * 
 * This testbench validates the functionality of the JTAG controller,
 * including TAP state machine transitions, instruction register operations,
 * and data register operations.
 */
module tb_jtag_controller;

    // Test signals
    reg         tck;         // Test Clock
    reg         tms;         // Test Mode Select
    reg         tdi;         // Test Data In
    wire        tdo;         // Test Data Out
    wire        trst_n_out;  // Test Reset output
    wire [3:0]  state;       // Current state of the JTAG state machine
    wire [3:0]  ir_reg;      // Instruction register
    reg         ext_reset;   // External reset
    
    // State indicator signals
    wire test_logic_reset_state;
    wire run_test_idle_state;
    wire select_dr_scan_state;
    wire capture_dr_state;
    wire shift_dr_state;
    wire exit1_dr_state;
    wire pause_dr_state;
    wire exit2_dr_state;
    wire update_dr_state;
    wire select_ir_scan_state;
    wire capture_ir_state;
    wire shift_ir_state;
    wire exit1_ir_state;
    wire pause_ir_state;
    wire exit2_ir_state;
    wire update_ir_state;
    
    // Instruction constants
    localparam IDCODE  = 4'b0001;
    localparam BYPASS  = 4'b1111;
    localparam EXTEST  = 4'b0000;
    localparam SAMPLE  = 4'b0010;
    
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
    
    // Test variables
    integer     i;
    reg  [3:0]  test_ir;
    integer     errors;
    
    // Instantiate the JTAG controller
    jtag_controller uut (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .trst_n_out(trst_n_out),
        .state(state),
        .ir_reg(ir_reg),
        .ext_reset(ext_reset),
        
        // State indicators
        .test_logic_reset_state(test_logic_reset_state),
        .run_test_idle_state(run_test_idle_state),
        .select_dr_scan_state(select_dr_scan_state),
        .capture_dr_state(capture_dr_state),
        .shift_dr_state(shift_dr_state),
        .exit1_dr_state(exit1_dr_state),
        .pause_dr_state(pause_dr_state),
        .exit2_dr_state(exit2_dr_state),
        .update_dr_state(update_dr_state),
        .select_ir_scan_state(select_ir_scan_state),
        .capture_ir_state(capture_ir_state),
        .shift_ir_state(shift_ir_state),
        .exit1_ir_state(exit1_ir_state),
        .pause_ir_state(pause_ir_state),
        .exit2_ir_state(exit2_ir_state),
        .update_ir_state(update_ir_state)
    );
    
    // Clock generation
    initial begin
        tck = 0;
        forever #5 tck = ~tck;
    end
    
    // Task to reset the TAP controller using ext_reset
    task reset_tap_ext;
        begin
            ext_reset = 1;
            tms = 1;
            tdi = 0;
            #20;
            ext_reset = 0;
            #20;
        end
    endtask
    
    // Task to reset the TAP controller using TMS
    task reset_tap_tms;
        begin
            tms = 1;
            repeat (5) @(posedge tck);
            if (state !== TEST_LOGIC_RESET) begin
                $display("Error: Failed to reset to TEST_LOGIC_RESET using TMS");
                errors = errors + 1;
            end
        end
    endtask
    
    // Task to navigate to a specific TAP state
    task goto_state;
        input [3:0] target_state;
        begin
            // First make sure we're in Test-Logic-Reset
            reset_tap_tms();
            
            case (target_state)
                TEST_LOGIC_RESET: begin
                    // Already in TEST_LOGIC_RESET
                end
                
                RUN_TEST_IDLE: begin
                    tms = 0;
                    @(posedge tck);
                end
                
                SELECT_DR_SCAN: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                end
                
                CAPTURE_DR: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 0;
                    @(posedge tck);
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
                end
                
                PAUSE_DR: begin
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
                    tms = 0;
                    @(posedge tck);
                end
                
                EXIT2_DR: begin
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
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
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
                end
                
                SELECT_IR_SCAN: begin
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
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
                end
                
                EXIT1_IR: begin
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
                end
                
                PAUSE_IR: begin
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
                    tms = 0;
                    @(posedge tck);
                end
                
                EXIT2_IR: begin
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
                    tms = 0;
                    @(posedge tck);
                    tms = 1;
                    @(posedge tck);
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
                end
                
                default: begin
                    $display("Error: Unknown target state %h", target_state);
                    errors = errors + 1;
                end
            endcase
            
            // Verify we've reached the target state
            if (state !== target_state) begin
                $display("Error: Failed to reach state %h. Current state: %h", target_state, state);
                errors = errors + 1;
            end
        end
    endtask
    
    // Task to load instruction register
    task load_ir;
        input [3:0] ir_value;
        begin
            // Go to Shift-IR state
            goto_state(SHIFT_IR);
            
            // Shift in IR value (LSB first)
            for (i = 0; i < 4; i = i + 1) begin
                tdi = ir_value[i];
                if (i == 3) tms = 1; // Exit on last bit
                @(posedge tck);
            end
            
            // Go to Update-IR
            tms = 1;
            @(posedge tck);
            
            // Verify IR value
            if (ir_reg !== ir_value) begin
                $display("Error: IR value mismatch. Expected: %h, Got: %h", ir_value, ir_reg);
                errors = errors + 1;
            end
        end
    endtask
    
    // Task to test bypass mode
    task test_bypass;
        begin
            // Load BYPASS instruction
            load_ir(BYPASS);
            
            // Go to Shift-DR state
            goto_state(SHIFT_DR);
            
            // Shift pattern through bypass register
            tdi = 1'b1;
            @(posedge tck);
            
            // Bypass should have 1-bit delay
            if (tdo !== 1'b0) begin
                $display("Error: Bypass first bit should be 0, got %b", tdo);
                errors = errors + 1;
            end
            
            @(posedge tck);
            if (tdo !== 1'b1) begin
                $display("Error: Bypass second bit should be 1, got %b", tdo);
                errors = errors + 1;
            end
            
            tdi = 1'b0;
            @(posedge tck);
            if (tdo !== 1'b1) begin
                $display("Error: Bypass third bit should be 1, got %b", tdo);
                errors = errors + 1;
            end
            
            @(posedge tck);
            if (tdo !== 1'b0) begin
                $display("Error: Bypass fourth bit should be 0, got %b", tdo);
                errors = errors + 1;
            end
            
            // Exit Shift-DR
            tms = 1;
            @(posedge tck);
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        tck = 0;
        tms = 0;
        tdi = 0;
        ext_reset = 0;
        errors = 0;
        
        // Display test start
        $display("Starting Enhanced JTAG Controller Test");
        
        // Test 1: Reset and check initial state
        $display("Test 1: Reset and initial state check");
        reset_tap_ext();
        if (state !== TEST_LOGIC_RESET) begin
            $display("Error: Initial state not TEST_LOGIC_RESET, got %h", state);
            errors = errors + 1;
        end
        
        // Test 2: State transitions through all TAP states
        $display("Test 2: State transition tests");
        
        // Test each state
        goto_state(TEST_LOGIC_RESET);
        goto_state(RUN_TEST_IDLE);
        goto_state(SELECT_DR_SCAN);
        goto_state(CAPTURE_DR);
        goto_state(SHIFT_DR);
        goto_state(EXIT1_DR);
        goto_state(PAUSE_DR);
        goto_state(EXIT2_DR);
        goto_state(UPDATE_DR);
        goto_state(SELECT_IR_SCAN);
        goto_state(CAPTURE_IR);
        goto_state(SHIFT_IR);
        goto_state(EXIT1_IR);
        goto_state(PAUSE_IR);
        goto_state(EXIT2_IR);
        goto_state(UPDATE_IR);
        
        // Test 3: Instruction register operations
        $display("Test 3: Instruction register operations");
        
        // Load various instructions
        load_ir(IDCODE);
        load_ir(BYPASS);
        load_ir(EXTEST);
        load_ir(SAMPLE);
        
        // Test 4: Bypass functionality
        $display("Test 4: Bypass functionality");
        test_bypass();
        
        // Test 5: Reset using TMS sequence
        $display("Test 5: Reset using TMS sequence");
        
        // Go to Run-Test/Idle
        goto_state(RUN_TEST_IDLE);
        
        // Reset using TMS sequence
        reset_tap_tms();
        
        // Report results
        if (errors == 0) begin
            $display("All JTAG controller tests passed successfully!");
        end else begin
            $display("JTAG controller tests completed with %d errors", errors);
        end
        
        #100;
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time: %0t, state: %h, tck: %b, tms: %b, tdi: %b, tdo: %b", 
                 $time, state, tck, tms, tdi, tdo);
    end

endmodule