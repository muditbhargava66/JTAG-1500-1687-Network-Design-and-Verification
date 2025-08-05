`timescale 1ns / 1ps

/**
 * Fault Simulation and Diagnostics Module
 * 
 * This module implements fault injection and detection capabilities
 * for comprehensive testing of the JTAG/1500/1687 network.
 * Supports stuck-at faults, bridging faults, and timing faults.
 */
module fault_simulator #(
    parameter DATA_WIDTH = 32,
    parameter NUM_FAULT_SITES = 64,
    parameter FAULT_COVERAGE_THRESHOLD = 95
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     enable,
    
    // Fault injection control
    input  wire [7:0]               fault_type,
    input  wire [15:0]              fault_location,
    input  wire                     inject_fault,
    input  wire                     clear_faults,
    
    // DUT interface (pass-through with fault injection)
    input  wire                     dut_tck_in,
    input  wire                     dut_tms_in,
    input  wire                     dut_tdi_in,
    output wire                     dut_tck_out,
    output wire                     dut_tms_out,
    output wire                     dut_tdi_out,
    input  wire                     dut_tdo_in,
    output wire                     dut_tdo_out,
    
    // Fault status and diagnostics
    output reg [31:0]               faults_injected,
    output reg [31:0]               faults_detected,
    output reg [15:0]               fault_coverage,
    output reg                      fault_detected,
    output reg [15:0]               fault_location_detected,
    
    // Diagnostic interface
    output reg [DATA_WIDTH-1:0]     diagnostic_data,
    output reg                      diagnostic_valid,
    output reg [7:0]                fault_signature
);

    // Fault types
    localparam FAULT_STUCK_AT_0     = 8'h01;
    localparam FAULT_STUCK_AT_1     = 8'h02;
    localparam FAULT_BRIDGING       = 8'h03;
    localparam FAULT_DELAY          = 8'h04;
    localparam FAULT_INTERMITTENT   = 8'h05;
    localparam FAULT_OPEN_CIRCUIT   = 8'h06;
    localparam FAULT_SHORT_CIRCUIT  = 8'h07;
    localparam FAULT_TIMING_SKEW    = 8'h08;

    // Internal registers
    reg [NUM_FAULT_SITES-1:0]       active_faults;
    reg [7:0]                       fault_types [NUM_FAULT_SITES-1:0];
    reg [15:0]                      fault_locations [NUM_FAULT_SITES-1:0];
    reg [31:0]                      fault_counter;
    reg [31:0]                      detection_counter;
    
    // Fault injection registers
    reg                             tck_fault;
    reg                             tms_fault;
    reg                             tdi_fault;
    reg                             tdo_fault;
    
    // Timing fault simulation
    reg [3:0]                       delay_counter;
    reg                             delayed_tck;
    reg                             delayed_tms;
    reg                             delayed_tdi;
    
    // Signature analysis
    reg [31:0]                      signature_register;
    reg [31:0]                      expected_signature;
    reg [15:0]                      signature_counter;
    
    // Golden reference storage
    reg [DATA_WIDTH-1:0]            golden_response [1023:0];
    reg [DATA_WIDTH-1:0]            faulty_response [1023:0];
    reg [9:0]                       response_index;
    
    // Fault detection state machine
    typedef enum logic [2:0] {
        IDLE,
        INJECT_FAULT,
        MONITOR,
        ANALYZE,
        REPORT
    } fault_state_t;
    
    fault_state_t fault_state, next_fault_state;

    // Main fault simulation logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            fault_state <= IDLE;
            active_faults <= {NUM_FAULT_SITES{1'b0}};
            faults_injected <= 32'h00000000;
            faults_detected <= 32'h00000000;
            fault_coverage <= 16'h0000;
            fault_detected <= 1'b0;
            fault_location_detected <= 16'h0000;
            fault_counter <= 32'h00000000;
            detection_counter <= 32'h00000000;
            signature_register <= 32'h00000000;
            signature_counter <= 16'h0000;
            response_index <= 10'h000;
            diagnostic_valid <= 1'b0;
            fault_signature <= 8'h00;
            
            // Initialize fault arrays
            for (int i = 0; i < NUM_FAULT_SITES; i++) begin
                fault_types[i] <= 8'h00;
                fault_locations[i] <= 16'h0000;
            end
        end else begin
            fault_state <= next_fault_state;
            
            case (fault_state)
                IDLE: begin
                    if (clear_faults) begin
                        active_faults <= {NUM_FAULT_SITES{1'b0}};
                        faults_injected <= 32'h00000000;
                        fault_counter <= 32'h00000000;
                    end
                    diagnostic_valid <= 1'b0;
                end
                
                INJECT_FAULT: begin
                    if (inject_fault && fault_location < NUM_FAULT_SITES) begin
                        active_faults[fault_location] <= 1'b1;
                        fault_types[fault_location] <= fault_type;
                        fault_locations[fault_location] <= fault_location;
                        faults_injected <= faults_injected + 1;
                        fault_counter <= fault_counter + 1;
                    end
                end
                
                MONITOR: begin
                    // Monitor for fault effects
                    monitor_fault_effects();
                    
                    // Update signature analysis
                    signature_register <= {signature_register[30:0], dut_tdo_in};
                    signature_counter <= signature_counter + 1;
                    
                    // Store responses for comparison
                    if (response_index < 1024) begin
                        faulty_response[response_index] <= {dut_tdo_in, faulty_response[response_index][DATA_WIDTH-1:1]};
                    end
                end
                
                ANALYZE: begin
                    // Analyze fault effects and update coverage
                    analyze_fault_coverage();
                    
                    // Generate diagnostic data
                    diagnostic_data <= {faults_injected[15:0], faults_detected[15:0]};
                    diagnostic_valid <= 1'b1;
                    
                    // Calculate fault signature
                    fault_signature <= signature_register[7:0] ^ signature_register[15:8] ^ 
                                     signature_register[23:16] ^ signature_register[31:24];
                end
                
                REPORT: begin
                    // Generate fault report
                    fault_coverage <= (faults_detected * 100) / faults_injected;
                    diagnostic_valid <= 1'b1;
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        next_fault_state = fault_state;
        
        case (fault_state)
            IDLE: begin
                if (inject_fault) begin
                    next_fault_state = INJECT_FAULT;
                end else if (enable) begin
                    next_fault_state = MONITOR;
                end
            end
            
            INJECT_FAULT: begin
                next_fault_state = MONITOR;
            end
            
            MONITOR: begin
                if (!enable) begin
                    next_fault_state = ANALYZE;
                end
            end
            
            ANALYZE: begin
                next_fault_state = REPORT;
            end
            
            REPORT: begin
                if (clear_faults) begin
                    next_fault_state = IDLE;
                end
            end
        endcase
    end

    // Fault injection logic
    always_comb begin
        // Default pass-through
        tck_fault = 1'b0;
        tms_fault = 1'b0;
        tdi_fault = 1'b0;
        tdo_fault = 1'b0;
        
        // Apply faults based on active fault sites
        for (int i = 0; i < NUM_FAULT_SITES; i++) begin
            if (active_faults[i]) begin
                case (fault_types[i])
                    FAULT_STUCK_AT_0: begin
                        case (fault_locations[i] % 4)
                            0: tck_fault = 1'b1;  // Force TCK to 0
                            1: tms_fault = 1'b1;  // Force TMS to 0
                            2: tdi_fault = 1'b1;  // Force TDI to 0
                            3: tdo_fault = 1'b1;  // Force TDO to 0
                        endcase
                    end
                    
                    FAULT_STUCK_AT_1: begin
                        case (fault_locations[i] % 4)
                            0: tck_fault = 1'b1;  // Force TCK to 1
                            1: tms_fault = 1'b1;  // Force TMS to 1
                            2: tdi_fault = 1'b1;  // Force TDI to 1
                            3: tdo_fault = 1'b1;  // Force TDO to 1
                        endcase
                    end
                    
                    FAULT_OPEN_CIRCUIT: begin
                        // Simulate open circuit by forcing to Z (high impedance)
                        case (fault_locations[i] % 4)
                            0: tck_fault = 1'b1;
                            1: tms_fault = 1'b1;
                            2: tdi_fault = 1'b1;
                            3: tdo_fault = 1'b1;
                        endcase
                    end
                endcase
            end
        end
    end

    // Output assignment with fault injection
    assign dut_tck_out = tck_fault ? (fault_type == FAULT_STUCK_AT_0 ? 1'b0 : 
                                     fault_type == FAULT_STUCK_AT_1 ? 1'b1 : 1'bz) : 
                                     (fault_type == FAULT_DELAY ? delayed_tck : dut_tck_in);
    
    assign dut_tms_out = tms_fault ? (fault_type == FAULT_STUCK_AT_0 ? 1'b0 : 
                                     fault_type == FAULT_STUCK_AT_1 ? 1'b1 : 1'bz) : 
                                     (fault_type == FAULT_DELAY ? delayed_tms : dut_tms_in);
    
    assign dut_tdi_out = tdi_fault ? (fault_type == FAULT_STUCK_AT_0 ? 1'b0 : 
                                     fault_type == FAULT_STUCK_AT_1 ? 1'b1 : 1'bz) : 
                                     (fault_type == FAULT_DELAY ? delayed_tdi : dut_tdi_in);
    
    assign dut_tdo_out = tdo_fault ? (fault_type == FAULT_STUCK_AT_0 ? 1'b0 : 
                                     fault_type == FAULT_STUCK_AT_1 ? 1'b1 : 1'bz) : dut_tdo_in;

    // Delay fault simulation
    always_ff @(posedge clk) begin
        if (reset) begin
            delay_counter <= 4'h0;
            delayed_tck <= 1'b0;
            delayed_tms <= 1'b0;
            delayed_tdi <= 1'b0;
        end else begin
            delay_counter <= delay_counter + 1;
            
            // Introduce delays for timing fault simulation
            if (delay_counter >= 2) begin
                delayed_tck <= dut_tck_in;
                delayed_tms <= dut_tms_in;
                delayed_tdi <= dut_tdi_in;
                delay_counter <= 4'h0;
            end
        end
    end

    // Task to monitor fault effects
    task monitor_fault_effects();
        // Compare current response with expected golden response
        if (response_index < 1024) begin
            if (faulty_response[response_index] != golden_response[response_index]) begin
                fault_detected <= 1'b1;
                fault_location_detected <= response_index;
                detection_counter <= detection_counter + 1;
                faults_detected <= faults_detected + 1;
            end
            response_index <= response_index + 1;
        end
    endtask

    // Task to analyze fault coverage
    task analyze_fault_coverage();
        // Calculate fault coverage percentage
        if (faults_injected > 0) begin
            fault_coverage <= (faults_detected * 100) / faults_injected;
        end else begin
            fault_coverage <= 16'h0000;
        end
        
        // Check if coverage threshold is met
        if (fault_coverage >= FAULT_COVERAGE_THRESHOLD) begin
            diagnostic_data[31] <= 1'b1;  // Coverage threshold met flag
        end
    endtask

    // Coverage collection for fault simulation
    covergroup fault_coverage_cg @(posedge clk);
        fault_type_cp: coverpoint fault_type {
            bins stuck_at_0 = {FAULT_STUCK_AT_0};
            bins stuck_at_1 = {FAULT_STUCK_AT_1};
            bins bridging = {FAULT_BRIDGING};
            bins delay = {FAULT_DELAY};
            bins intermittent = {FAULT_INTERMITTENT};
            bins open_circuit = {FAULT_OPEN_CIRCUIT};
            bins short_circuit = {FAULT_SHORT_CIRCUIT};
            bins timing_skew = {FAULT_TIMING_SKEW};
        }
        
        fault_location_cp: coverpoint fault_location {
            bins low_locations = {[0:15]};
            bins mid_locations = {[16:47]};
            bins high_locations = {[48:63]};
        }
        
        fault_detection_cp: coverpoint fault_detected {
            bins not_detected = {0};
            bins detected = {1};
        }
        
        coverage_level_cp: coverpoint fault_coverage {
            bins low_coverage = {[0:49]};
            bins medium_coverage = {[50:79]};
            bins high_coverage = {[80:94]};
            bins excellent_coverage = {[95:100]};
        }
    endgroup

    fault_coverage_cg fault_cov = new();

    // Assertions for fault simulation verification
    property fault_injection_check;
        @(posedge clk) (inject_fault && fault_location < NUM_FAULT_SITES) |-> 
                       ##1 active_faults[fault_location];
    endproperty
    
    property fault_detection_check;
        @(posedge clk) (fault_detected) |-> (faults_detected > 0);
    endproperty
    
    property coverage_calculation_check;
        @(posedge clk) (faults_injected > 0) |-> (fault_coverage <= 100);
    endproperty

    assert property(fault_injection_check) else $error("Fault injection failed");
    assert property(fault_detection_check) else $error("Fault detection inconsistent");
    assert property(coverage_calculation_check) else $error("Coverage calculation error");

    // Debug and monitoring
    always @(posedge clk) begin
        if (fault_detected) begin
            $display("Time: %0t - Fault detected at location %0d, signature: %02h", 
                    $time, fault_location_detected, fault_signature);
        end
        
        if (diagnostic_valid) begin
            $display("Time: %0t - Fault coverage: %0d%%, Faults injected: %0d, Detected: %0d", 
                    $time, fault_coverage, faults_injected, faults_detected);
        end
    end

endmodule