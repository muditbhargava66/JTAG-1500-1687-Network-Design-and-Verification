`timescale 1ns / 1ps

/**
 * Power Management Module for JTAG/1500/1687 Test Infrastructure
 * 
 * This module implements power management features including:
 * - Dynamic power gating for unused test components
 * - Clock gating for power optimization
 * - Power domain isolation
 * - Low-power test modes
 */
module power_manager #(
    parameter NUM_POWER_DOMAINS = 8,
    parameter POWER_ON_DELAY = 100,  // Clock cycles
    parameter POWER_OFF_DELAY = 50   // Clock cycles
) (
    // System interface
    input  wire                             clk,
    input  wire                             reset,
    input  wire                             system_enable,
    
    // Power control interface
    input  wire [NUM_POWER_DOMAINS-1:0]    domain_enable_req,
    input  wire [NUM_POWER_DOMAINS-1:0]    domain_disable_req,
    input  wire [2:0]                       power_mode,
    
    // Clock gating control
    input  wire                             jtag_active,
    input  wire                             ieee1500_active,
    input  wire                             ieee1687_active,
    input  wire                             boundary_scan_active,
    
    // Power domain outputs
    output reg  [NUM_POWER_DOMAINS-1:0]    domain_power_on,
    output reg  [NUM_POWER_DOMAINS-1:0]    domain_isolation,
    output reg  [NUM_POWER_DOMAINS-1:0]    domain_reset,
    
    // Clock outputs (gated)
    output wire                             jtag_clk,
    output wire                             ieee1500_clk,
    output wire                             ieee1687_clk,
    output wire                             boundary_scan_clk,
    
    // Power status
    output reg  [7:0]                       power_status,
    output reg  [15:0]                      power_consumption_estimate,
    output reg                              low_power_mode,
    output reg                              power_good
);

    // Power modes
    localparam POWER_MODE_NORMAL    = 3'b000;
    localparam POWER_MODE_LOW       = 3'b001;
    localparam POWER_MODE_STANDBY   = 3'b010;
    localparam POWER_MODE_SLEEP     = 3'b011;
    localparam POWER_MODE_SHUTDOWN  = 3'b100;

    // Power domain definitions
    localparam DOMAIN_JTAG          = 0;
    localparam DOMAIN_IEEE1500      = 1;
    localparam DOMAIN_IEEE1687      = 2;
    localparam DOMAIN_BOUNDARY_SCAN = 3;
    localparam DOMAIN_PATTERN_GEN   = 4;
    localparam DOMAIN_FAULT_SIM     = 5;
    localparam DOMAIN_COVERAGE      = 6;
    localparam DOMAIN_DEBUG         = 7;

    // Internal registers
    reg [NUM_POWER_DOMAINS-1:0]     domain_power_req;
    reg [NUM_POWER_DOMAINS-1:0]     domain_power_ack;
    reg [7:0]                       power_on_counter [NUM_POWER_DOMAINS-1:0];
    reg [7:0]                       power_off_counter [NUM_POWER_DOMAINS-1:0];
    reg [2:0]                       current_power_mode;
    reg [15:0]                      activity_counter;
    reg [3:0]                       idle_counter;
    
    // Clock gating enables
    reg                             jtag_clk_enable;
    reg                             ieee1500_clk_enable;
    reg                             ieee1687_clk_enable;
    reg                             boundary_scan_clk_enable;
    
    // Power state machine
    typedef enum logic [2:0] {
        PWR_INIT,
        PWR_NORMAL,
        PWR_LOW_POWER,
        PWR_STANDBY,
        PWR_SLEEP,
        PWR_SHUTDOWN
    } power_state_t;
    
    power_state_t power_state, next_power_state;

    // Main power management state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            power_state <= PWR_INIT;
            domain_power_on <= {NUM_POWER_DOMAINS{1'b0}};
            domain_isolation <= {NUM_POWER_DOMAINS{1'b1}};
            domain_reset <= {NUM_POWER_DOMAINS{1'b1}};
            current_power_mode <= POWER_MODE_NORMAL;
            power_status <= 8'h00;
            power_consumption_estimate <= 16'h0000;
            low_power_mode <= 1'b0;
            power_good <= 1'b0;
            activity_counter <= 16'h0000;
            idle_counter <= 4'h0;
            
            // Initialize clock enables
            jtag_clk_enable <= 1'b0;
            ieee1500_clk_enable <= 1'b0;
            ieee1687_clk_enable <= 1'b0;
            boundary_scan_clk_enable <= 1'b0;
            
            // Initialize counters
            for (integer i = 0; i < NUM_POWER_DOMAINS; i = i + 1) begin
                power_on_counter[i] <= 8'h00;
                power_off_counter[i] <= 8'h00;
            end
        end else begin
            power_state <= next_power_state;
            current_power_mode <= power_mode;
            
            // Update activity monitoring
            if (jtag_active || ieee1500_active || ieee1687_active || boundary_scan_active) begin
                activity_counter <= activity_counter + 1;
                idle_counter <= 4'h0;
            end else begin
                if (idle_counter < 4'hF) begin
                    idle_counter <= idle_counter + 1;
                end
            end
            
            case (power_state)
                PWR_INIT: begin
                    // Initialize power domains based on system requirements
                    if (system_enable) begin
                        domain_power_on[DOMAIN_JTAG] <= 1'b1;
                        domain_isolation[DOMAIN_JTAG] <= 1'b0;
                        domain_reset[DOMAIN_JTAG] <= 1'b0;
                        power_good <= 1'b1;
                        power_status <= 8'h01;  // Basic power on
                    end
                end
                
                PWR_NORMAL: begin
                    // Normal operation - manage individual domains
                    manage_power_domains();
                    update_clock_gating();
                    power_consumption_estimate <= calculate_power_consumption();
                    low_power_mode <= 1'b0;
                    power_status <= 8'hFF;  // All systems operational
                end
                
                PWR_LOW_POWER: begin
                    // Low power mode - disable unused domains
                    disable_unused_domains();
                    update_clock_gating();
                    power_consumption_estimate <= calculate_power_consumption() >> 1;
                    low_power_mode <= 1'b1;
                    power_status <= 8'h0F;  // Reduced functionality
                end
                
                PWR_STANDBY: begin
                    // Standby mode - keep only essential domains
                    keep_essential_domains();
                    disable_all_clocks();
                    power_consumption_estimate <= calculate_power_consumption() >> 2;
                    low_power_mode <= 1'b1;
                    power_status <= 8'h03;  // Minimal functionality
                end
                
                PWR_SLEEP: begin
                    // Sleep mode - power down most domains
                    power_down_non_essential();
                    disable_all_clocks();
                    power_consumption_estimate <= 16'h0010;  // Very low power
                    low_power_mode <= 1'b1;
                    power_status <= 8'h01;  // Wake-up capability only
                end
                
                PWR_SHUTDOWN: begin
                    // Shutdown mode - power down everything except wake-up logic
                    domain_power_on <= {NUM_POWER_DOMAINS{1'b0}};
                    domain_isolation <= {NUM_POWER_DOMAINS{1'b1}};
                    domain_reset <= {NUM_POWER_DOMAINS{1'b1}};
                    disable_all_clocks();
                    power_consumption_estimate <= 16'h0001;  // Minimal leakage
                    low_power_mode <= 1'b1;
                    power_good <= 1'b0;
                    power_status <= 8'h00;  // Shutdown
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        next_power_state = power_state;
        
        case (power_state)
            PWR_INIT: begin
                if (system_enable) begin
                    next_power_state = PWR_NORMAL;
                end
            end
            
            PWR_NORMAL: begin
                case (power_mode)
                    POWER_MODE_LOW: next_power_state = PWR_LOW_POWER;
                    POWER_MODE_STANDBY: next_power_state = PWR_STANDBY;
                    POWER_MODE_SLEEP: next_power_state = PWR_SLEEP;
                    POWER_MODE_SHUTDOWN: next_power_state = PWR_SHUTDOWN;
                    default: next_power_state = PWR_NORMAL;
                endcase
                
                // Auto transition to low power if idle
                if (idle_counter >= 4'hF) begin
                    next_power_state = PWR_LOW_POWER;
                end
            end
            
            PWR_LOW_POWER: begin
                case (power_mode)
                    POWER_MODE_NORMAL: next_power_state = PWR_NORMAL;
                    POWER_MODE_STANDBY: next_power_state = PWR_STANDBY;
                    POWER_MODE_SLEEP: next_power_state = PWR_SLEEP;
                    POWER_MODE_SHUTDOWN: next_power_state = PWR_SHUTDOWN;
                    default: next_power_state = PWR_LOW_POWER;
                endcase
                
                // Return to normal if activity detected
                if (jtag_active || ieee1500_active || ieee1687_active || boundary_scan_active) begin
                    next_power_state = PWR_NORMAL;
                end
            end
            
            PWR_STANDBY: begin
                case (power_mode)
                    POWER_MODE_NORMAL: next_power_state = PWR_NORMAL;
                    POWER_MODE_LOW: next_power_state = PWR_LOW_POWER;
                    POWER_MODE_SLEEP: next_power_state = PWR_SLEEP;
                    POWER_MODE_SHUTDOWN: next_power_state = PWR_SHUTDOWN;
                    default: next_power_state = PWR_STANDBY;
                endcase
                
                // Wake up on any activity
                if (system_enable && (jtag_active || ieee1500_active || ieee1687_active)) begin
                    next_power_state = PWR_NORMAL;
                end
            end
            
            PWR_SLEEP: begin
                case (power_mode)
                    POWER_MODE_NORMAL: next_power_state = PWR_NORMAL;
                    POWER_MODE_LOW: next_power_state = PWR_LOW_POWER;
                    POWER_MODE_STANDBY: next_power_state = PWR_STANDBY;
                    POWER_MODE_SHUTDOWN: next_power_state = PWR_SHUTDOWN;
                    default: next_power_state = PWR_SLEEP;
                endcase
                
                // Wake up only on explicit enable
                if (system_enable && power_mode == POWER_MODE_NORMAL) begin
                    next_power_state = PWR_NORMAL;
                end
            end
            
            PWR_SHUTDOWN: begin
                if (system_enable && power_mode == POWER_MODE_NORMAL) begin
                    next_power_state = PWR_INIT;
                end
            end
        endcase
    end

    // Task to manage individual power domains
    task manage_power_domains();
        integer i;
        begin
            for (i = 0; i < NUM_POWER_DOMAINS; i = i + 1) begin
                // Handle power-on requests
                if (domain_enable_req[i] && !domain_power_on[i]) begin
                    if (power_on_counter[i] < POWER_ON_DELAY) begin
                        power_on_counter[i] <= power_on_counter[i] + 1;
                    end else begin
                        domain_power_on[i] <= 1'b1;
                        domain_isolation[i] <= 1'b0;
                        domain_reset[i] <= 1'b0;
                        power_on_counter[i] <= 8'h00;
                    end
                end
                
                // Handle power-off requests
                if (domain_disable_req[i] && domain_power_on[i]) begin
                    if (power_off_counter[i] < POWER_OFF_DELAY) begin
                        domain_isolation[i] <= 1'b1;
                        domain_reset[i] <= 1'b1;
                        power_off_counter[i] <= power_off_counter[i] + 1;
                    end else begin
                        domain_power_on[i] <= 1'b0;
                        power_off_counter[i] <= 8'h00;
                    end
                end
            end
        end
    endtask

    // Task to update clock gating based on activity
    task update_clock_gating();
        begin
            jtag_clk_enable <= jtag_active && domain_power_on[DOMAIN_JTAG];
            ieee1500_clk_enable <= ieee1500_active && domain_power_on[DOMAIN_IEEE1500];
            ieee1687_clk_enable <= ieee1687_active && domain_power_on[DOMAIN_IEEE1687];
            boundary_scan_clk_enable <= boundary_scan_active && domain_power_on[DOMAIN_BOUNDARY_SCAN];
        end
    endtask

    // Task to disable unused domains in low power mode
    task disable_unused_domains();
        begin
            if (!jtag_active) begin
                domain_power_on[DOMAIN_JTAG] <= 1'b0;
                domain_isolation[DOMAIN_JTAG] <= 1'b1;
            end
            if (!ieee1500_active) begin
                domain_power_on[DOMAIN_IEEE1500] <= 1'b0;
                domain_isolation[DOMAIN_IEEE1500] <= 1'b1;
            end
            if (!ieee1687_active) begin
                domain_power_on[DOMAIN_IEEE1687] <= 1'b0;
                domain_isolation[DOMAIN_IEEE1687] <= 1'b1;
            end
            if (!boundary_scan_active) begin
                domain_power_on[DOMAIN_BOUNDARY_SCAN] <= 1'b0;
                domain_isolation[DOMAIN_BOUNDARY_SCAN] <= 1'b1;
            end
        end
    endtask

    // Task to keep only essential domains in standby
    task keep_essential_domains();
        begin
            // Keep only JTAG domain for wake-up capability
            domain_power_on <= {{(NUM_POWER_DOMAINS-1){1'b0}}, 1'b1};
            domain_isolation <= {{(NUM_POWER_DOMAINS-1){1'b1}}, 1'b0};
            domain_reset <= {{(NUM_POWER_DOMAINS-1){1'b1}}, 1'b0};
        end
    endtask

    // Task to power down non-essential domains
    task power_down_non_essential();
        begin
            domain_power_on <= {NUM_POWER_DOMAINS{1'b0}};
            domain_isolation <= {NUM_POWER_DOMAINS{1'b1}};
            domain_reset <= {NUM_POWER_DOMAINS{1'b1}};
        end
    endtask

    // Task to disable all clocks
    task disable_all_clocks();
        begin
            jtag_clk_enable <= 1'b0;
            ieee1500_clk_enable <= 1'b0;
            ieee1687_clk_enable <= 1'b0;
            boundary_scan_clk_enable <= 1'b0;
        end
    endtask

    // Function to calculate estimated power consumption
    function [15:0] calculate_power_consumption();
        reg [15:0] power_estimate;
        integer i;
        begin
            power_estimate = 16'h0000;
            
            // Base power consumption per active domain
            for (i = 0; i < NUM_POWER_DOMAINS; i = i + 1) begin
                if (domain_power_on[i]) begin
                    power_estimate = power_estimate + 16'h0010;  // 16 units per domain
                end
            end
            
            // Additional power for active clocks
            if (jtag_clk_enable) power_estimate = power_estimate + 16'h0008;
            if (ieee1500_clk_enable) power_estimate = power_estimate + 16'h0008;
            if (ieee1687_clk_enable) power_estimate = power_estimate + 16'h0008;
            if (boundary_scan_clk_enable) power_estimate = power_estimate + 16'h0008;
            
            // Activity-based power scaling
            if (activity_counter > 16'h1000) begin
                power_estimate = power_estimate + (power_estimate >> 2);  // +25% for high activity
            end
            
            calculate_power_consumption = power_estimate;
        end
    endfunction

    // Clock gating implementation
    assign jtag_clk = clk & jtag_clk_enable;
    assign ieee1500_clk = clk & ieee1500_clk_enable;
    assign ieee1687_clk = clk & ieee1687_clk_enable;
    assign boundary_scan_clk = clk & boundary_scan_clk_enable;

    // Power monitoring and reporting
    always @(posedge clk) begin
        if (power_consumption_estimate > 16'h0100) begin
            $display("Time: %0t - High power consumption detected: %0d units", 
                    $time, power_consumption_estimate);
        end
        
        if (low_power_mode) begin
            $display("Time: %0t - Operating in low power mode, consumption: %0d units", 
                    $time, power_consumption_estimate);
        end
    end

    // Assertions for power management verification
    property power_domain_isolation_check;
        @(posedge clk) (!domain_power_on) |-> domain_isolation;
    endproperty
    
    property clock_gating_check;
        @(posedge clk) (!jtag_active) |-> ##[1:10] (!jtag_clk_enable);
    endproperty
    
    property power_consumption_bounds_check;
        @(posedge clk) power_consumption_estimate <= 16'hFFFF;
    endproperty

    assert property(power_domain_isolation_check) 
        else $error("Power domain not properly isolated when powered down");
    assert property(clock_gating_check) 
        else $error("Clock not properly gated when inactive");
    assert property(power_consumption_bounds_check) 
        else $error("Power consumption estimate out of bounds");

endmodule