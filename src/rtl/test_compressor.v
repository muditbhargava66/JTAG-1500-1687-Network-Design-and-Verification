`timescale 1ns / 1ps

/**
 * Test Compression Module
 * 
 * Implements various test compression techniques to reduce test data volume
 * and test application time while maintaining fault coverage.
 */
module test_compressor #(
    parameter INPUT_WIDTH = 64,
    parameter OUTPUT_WIDTH = 16,
    parameter COMPRESSION_RATIO = 4,
    parameter LFSR_WIDTH = 32,
    parameter MISR_WIDTH = 32
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     enable,
    
    // Compression control
    input  wire [2:0]               compression_mode,
    input  wire [LFSR_WIDTH-1:0]    seed_value,
    input  wire                     load_seed,
    
    // Input data interface
    input  wire [INPUT_WIDTH-1:0]   test_data_in,
    input  wire                     data_valid,
    output wire                     data_ready,
    
    // Compressed output interface
    output reg  [OUTPUT_WIDTH-1:0]  compressed_data_out,
    output reg                      compressed_valid,
    input  wire                     compressed_ready,
    
    // Decompression interface
    input  wire [OUTPUT_WIDTH-1:0]  compressed_data_in,
    input  wire                     decompress_enable,
    output reg  [INPUT_WIDTH-1:0]   decompressed_data_out,
    output reg                      decompress_valid,
    
    // Status and statistics
    output reg  [31:0]              compression_ratio_achieved,
    output reg  [31:0]              total_input_bits,
    output reg  [31:0]              total_output_bits,
    output reg  [15:0]              fault_coverage_estimate,
    output reg                      compression_complete
);

    // Compression modes
    localparam MODE_LFSR_RESEEDING  = 3'b000;
    localparam MODE_MISR_SIGNATURE  = 3'b001;
    localparam MODE_DICTIONARY     = 3'b010;
    localparam MODE_RUN_LENGTH     = 3'b011;
    localparam MODE_HUFFMAN        = 3'b100;
    localparam MODE_HYBRID         = 3'b101;

    // Internal registers
    reg [LFSR_WIDTH-1:0]    lfsr_reg;
    reg [MISR_WIDTH-1:0]    misr_reg;
    reg [INPUT_WIDTH-1:0]   input_buffer;
    reg [7:0]               bit_counter;
    reg [15:0]              pattern_counter;
    reg [31:0]              cycle_counter;
    
    // Dictionary compression
    reg [INPUT_WIDTH-1:0]   dictionary [0:255];
    reg [7:0]               dict_size;
    reg [7:0]               dict_index;
    reg                     dict_hit;
    
    // Run-length encoding
    reg [INPUT_WIDTH-1:0]   previous_pattern;
    reg [7:0]               run_length;
    reg                     run_active;
    
    // Decompression support
    reg [INPUT_WIDTH-1:0]   literal_buffer;
    reg                     literal_pending;
    
    // Huffman coding tables (simplified)
    reg [3:0]               huffman_code [0:15];
    reg [3:0]               huffman_length [0:15];
    
    // State machine
    typedef enum logic [2:0] {
        IDLE,
        COMPRESS,
        DECOMPRESS,
        ANALYZE,
        COMPLETE
    } comp_state_t;
    
    comp_state_t comp_state, next_comp_state;

    // Initialize Huffman tables
    initial begin
        // Simple Huffman codes for common patterns
        huffman_code[0] = 4'b0000;    huffman_length[0] = 4;  // All zeros
        huffman_code[1] = 4'b0001;    huffman_length[1] = 4;  // All ones
        huffman_code[2] = 4'b001;     huffman_length[2] = 3;  // Alternating
        huffman_code[3] = 4'b01;      huffman_length[3] = 2;  // Common pattern
        huffman_code[4] = 4'b10;      huffman_length[4] = 2;  // Another common
        huffman_code[5] = 4'b110;     huffman_length[5] = 3;  // Less common
        huffman_code[6] = 4'b1110;    huffman_length[6] = 4;  // Rare
        huffman_code[7] = 4'b1111;    huffman_length[7] = 4;  // Very rare
        // Initialize remaining entries
        for (integer i = 8; i < 16; i = i + 1) begin
            huffman_code[i] = 4'b1111;
            huffman_length[i] = 4;
        end
    end

    // Main compression state machine
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            comp_state <= IDLE;
            lfsr_reg <= 32'h12345678;
            misr_reg <= 32'h00000000;
            input_buffer <= {INPUT_WIDTH{1'b0}};
            bit_counter <= 8'h00;
            pattern_counter <= 16'h0000;
            cycle_counter <= 32'h00000000;
            compressed_data_out <= {OUTPUT_WIDTH{1'b0}};
            compressed_valid <= 1'b0;
            decompressed_data_out <= {INPUT_WIDTH{1'b0}};
            decompress_valid <= 1'b0;
            compression_ratio_achieved <= 32'h00000000;
            total_input_bits <= 32'h00000000;
            total_output_bits <= 32'h00000000;
            fault_coverage_estimate <= 16'h0000;
            compression_complete <= 1'b0;
            dict_size <= 8'h00;
            dict_index <= 8'h00;
            dict_hit <= 1'b0;
            previous_pattern <= {INPUT_WIDTH{1'b0}};
            run_length <= 8'h00;
            run_active <= 1'b0;
            
            // Initialize dictionary with common patterns
            dictionary[0] <= {INPUT_WIDTH{1'b0}};      // All zeros
            dictionary[1] <= {INPUT_WIDTH{1'b1}};      // All ones
            dictionary[2] <= {{INPUT_WIDTH/2{1'b0}}, {INPUT_WIDTH/2{1'b1}}};  // Half pattern
            dictionary[3] <= {INPUT_WIDTH{1'b0}} ^ {INPUT_WIDTH{1'b1}};       // Alternating
            dict_size <= 8'h04;
        end else begin
            comp_state <= next_comp_state;
            cycle_counter <= cycle_counter + 1;
            
            case (comp_state)
                IDLE: begin
                    if (enable) begin
                        compression_complete <= 1'b0;
                        total_input_bits <= 32'h00000000;
                        total_output_bits <= 32'h00000000;
                        pattern_counter <= 16'h0000;
                        
                        if (load_seed) begin
                            lfsr_reg <= seed_value;
                        end
                    end
                end
                
                COMPRESS: begin
                    if (data_valid && data_ready) begin
                        input_buffer <= test_data_in;
                        total_input_bits <= total_input_bits + INPUT_WIDTH;
                        pattern_counter <= pattern_counter + 1;
                        
                        case (compression_mode)
                            MODE_LFSR_RESEEDING: begin
                                compress_lfsr_reseeding();
                            end
                            MODE_MISR_SIGNATURE: begin
                                compress_misr_signature();
                            end
                            MODE_DICTIONARY: begin
                                compress_dictionary();
                            end
                            MODE_RUN_LENGTH: begin
                                compress_run_length();
                            end
                            MODE_HUFFMAN: begin
                                compress_huffman();
                            end
                            MODE_HYBRID: begin
                                compress_hybrid();
                            end
                        endcase
                    end
                end
                
                DECOMPRESS: begin
                    if (decompress_enable) begin
                        case (compression_mode)
                            MODE_LFSR_RESEEDING: begin
                                decompress_lfsr_reseeding();
                            end
                            MODE_DICTIONARY: begin
                                decompress_dictionary();
                            end
                            MODE_RUN_LENGTH: begin
                                decompress_run_length();
                            end
                            default: begin
                                decompressed_data_out <= {INPUT_WIDTH{1'b0}};
                                decompress_valid <= 1'b0;
                            end
                        endcase
                    end
                end
                
                ANALYZE: begin
                    analyze_compression_results();
                end
                
                COMPLETE: begin
                    compression_complete <= 1'b1;
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        next_comp_state = comp_state;
        
        case (comp_state)
            IDLE: begin
                if (enable) begin
                    if (decompress_enable) begin
                        next_comp_state = DECOMPRESS;
                    end else begin
                        next_comp_state = COMPRESS;
                    end
                end
            end
            
            COMPRESS: begin
                if (!enable) begin
                    next_comp_state = ANALYZE;
                end
            end
            
            DECOMPRESS: begin
                if (!decompress_enable) begin
                    next_comp_state = COMPLETE;
                end
            end
            
            ANALYZE: begin
                next_comp_state = COMPLETE;
            end
            
            COMPLETE: begin
                if (!enable && !decompress_enable) begin
                    next_comp_state = IDLE;
                end
            end
        endcase
    end

    // Task for LFSR reseeding compression
    task compress_lfsr_reseeding();
        begin
            // Generate expected pattern from LFSR
            reg [INPUT_WIDTH-1:0] expected_pattern;
            reg [15:0] seed_diff;
            
            expected_pattern = generate_lfsr_pattern(lfsr_reg);
            
            if (input_buffer == expected_pattern) begin
                // Pattern matches LFSR, just output a match indicator
                compressed_data_out <= 16'h0000;  // Match code
                total_output_bits <= total_output_bits + 16;
            end else begin
                // Pattern doesn't match, find minimal seed difference
                seed_diff = find_seed_difference(input_buffer, expected_pattern);
                compressed_data_out <= seed_diff;
                total_output_bits <= total_output_bits + 16;
            end
            
            compressed_valid <= 1'b1;
            
            // Advance LFSR
            lfsr_reg <= {lfsr_reg[30:0], lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0]};
        end
    endtask

    // Task for MISR signature compression
    task compress_misr_signature();
        begin
            // Update MISR with input data
            for (integer i = 0; i < INPUT_WIDTH; i = i + 1) begin
                misr_reg <= {misr_reg[30:0], misr_reg[31] ^ misr_reg[27] ^ misr_reg[2] ^ misr_reg[1] ^ input_buffer[i]};
            end
            
            // Output current signature
            compressed_data_out <= misr_reg[OUTPUT_WIDTH-1:0];
            compressed_valid <= 1'b1;
            total_output_bits <= total_output_bits + OUTPUT_WIDTH;
        end
    endtask

    // Task for dictionary compression
    task compress_dictionary();
        begin
            // Search dictionary for matching pattern
            dict_hit <= 1'b0;
            dict_index <= 8'h00;
            
            for (integer i = 0; i < dict_size; i = i + 1) begin
                if (dictionary[i] == input_buffer) begin
                    dict_hit <= 1'b1;
                    dict_index <= i[7:0];
                end
            end
            
            if (dict_hit) begin
                // Output dictionary index
                compressed_data_out <= {8'h00, dict_index};
                total_output_bits <= total_output_bits + 8;
            end else begin
                // Add to dictionary if space available
                if (dict_size < 255) begin
                    dictionary[dict_size] <= input_buffer;
                    dict_size <= dict_size + 1;
                end
                
                // Output full pattern with escape code
                compressed_data_out <= 16'hFFFF;  // Escape code
                total_output_bits <= total_output_bits + INPUT_WIDTH + 16;
            end
            
            compressed_valid <= 1'b1;
        end
    endtask

    // Task for run-length compression
    task compress_run_length();
        begin
            if (input_buffer == previous_pattern && run_active) begin
                // Continue run
                run_length <= run_length + 1;
                compressed_valid <= 1'b0;  // Don't output yet
            end else begin
                // End of run or new pattern
                if (run_active && run_length > 1) begin
                    // Output run-length encoded data
                    compressed_data_out <= {8'hFF, run_length};  // Run marker + length
                    total_output_bits <= total_output_bits + 16;
                    compressed_valid <= 1'b1;
                end else begin
                    // Output literal pattern
                    compressed_data_out <= input_buffer[OUTPUT_WIDTH-1:0];
                    total_output_bits <= total_output_bits + OUTPUT_WIDTH;
                    compressed_valid <= 1'b1;
                end
                
                // Start new run
                previous_pattern <= input_buffer;
                run_length <= 8'h01;
                run_active <= 1'b1;
            end
        end
    endtask

    // Task for Huffman compression
    task compress_huffman();
        begin
            // Simplified Huffman encoding based on pattern type
            reg [3:0] pattern_type;
            
            // Classify pattern
            if (input_buffer == {INPUT_WIDTH{1'b0}}) begin
                pattern_type = 4'h0;  // All zeros
            end else if (input_buffer == {INPUT_WIDTH{1'b1}}) begin
                pattern_type = 4'h1;  // All ones
            end else if (input_buffer == {{INPUT_WIDTH/2{1'b0}}, {INPUT_WIDTH/2{1'b1}}}) begin
                pattern_type = 4'h2;  // Half pattern
            end else begin
                pattern_type = 4'h3;  // Other
            end
            
            // Output Huffman code
            compressed_data_out <= {12'h000, huffman_code[pattern_type]};
            total_output_bits <= total_output_bits + huffman_length[pattern_type];
            compressed_valid <= 1'b1;
        end
    endtask

    // Task for hybrid compression
    task compress_hybrid();
        begin
            // Use different compression methods based on pattern characteristics
            reg [31:0] pattern_entropy;
            
            pattern_entropy = calculate_entropy(input_buffer);
            
            if (pattern_entropy < 8) begin
                // Low entropy - use run-length
                compress_run_length();
            end else if (pattern_entropy < 16) begin
                // Medium entropy - use dictionary
                compress_dictionary();
            end else begin
                // High entropy - use LFSR reseeding
                compress_lfsr_reseeding();
            end
        end
    endtask

    // Task for LFSR reseeding decompression
    task decompress_lfsr_reseeding();
        begin
            if (compressed_data_in == 16'h0000) begin
                // Match code - generate pattern from current LFSR
                decompressed_data_out <= generate_lfsr_pattern(lfsr_reg);
            end else begin
                // Seed difference - apply to LFSR and generate
                reg [LFSR_WIDTH-1:0] modified_seed;
                modified_seed = lfsr_reg ^ {16'h0000, compressed_data_in};
                decompressed_data_out <= generate_lfsr_pattern(modified_seed);
            end
            
            decompress_valid <= 1'b1;
            
            // Advance LFSR
            lfsr_reg <= {lfsr_reg[30:0], lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0]};
        end
    endtask

    // Task for dictionary decompression
    task decompress_dictionary();
        begin
            if (compressed_data_in == 16'hFFFF) begin
                // Escape code - next data is literal
                // In real implementation, this would read the next literal value
                decompressed_data_out <= literal_buffer; // Use stored literal value
            end else begin
                // Dictionary index decompression
                reg [7:0] index;
                index = compressed_data_in[7:0];
                if (index < dict_size && index < DICT_SIZE) begin
                    decompressed_data_out <= dictionary[index];
                end else begin
                    // Invalid index - output zero pattern
                    decompressed_data_out <= {INPUT_WIDTH{1'b0}};
                    $display("Warning: Invalid dictionary index %d at time %0t", index, $time);
                end
            end
            
            decompress_valid <= 1'b1;
        end
    endtask

    // Task for run-length decompression - Enhanced implementation
    task decompress_run_length();
        begin
            if (compressed_data_in[15:8] == 8'hFF) begin
                // Run-length marker - enhanced handling
                reg [7:0] length;
                length = compressed_data_in[7:0];
                
                if (length > 0 && length <= 255) begin
                    // Output previous pattern 'length' times
                    decompressed_data_out <= previous_pattern;
                    run_length <= length - 1; // Track remaining repetitions
                    run_active <= (length > 1);
                end else begin
                    // Invalid run length
                    decompressed_data_out <= {INPUT_WIDTH{1'b0}};
                    run_active <= 1'b0;
                    $display("Warning: Invalid run length %d at time %0t", length, $time);
                end
            end else begin
                // Literal pattern - enhanced handling
                if (compressed_data_in[15:14] == 2'b10) begin
                    // Extended literal marker for larger patterns
                    decompressed_data_out <= {compressed_data_in[13:0], {(INPUT_WIDTH-14){1'b0}}};
                end else begin
                    // Standard literal pattern
                    decompressed_data_out <= {{(INPUT_WIDTH-OUTPUT_WIDTH){1'b0}}, compressed_data_in};
                end
                previous_pattern <= decompressed_data_out;
                run_active <= 1'b0;
            end
            
            decompress_valid <= 1'b1;
        end
    endtask

    // Task to analyze compression results
    task analyze_compression_results();
        begin
            if (total_input_bits > 0) begin
                compression_ratio_achieved <= (total_input_bits * 100) / total_output_bits;
            end else begin
                compression_ratio_achieved <= 32'h00000000;
            end
            
            // Estimate fault coverage based on compression ratio
            if (compression_ratio_achieved > 400) begin
                fault_coverage_estimate <= 16'd9500;  // 95%
            end else if (compression_ratio_achieved > 200) begin
                fault_coverage_estimate <= 16'd9000;  // 90%
            end else begin
                fault_coverage_estimate <= 16'd8500;  // 85%
            end
        end
    endtask

    // Function to generate LFSR pattern
    function [INPUT_WIDTH-1:0] generate_lfsr_pattern(input [LFSR_WIDTH-1:0] seed);
        reg [LFSR_WIDTH-1:0] temp_lfsr;
        reg [INPUT_WIDTH-1:0] pattern;
        integer i;
        begin
            temp_lfsr = seed;
            pattern = {INPUT_WIDTH{1'b0}};
            
            for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
                pattern[i] = temp_lfsr[0];
                temp_lfsr = {temp_lfsr[30:0], temp_lfsr[31] ^ temp_lfsr[21] ^ temp_lfsr[1] ^ temp_lfsr[0]};
            end
            
            generate_lfsr_pattern = pattern;
        end
    endfunction

    // Function to find seed difference
    function [15:0] find_seed_difference(input [INPUT_WIDTH-1:0] actual, input [INPUT_WIDTH-1:0] expected);
        reg [15:0] diff;
        begin
            // Simplified difference calculation
            diff = actual[15:0] ^ expected[15:0];
            find_seed_difference = diff;
        end
    endfunction

    // Function to calculate pattern entropy (simplified)
    function [31:0] calculate_entropy(input [INPUT_WIDTH-1:0] pattern);
        reg [31:0] ones_count;
        integer i;
        begin
            ones_count = 0;
            for (i = 0; i < INPUT_WIDTH; i = i + 1) begin
                if (pattern[i]) ones_count = ones_count + 1;
            end
            
            // Simple entropy estimate based on bit distribution
            if (ones_count == 0 || ones_count == INPUT_WIDTH) begin
                calculate_entropy = 0;  // No entropy
            end else if (ones_count == INPUT_WIDTH/2) begin
                calculate_entropy = 32;  // Maximum entropy
            end else begin
                calculate_entropy = 16;  // Medium entropy
            end
        end
    endfunction

    // Output control
    assign data_ready = (comp_state == COMPRESS) && compressed_ready;

    // Debug and monitoring
    always @(posedge clk) begin
        if (compressed_valid) begin
            $display("Time: %0t - Compressed: Input %0d bits -> Output %0d bits (Ratio: %0d:1)", 
                    $time, INPUT_WIDTH, OUTPUT_WIDTH, INPUT_WIDTH/OUTPUT_WIDTH);
        end
        
        if (compression_complete) begin
            $display("Time: %0t - Compression complete: Total ratio %0d:1, Coverage estimate: %0d%%", 
                    $time, compression_ratio_achieved/100, fault_coverage_estimate/100);
        end
    end

endmodule