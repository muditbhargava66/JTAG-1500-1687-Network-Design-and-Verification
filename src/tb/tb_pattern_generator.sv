`timescale 1ns / 1ps

/**
 * Advanced Pattern Generator for JTAG Test Vectors
 * 
 * This module generates sophisticated test patterns for comprehensive
 * JTAG testing including boundary scan, instruction sequences, and
 * data patterns with configurable parameters.
 */
module pattern_generator #(
    parameter DATA_WIDTH = 32,
    parameter INSTRUCTION_WIDTH = 4,
    parameter MAX_CHAIN_LENGTH = 256
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     enable,
    
    // Configuration interface
    input  wire [7:0]               pattern_type,
    input  wire [15:0]              pattern_length,
    input  wire [31:0]              seed_value,
    
    // JTAG interface
    output reg                      tck,
    output reg                      tms,
    output reg                      tdi,
    input  wire                     tdo,
    
    // Control and status
    output reg                      pattern_complete,
    output reg [31:0]               cycle_count,
    output reg [15:0]               error_count,
    
    // Debug interface
    output reg [DATA_WIDTH-1:0]     expected_data,
    output reg [DATA_WIDTH-1:0]     received_data,
    output reg                      data_mismatch
);

    // Pattern types
    localparam PATTERN_WALKING_ONES    = 8'h01;
    localparam PATTERN_WALKING_ZEROS   = 8'h02;
    localparam PATTERN_ALTERNATING     = 8'h03;
    localparam PATTERN_RANDOM          = 8'h04;
    localparam PATTERN_LFSR            = 8'h05;
    localparam PATTERN_CUSTOM          = 8'h06;
    localparam PATTERN_BOUNDARY_SCAN   = 8'h10;
    localparam PATTERN_INSTRUCTION_SEQ = 8'h20;
    localparam PATTERN_STRESS_TEST     = 8'h30;

    // JTAG states
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

    // Internal registers
    reg [3:0]                   current_state;
    reg [3:0]                   next_state;
    reg [31:0]                  lfsr_reg;
    reg [15:0]                  bit_counter;
    reg [15:0]                  pattern_counter;
    reg [DATA_WIDTH-1:0]        shift_register;
    reg [DATA_WIDTH-1:0]        pattern_data;
    reg [INSTRUCTION_WIDTH-1:0] current_instruction;
    reg                         tck_enable;
    reg [7:0]                   tck_divider;
    
    // Pattern generation state machine
    typedef enum logic [3:0] {
        IDLE,
        INIT_PATTERN,
        GENERATE_RESET,
        LOAD_INSTRUCTION,
        SHIFT_INSTRUCTION,
        UPDATE_INSTRUCTION,
        LOAD_DATA,
        SHIFT_DATA,
        UPDATE_DATA,
        VERIFY_DATA,
        COMPLETE
    } pattern_state_t;
    
    pattern_state_t pattern_state, next_pattern_state;

    // TCK generation
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            tck <= 1'b0;
            tck_divider <= 8'h00;
        end else if (tck_enable) begin
            tck_divider <= tck_divider + 1;
            if (tck_divider == 8'h03) begin  // Divide by 4 for slower TCK
                tck <= ~tck;
                tck_divider <= 8'h00;
            end
        end
    end

    // Pattern generation state machine
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pattern_state <= IDLE;
            current_state <= TEST_LOGIC_RESET;
            cycle_count <= 32'h00000000;
            error_count <= 16'h0000;
            pattern_complete <= 1'b0;
            tck_enable <= 1'b0;
            tms <= 1'b1;
            tdi <= 1'b0;
            bit_counter <= 16'h0000;
            pattern_counter <= 16'h0000;
            lfsr_reg <= 32'h12345678;  // Default seed
            data_mismatch <= 1'b0;
        end else begin
            pattern_state <= next_pattern_state;
            
            if (enable && !pattern_complete) begin
                cycle_count <= cycle_count + 1;
                tck_enable <= 1'b1;
                
                case (pattern_state)
                    IDLE: begin
                        if (enable) begin
                            pattern_complete <= 1'b0;
                            error_count <= 16'h0000;
                            cycle_count <= 32'h00000000;
                            if (seed_value != 32'h00000000) begin
                                lfsr_reg <= seed_value;
                            end
                        end
                    end
                    
                    INIT_PATTERN: begin
                        generate_pattern_data();
                        bit_counter <= 16'h0000;
                    end
                    
                    GENERATE_RESET: begin
                        tms <= 1'b1;
                        current_state <= TEST_LOGIC_RESET;
                        if (bit_counter >= 5) begin
                            bit_counter <= 16'h0000;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                    
                    LOAD_INSTRUCTION: begin
                        navigate_to_shift_ir();
                    end
                    
                    SHIFT_INSTRUCTION: begin
                        if (bit_counter < INSTRUCTION_WIDTH) begin
                            tdi <= current_instruction[bit_counter];
                            tms <= 1'b0;  // Stay in Shift-IR
                            bit_counter <= bit_counter + 1;
                        end else begin
                            tms <= 1'b1;  // Exit to Exit1-IR
                            bit_counter <= 16'h0000;
                        end
                    end
                    
                    UPDATE_INSTRUCTION: begin
                        tms <= 1'b1;  // Go to Update-IR
                        current_state <= UPDATE_IR;
                    end
                    
                    LOAD_DATA: begin
                        navigate_to_shift_dr();
                    end
                    
                    SHIFT_DATA: begin
                        if (bit_counter < pattern_length) begin
                            tdi <= pattern_data[bit_counter % DATA_WIDTH];
                            tms <= 1'b0;  // Stay in Shift-DR
                            
                            // Capture TDO for verification
                            shift_register <= {tdo, shift_register[DATA_WIDTH-1:1]};
                            bit_counter <= bit_counter + 1;
                        end else begin
                            tms <= 1'b1;  // Exit to Exit1-DR
                            bit_counter <= 16'h0000;
                        end
                    end
                    
                    UPDATE_DATA: begin
                        tms <= 1'b1;  // Go to Update-DR
                        current_state <= UPDATE_DR;
                    end
                    
                    VERIFY_DATA: begin
                        received_data <= shift_register;
                        expected_data <= pattern_data;
                        
                        if (shift_register != pattern_data) begin
                            data_mismatch <= 1'b1;
                            error_count <= error_count + 1;
                        end else begin
                            data_mismatch <= 1'b0;
                        end
                        
                        pattern_counter <= pattern_counter + 1;
                        
                        if (pattern_counter >= (pattern_length / DATA_WIDTH)) begin
                            pattern_complete <= 1'b1;
                            tck_enable <= 1'b0;
                        end
                    end
                    
                    COMPLETE: begin
                        pattern_complete <= 1'b1;
                        tck_enable <= 1'b0;
                    end
                endcase
            end else begin
                tck_enable <= 1'b0;
            end
        end
    end

    // Next state logic for pattern generation
    always_comb begin
        next_pattern_state = pattern_state;
        
        case (pattern_state)
            IDLE: begin
                if (enable) begin
                    next_pattern_state = INIT_PATTERN;
                end
            end
            
            INIT_PATTERN: begin
                next_pattern_state = GENERATE_RESET;
            end
            
            GENERATE_RESET: begin
                if (bit_counter >= 5) begin
                    if (pattern_type == PATTERN_INSTRUCTION_SEQ) begin
                        next_pattern_state = LOAD_INSTRUCTION;
                    end else begin
                        next_pattern_state = LOAD_DATA;
                    end
                end
            end
            
            LOAD_INSTRUCTION: begin
                if (current_state == SHIFT_IR) begin
                    next_pattern_state = SHIFT_INSTRUCTION;
                end
            end
            
            SHIFT_INSTRUCTION: begin
                if (bit_counter >= INSTRUCTION_WIDTH) begin
                    next_pattern_state = UPDATE_INSTRUCTION;
                end
            end
            
            UPDATE_INSTRUCTION: begin
                next_pattern_state = LOAD_DATA;
            end
            
            LOAD_DATA: begin
                if (current_state == SHIFT_DR) begin
                    next_pattern_state = SHIFT_DATA;
                end
            end
            
            SHIFT_DATA: begin
                if (bit_counter >= pattern_length) begin
                    next_pattern_state = UPDATE_DATA;
                end
            end
            
            UPDATE_DATA: begin
                next_pattern_state = VERIFY_DATA;
            end
            
            VERIFY_DATA: begin
                if (pattern_counter >= (pattern_length / DATA_WIDTH)) begin
                    next_pattern_state = COMPLETE;
                end else begin
                    next_pattern_state = INIT_PATTERN;
                end
            end
            
            COMPLETE: begin
                if (!enable) begin
                    next_pattern_state = IDLE;
                end
            end
        endcase
    end

    // Task to generate pattern data based on type
    task generate_pattern_data();
        case (pattern_type)
            PATTERN_WALKING_ONES: begin
                pattern_data = 32'h00000001 << (pattern_counter % 32);
            end
            
            PATTERN_WALKING_ZEROS: begin
                pattern_data = ~(32'h00000001 << (pattern_counter % 32));
            end
            
            PATTERN_ALTERNATING: begin
                pattern_data = (pattern_counter % 2) ? 32'hAAAAAAAA : 32'h55555555;
            end
            
            PATTERN_RANDOM: begin
                // Simple LFSR for pseudo-random patterns
                lfsr_reg = {lfsr_reg[30:0], lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0]};
                pattern_data = lfsr_reg;
            end
            
            PATTERN_LFSR: begin
                // More complex LFSR with multiple taps
                lfsr_reg = {lfsr_reg[30:0], lfsr_reg[31] ^ lfsr_reg[30] ^ lfsr_reg[26] ^ lfsr_reg[25]};
                pattern_data = lfsr_reg;
            end
            
            PATTERN_BOUNDARY_SCAN: begin
                // Specific patterns for boundary scan testing
                case (pattern_counter % 4)
                    0: pattern_data = 32'h00000000;  // All zeros
                    1: pattern_data = 32'hFFFFFFFF;  // All ones
                    2: pattern_data = 32'hA5A5A5A5;  // Alternating pattern
                    3: pattern_data = 32'h5A5A5A5A;  // Inverted alternating
                endcase
            end
            
            PATTERN_STRESS_TEST: begin
                // High-frequency switching patterns
                pattern_data = (pattern_counter % 8 < 4) ? 32'hFFFFFFFF : 32'h00000000;
            end
            
            default: begin
                pattern_data = 32'h12345678;  // Default pattern
            end
        endcase
        
        // Set instruction based on pattern type
        case (pattern_type)
            PATTERN_BOUNDARY_SCAN: current_instruction = 4'b0000;  // EXTEST
            PATTERN_INSTRUCTION_SEQ: current_instruction = 4'b0001; // IDCODE
            default: current_instruction = 4'b1111;  // BYPASS
        endcase
    endtask

    // Task to navigate to Shift-IR state
    task navigate_to_shift_ir();
        case (current_state)
            TEST_LOGIC_RESET: begin
                tms = 1'b0;
                current_state = RUN_TEST_IDLE;
            end
            RUN_TEST_IDLE: begin
                tms = 1'b1;
                current_state = SELECT_DR_SCAN;
            end
            SELECT_DR_SCAN: begin
                tms = 1'b1;
                current_state = SELECT_IR_SCAN;
            end
            SELECT_IR_SCAN: begin
                tms = 1'b0;
                current_state = CAPTURE_IR;
            end
            CAPTURE_IR: begin
                tms = 1'b0;
                current_state = SHIFT_IR;
            end
            default: begin
                tms = 1'b1;  // Force reset
                current_state = TEST_LOGIC_RESET;
            end
        endcase
    endtask

    // Task to navigate to Shift-DR state
    task navigate_to_shift_dr();
        case (current_state)
            TEST_LOGIC_RESET: begin
                tms = 1'b0;
                current_state = RUN_TEST_IDLE;
            end
            RUN_TEST_IDLE: begin
                tms = 1'b1;
                current_state = SELECT_DR_SCAN;
            end
            UPDATE_IR: begin
                tms = 1'b0;
                current_state = RUN_TEST_IDLE;
            end
            SELECT_DR_SCAN: begin
                tms = 1'b0;
                current_state = CAPTURE_DR;
            end
            CAPTURE_DR: begin
                tms = 1'b0;
                current_state = SHIFT_DR;
            end
            default: begin
                tms = 1'b1;  // Force reset
                current_state = TEST_LOGIC_RESET;
            end
        endcase
    endtask

    // Coverage collection for pattern generator
    covergroup pattern_coverage @(posedge clk);
        pattern_type_cp: coverpoint pattern_type {
            bins walking_ones = {PATTERN_WALKING_ONES};
            bins walking_zeros = {PATTERN_WALKING_ZEROS};
            bins alternating = {PATTERN_ALTERNATING};
            bins random = {PATTERN_RANDOM};
            bins lfsr = {PATTERN_LFSR};
            bins boundary_scan = {PATTERN_BOUNDARY_SCAN};
            bins instruction_seq = {PATTERN_INSTRUCTION_SEQ};
            bins stress_test = {PATTERN_STRESS_TEST};
        }
        
        pattern_length_cp: coverpoint pattern_length {
            bins short_patterns = {[1:32]};
            bins medium_patterns = {[33:128]};
            bins long_patterns = {[129:256]};
        }
        
        state_coverage_cp: coverpoint current_state {
            bins all_states[] = {[0:15]};
        }
        
        error_coverage_cp: coverpoint error_count {
            bins no_errors = {0};
            bins few_errors = {[1:5]};
            bins many_errors = {[6:$]};
        }
    endgroup

    pattern_coverage pattern_cov = new();

    // Assertions for verification
    property pattern_completion_check;
        @(posedge clk) (enable && pattern_state == COMPLETE) |-> pattern_complete;
    endproperty
    
    property tck_generation_check;
        @(posedge clk) tck_enable |-> ##[1:10] (tck != $past(tck));
    endproperty
    
    property state_transition_check;
        @(posedge clk) (current_state inside {[0:15]});
    endproperty

    assert property(pattern_completion_check) else $error("Pattern completion flag not set correctly");
    assert property(tck_generation_check) else $error("TCK not toggling when enabled");
    assert property(state_transition_check) else $error("Invalid JTAG state detected");

endmodule