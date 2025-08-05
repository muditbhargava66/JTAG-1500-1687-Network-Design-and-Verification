`timescale 1ns / 1ps

/**
 * Optimized Scan Chain Implementation
 * 
 * This module implements an optimized scan chain with features for faster testing:
 * - Parallel scan paths for reduced test time
 * - Configurable scan chain length
 * - Built-in compression/decompression
 * - Power-optimized scanning modes
 */
module optimized_scan_chain #(
    parameter CHAIN_LENGTH = 64,
    parameter NUM_PARALLEL_CHAINS = 4,
    parameter COMPRESSION_RATIO = 4,
    parameter ENABLE_POWER_OPT = 1
) (
    // System interface
    input  wire                             clk,
    input  wire                             reset,
    input  wire                             scan_enable,
    
    // Scan control
    input  wire [1:0]                       scan_mode,
    input  wire                             scan_in,
    output wire                             scan_out,
    input  wire                             scan_clock,
    
    // Parallel scan inputs/outputs
    input  wire [NUM_PARALLEL_CHAINS-1:0]  parallel_scan_in,
    output wire [NUM_PARALLEL_CHAINS-1:0]  parallel_scan_out,
    
    // Functional data interface
    input  wire [CHAIN_LENGTH-1:0]         functional_data_in,
    output wire [CHAIN_LENGTH-1:0]         functional_data_out,
    input  wire                             capture_enable,
    
    // Compression interface
    input  wire                             compression_enable,
    input  wire [7:0]                       compression_seed,
    output wire [15:0]                      compression_signature,
    
    // Power management
    input  wire                             low_power_mode,
    output wire [7:0]                       power_status,
    
    // Status and control
    output wire [15:0]                      scan_length,
    output wire                             scan_complete,
    output wire [31:0]                      scan_cycles
);

    // Scan modes
    localparam SCAN_MODE_NORMAL     = 2'b00;
    localparam SCAN_MODE_PARALLEL   = 2'b01;
    localparam SCAN_MODE_COMPRESSED = 2'b10;
    localparam SCAN_MODE_POWER_OPT  = 2'b11;

    // Internal registers
    reg [CHAIN_LENGTH-1:0]          scan_chain_reg;
    reg [CHAIN_LENGTH-1:0]          shadow_reg;
    reg [NUM_PARALLEL_CHAINS-1:0]  parallel_chains [CHAIN_LENGTH/NUM_PARALLEL_CHAINS-1:0];
    reg [31:0]                      cycle_counter;
    reg [15:0]                      current_scan_length;
    reg                             scan_active;
    reg [7:0]                       power_control;
    
    // Compression logic
    reg [31:0]                      lfsr_compressor;
    reg [31:0]                      misr_signature;
    reg [15:0]                      compressed_data;
    
    // Power optimization
    reg [3:0]                       power_gate_control;
    reg [7:0]                       clock_gate_control;
    
    // Scan chain implementation
    always_ff @(posedge scan_clock or posedge reset) begin
        if (reset) begin
            scan_chain_reg <= {CHAIN_LENGTH{1'b0}};
            shadow_reg <= {CHAIN_LENGTH{1'b0}};
            cycle_counter <= 32'h00000000;
            current_scan_length <= CHAIN_LENGTH;
            scan_active <= 1'b0;
            power_control <= 8'hFF;
            lfsr_compressor <= 32'h12345678;
            misr_signature <= 32'h00000000;
            compressed_data <= 16'h0000;
            power_gate_control <= 4'h0;
            clock_gate_control <= 8'h00;
            
            // Initialize parallel chains
            for (integer i = 0; i < CHAIN_LENGTH/NUM_PARALLEL_CHAINS; i = i + 1) begin
                parallel_chains[i] <= {NUM_PARALLEL_CHAINS{1'b0}};
            end
        end else if (scan_enable) begin
            scan_active <= 1'b1;
            cycle_counter <= cycle_counter + 1;
            
            case (scan_mode)
                SCAN_MODE_NORMAL: begin
                    // Standard serial scan
                    scan_chain_reg <= {scan_chain_reg[CHAIN_LENGTH-2:0], scan_in};
                    current_scan_length <= CHAIN_LENGTH;
                    power_control <= 8'hFF;
                end
                
                SCAN_MODE_PARALLEL: begin
                    // Parallel scan for faster testing
                    execute_parallel_scan();
                    current_scan_length <= CHAIN_LENGTH / NUM_PARALLEL_CHAINS;
                    power_control <= 8'hFF;
                end
                
                SCAN_MODE_COMPRESSED: begin
                    // Compressed scan using LFSR/MISR
                    execute_compressed_scan();
                    current_scan_length <= CHAIN_LENGTH / COMPRESSION_RATIO;
                    power_control <= 8'hC0;
                end
                
                SCAN_MODE_POWER_OPT: begin
                    // Power-optimized scan
                    execute_power_optimized_scan();
                    current_scan_length <= CHAIN_LENGTH;
                    power_control <= 8'h3F;
                end
            endcase
            
            // Capture functional data when enabled
            if (capture_enable) begin
                shadow_reg <= functional_data_in;
            end
        end else begin
            scan_active <= 1'b0;
        end
    end

    // Task to execute parallel scan
    task execute_parallel_scan();
        integer i, j;
        begin
            // Shift all parallel chains simultaneously
            for (i = 0; i < CHAIN_LENGTH/NUM_PARALLEL_CHAINS; i = i + 1) begin
                if (i == 0) begin
                    // First stage gets input from parallel_scan_in
                    parallel_chains[i] <= {parallel_chains[i][NUM_PARALLEL_CHAINS-2:0], parallel_scan_in};
                end else begin
                    // Subsequent stages get input from previous stage
                    parallel_chains[i] <= {parallel_chains[i][NUM_PARALLEL_CHAINS-2:0], parallel_chains[i-1][NUM_PARALLEL_CHAINS-1]};
                end
            end
            
            // Update main scan chain from parallel chains
            for (i = 0; i < CHAIN_LENGTH/NUM_PARALLEL_CHAINS; i = i + 1) begin
                for (j = 0; j < NUM_PARALLEL_CHAINS; j = j + 1) begin
                    scan_chain_reg[i*NUM_PARALLEL_CHAINS + j] <= parallel_chains[i][j];
                end
            end
        end
    endtask

    // Task to execute compressed scan
    task execute_compressed_scan();
        begin
            // LFSR-based pattern generation for input compression
            lfsr_compressor <= {lfsr_compressor[30:0], 
                               lfsr_compressor[31] ^ lfsr_compressor[21] ^ 
                               lfsr_compressor[1] ^ lfsr_compressor[0]};
            
            // Use LFSR output to generate scan patterns
            scan_chain_reg <= {scan_chain_reg[CHAIN_LENGTH-2:0], lfsr_compressor[0]};
            
            // MISR for output compression
            misr_signature <= {misr_signature[30:0], 
                              misr_signature[31] ^ misr_signature[27] ^ 
                              misr_signature[2] ^ misr_signature[1] ^ scan_chain_reg[CHAIN_LENGTH-1]};
            
            // Generate compressed signature
            compressed_data <= misr_signature[15:0] ^ misr_signature[31:16];
        end
    endtask

    // Task to execute power-optimized scan
    task execute_power_optimized_scan();
        begin
            // Implement clock gating for unused portions
            if (low_power_mode) begin
                // Gate clocks for inactive scan segments
                clock_gate_control <= 8'h0F;  // Gate half the chain
                
                // Power gate unused logic
                power_gate_control <= 4'h3;   // Gate 2 out of 4 power domains
                
                // Reduced frequency scanning
                if (cycle_counter % 4 == 0) begin
                    scan_chain_reg <= {scan_chain_reg[CHAIN_LENGTH-2:0], scan_in};
                end
            end else begin
                // Normal power mode
                clock_gate_control <= 8'h00;
                power_gate_control <= 4'h0;
                scan_chain_reg <= {scan_chain_reg[CHAIN_LENGTH-2:0], scan_in};
            end
        end
    endtask

    // Output assignments
    assign scan_out = scan_chain_reg[CHAIN_LENGTH-1];
    assign parallel_scan_out = (scan_mode == SCAN_MODE_PARALLEL) ? 
                              parallel_chains[CHAIN_LENGTH/NUM_PARALLEL_CHAINS-1] : 
                              {NUM_PARALLEL_CHAINS{1'b0}};
    
    assign functional_data_out = scan_enable ? scan_chain_reg : shadow_reg;
    assign compression_signature = (scan_mode == SCAN_MODE_COMPRESSED) ? 
                                  compressed_data : 16'h0000;
    
    assign scan_length = current_scan_length;
    assign scan_complete = scan_active && (cycle_counter >= current_scan_length);
    assign scan_cycles = cycle_counter;
    assign power_status = power_control;

    // Performance monitoring
    reg [31:0] total_scan_time;
    reg [15:0] throughput_mbps;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            total_scan_time <= 32'h00000000;
            throughput_mbps <= 16'h0000;
        end else if (scan_complete) begin
            total_scan_time <= cycle_counter;
            
            // Calculate throughput in Mbps (simplified)
            if (cycle_counter > 0) begin
                throughput_mbps <= (CHAIN_LENGTH * 100) / cycle_counter;  // Approximate
            end
        end
    end

    // Built-in self-test (BIST) capability
    reg [7:0] bist_pattern;
    reg       bist_enable;
    reg       bist_pass;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            bist_pattern <= 8'h55;  // Alternating pattern
            bist_enable <= 1'b0;
            bist_pass <= 1'b0;
        end else if (scan_enable && scan_mode == SCAN_MODE_NORMAL) begin
            // Simple BIST: inject known pattern and verify
            if (cycle_counter == 1) begin
                bist_enable <= 1'b1;
                // Inject test pattern
                scan_chain_reg[7:0] <= bist_pattern;
            end else if (cycle_counter == CHAIN_LENGTH + 8) begin
                // Check if pattern propagated correctly
                bist_pass <= (scan_chain_reg[CHAIN_LENGTH-1:CHAIN_LENGTH-8] == bist_pattern);
                bist_enable <= 1'b0;
            end
        end
    end

    // Assertions for verification
    property scan_chain_length_check;
        @(posedge scan_clock) scan_enable |-> (current_scan_length <= CHAIN_LENGTH);
    endproperty
    
    property parallel_scan_consistency;
        @(posedge scan_clock) (scan_mode == SCAN_MODE_PARALLEL) |-> 
                             (current_scan_length == CHAIN_LENGTH / NUM_PARALLEL_CHAINS);
    endproperty
    
    property power_optimization_check;
        @(posedge scan_clock) low_power_mode |-> (power_control < 8'h80);
    endproperty

    assert property(scan_chain_length_check) 
        else $error("Scan chain length exceeds maximum");
    assert property(parallel_scan_consistency) 
        else $error("Parallel scan length calculation error");
    assert property(power_optimization_check) 
        else $error("Power optimization not active in low power mode");

    // Coverage collection
    covergroup scan_modes_cg @(posedge scan_clock);
        scan_mode_cp: coverpoint scan_mode {
            bins normal = {SCAN_MODE_NORMAL};
            bins parallel = {SCAN_MODE_PARALLEL};
            bins compressed = {SCAN_MODE_COMPRESSED};
            bins power_opt = {SCAN_MODE_POWER_OPT};
        }
        
        chain_length_cp: coverpoint current_scan_length {
            bins short_chain = {[1:16]};
            bins medium_chain = {[17:32]};
            bins long_chain = {[33:64]};
        }
        
        power_mode_cp: coverpoint low_power_mode {
            bins normal_power = {0};
            bins low_power = {1};
        }
    endgroup

    scan_modes_cg scan_cov = new();

    // Debug and monitoring
    always @(posedge scan_clock) begin
        if (scan_enable && (cycle_counter % 100 == 0)) begin
            $display("Time: %0t - Scan progress: %0d/%0d cycles, Mode: %0d, Power: %02h", 
                    $time, cycle_counter, current_scan_length, scan_mode, power_control);
        end
        
        if (scan_complete) begin
            $display("Time: %0t - Scan completed: %0d cycles, Throughput: %0d Mbps", 
                    $time, total_scan_time, throughput_mbps);
        end
        
        if (bist_enable && !bist_pass && cycle_counter > CHAIN_LENGTH + 8) begin
            $display("Time: %0t - BIST failure detected in scan chain", $time);
        end
    end

endmodule