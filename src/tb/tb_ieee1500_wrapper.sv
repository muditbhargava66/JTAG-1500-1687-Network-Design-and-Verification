`timescale 1ns / 1ps

/**
 * Testbench for IEEE 1500 Wrapper
 * 
 * This testbench validates the functionality of the IEEE 1500 wrapper,
 * including instruction register operations, data register operations,
 * and various test modes.
 */
module tb_ieee1500_wrapper;

    // Test signals
    reg         wrstn;       // Wrapper reset (active low)
    reg         wrck;        // Wrapper clock
    reg         wsi;         // Wrapper serial input
    wire        wso;         // Wrapper serial output
    reg         selectwir;   // Select wrapper instruction register
    reg         capturewir;  // Capture to wrapper instruction register
    reg         shiftwir;    // Shift wrapper instruction register
    reg         updatewir;   // Update wrapper instruction register
    reg         selectwdr;   // Select wrapper data register
    reg         capturewdr;  // Capture to wrapper data register
    reg         shiftwdr;    // Shift wrapper data register
    reg         updatewdr;   // Update wrapper data register
    
    // Core signals
    reg  [7:0]  core_inputs; // Inputs to the core
    wire [7:0]  core_outputs; // Outputs from the core
    
    // Test variables
    integer     i;
    reg  [2:0]  test_ir;
    reg  [15:0] test_dr;
    
    // Instruction constants
    localparam BYPASS = 3'b000;
    localparam EXTEST = 3'b001;
    localparam INTEST = 3'b010;
    localparam SAMPLE = 3'b011;
    localparam CLAMP  = 3'b100;
    
    // Instantiate the IEEE 1500 wrapper
    ieee1500_wrapper uut (
        .wrstn(wrstn),
        .wrck(wrck),
        .wsi(wsi),
        .wso(wso),
        .selectwir(selectwir),
        .capturewir(capturewir),
        .shiftwir(shiftwir),
        .updatewir(updatewir),
        .selectwdr(selectwdr),
        .capturewdr(capturewdr),
        .shiftwdr(shiftwdr),
        .updatewdr(updatewdr),
        .core_inputs(core_inputs),
        .core_outputs(core_outputs)
    );
    
    // Clock generation
    initial begin
        wrck = 0;
        forever #5 wrck = ~wrck;
    end
    
    // Task to reset the wrapper
    task reset_wrapper;
        begin
            wrstn = 0;
            #20;
            wrstn = 1;
            #20;
        end
    endtask
    
    // Task to load instruction register
    task load_ir;
        input [2:0] ir_value;
        begin
            // Setup
            selectwir = 1;
            selectwdr = 0;
            capturewir = 0;
            shiftwir = 0;
            updatewir = 0;
            
            // Capture IR
            #10;
            capturewir = 1;
            #10;
            capturewir = 0;
            
            // Shift in IR value
            shiftwir = 1;
            for (i = 0; i < 3; i = i + 1) begin
                wsi = ir_value[i];
                #10;
            end
            shiftwir = 0;
            
            // Update IR
            updatewir = 1;
            #10;
            updatewir = 0;
            
            // Deselect IR
            #10;
            selectwir = 0;
        end
    endtask
    
    // Task to load data register
    task load_dr;
        input [15:0] dr_value;
        begin
            // Setup
            selectwir = 0;
            selectwdr = 1;
            capturewdr = 0;
            shiftwdr = 0;
            updatewdr = 0;
            
            // Capture DR
            #10;
            capturewdr = 1;
            #10;
            capturewdr = 0;
            
            // Shift in DR value
            shiftwdr = 1;
            for (i = 0; i < 16; i = i + 1) begin
                wsi = dr_value[i];
                #10;
            end
            shiftwdr = 0;
            
            // Update DR
            updatewdr = 1;
            #10;
            updatewdr = 0;
            
            // Deselect DR
            #10;
            selectwdr = 0;
        end
    endtask
    
    // Task to read data register
    task read_dr;
        output [15:0] dr_value;
        begin
            // Setup
            selectwir = 0;
            selectwdr = 1;
            capturewdr = 0;
            shiftwdr = 0;
            updatewdr = 0;
            
            // Capture DR
            #10;
            capturewdr = 1;
            #10;
            capturewdr = 0;
            
            // Shift out DR value
            shiftwdr = 1;
            for (i = 0; i < 16; i = i + 1) begin
                #10;
                dr_value[i] = wso;
            end
            shiftwdr = 0;
            
            // Deselect DR
            #10;
            selectwdr = 0;
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize signals
        wrstn = 1;
        wrck = 0;
        wsi = 0;
        selectwir = 0;
        capturewir = 0;
        shiftwir = 0;
        updatewir = 0;
        selectwdr = 0;
        capturewdr = 0;
        shiftwdr = 0;
        updatewdr = 0;
        core_inputs = 8'h55;
        
        // Display test start
        $display("Starting IEEE 1500 Wrapper Test");
        
        // Reset the wrapper
        reset_wrapper();
        
        // Test 1: EXTEST Instruction
        $display("Test 1: EXTEST Instruction");
        test_ir = EXTEST;
        test_dr = 16'hA55A; // Input data on upper 8 bits, expected output on lower 8 bits
        
        // Load the instruction
        load_ir(test_ir);
        
        // Load the data register
        load_dr(test_dr);
        
        // Check outputs
        #20;
        $display("Core Outputs: %h (Expected: %h)", core_outputs, test_dr[7:0]);
        
        // Test 2: INTEST Instruction
        $display("Test 2: INTEST Instruction");
        test_ir = INTEST;
        test_dr = 16'h5AA5; // Test pattern
        
        // Load the instruction
        load_ir(test_ir);
        
        // Load the data register
        load_dr(test_dr);
        
        // Wait for internal test to complete
        #20;
        
        // Read back the data register
        read_dr(test_dr);
        $display("Read DR: %h", test_dr);
        
        // Test 3: BYPASS Instruction
        $display("Test 3: BYPASS Instruction");
        test_ir = BYPASS;
        
        // Load the instruction
        load_ir(test_ir);
        
        // Set WSI and observe WSO (should be delayed by 1 cycle)
        selectwdr = 1;
        shiftwdr = 1;
        
        wsi = 1'b1;
        #10;
        $display("BYPASS: WSI = 1, WSO = %b (Expected: 0)", wso);
        
        #10;
        $display("BYPASS: WSI = 1, WSO = %b (Expected: 1)", wso);
        
        wsi = 1'b0;
        #10;
        $display("BYPASS: WSI = 0, WSO = %b (Expected: 1)", wso);
        
        #10;
        $display("BYPASS: WSI = 0, WSO = %b (Expected: 0)", wso);
        
        shiftwdr = 0;
        selectwdr = 0;
        
        // Complete the test
        $display("IEEE 1500 Wrapper Test Complete");
        #100;
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time: %0t, wrck: %b, wsi: %b, wso: %b", $time, wrck, wsi, wso);
    end

endmodule