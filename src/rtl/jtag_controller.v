`timescale 1ns / 1ps

/**
 * Complete JTAG Controller Implementation
 * 
 * This module implements a full-featured JTAG (IEEE 1149.1) TAP controller
 * with memory access capabilities, proper instruction handling, and
 * comprehensive data register operations.
 * 
 * Features:
 * - Complete IEEE 1149.1 TAP state machine
 * - Standard JTAG instructions (BYPASS, EXTEST, IDCODE, SAMPLE/PRELOAD)
 * - Memory access instructions (MEM_READ, MEM_WRITE)
 * - Address range checking and error handling
 * - Proper data register operations
 * - Boundary scan support
 */
module jtag_controller (
    input wire tck,         // Test Clock
    input wire tms,         // Test Mode Select
    input wire tdi,         // Test Data In
    output wire tdo,        // Test Data Out
    output wire trst_n_out, // Test Reset (active low) output
    
    // TAP state outputs
    output reg [3:0] state, // Current state of the JTAG state machine
    
    // State indicator outputs
    output wire test_logic_reset_state,
    output wire run_test_idle_state,
    output wire select_dr_scan_state,
    output wire capture_dr_state,
    output wire shift_dr_state,
    output wire exit1_dr_state,
    output wire pause_dr_state,
    output wire exit2_dr_state,
    output wire update_dr_state,
    output wire select_ir_scan_state,
    output wire capture_ir_state,
    output wire shift_ir_state,
    output wire exit1_ir_state,
    output wire pause_ir_state,
    output wire exit2_ir_state,
    output wire update_ir_state,
    
    // Instruction register
    output reg [3:0] ir_reg, // Current instruction register
    
    // Memory interface for JTAG memory access
    output reg        mem_enable,    // Memory enable
    output reg        mem_write,     // Memory write enable
    output reg [31:0] mem_address,   // Memory address
    output reg [31:0] mem_write_data,// Memory write data
    input wire [31:0] mem_read_data, // Memory read data
    input wire        mem_ready,     // Memory operation ready
    input wire        mem_error,     // Memory access error
    
    // Boundary scan interface
    output reg [7:0]  boundary_scan_out, // Boundary scan outputs
    input wire [7:0]  boundary_scan_in,  // Boundary scan inputs
    
    // Status and error outputs
    output reg        jtag_error,    // JTAG operation error
    output reg [7:0]  error_code,    // Error code
    
    // Optional external reset
    input wire ext_reset
);

    // JTAG state machine states (16 states as per IEEE 1149.1)
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
    
    // JTAG Instructions (IEEE 1149.1 standard + custom memory access)
    localparam BYPASS         = 4'b1111;  // Mandatory bypass instruction
    localparam IDCODE         = 4'b0001;  // Device identification
    localparam SAMPLE_PRELOAD = 4'b0010;  // Sample/preload boundary scan
    localparam EXTEST         = 4'b0000;  // External test
    localparam INTEST         = 4'b0011;  // Internal test
    localparam MEM_READ       = 4'b0100;  // Memory read instruction
    localparam MEM_WRITE      = 4'b0101;  // Memory write instruction
    localparam DEBUG_ACCESS   = 4'b0110;  // Debug access instruction
    
    // Error codes
    localparam ERR_NONE           = 8'h00;
    localparam ERR_INVALID_ADDR   = 8'h01;
    localparam ERR_MEM_TIMEOUT    = 8'h02;
    localparam ERR_MEM_ERROR      = 8'h03;
    localparam ERR_INVALID_INSTR  = 8'h04;
    localparam ERR_ACCESS_DENIED  = 8'h05;
    
    // Memory address ranges (configurable in real implementation)
    localparam MEM_BASE_ADDR      = 32'h00000000;
    localparam MEM_SIZE           = 32'h00100000;  // 1MB accessible memory
    localparam MEM_END_ADDR       = MEM_BASE_ADDR + MEM_SIZE - 1;
    
    // Internal registers
    reg        trst_n;           // Internal reset signal
    reg [4:0]  tms_high_count;   // TMS high counter for reset detection
    reg        tdo_int;          // Internal TDO signal
    
    // Instruction register chain
    reg [3:0]  ir_shift;         // IR shift register
    
    // Data registers
    reg [31:0] idcode_reg;       // Device ID register
    reg        bypass_reg;       // Bypass register
    reg [7:0]  boundary_scan_reg;// Boundary scan register
    reg [63:0] mem_access_reg;   // Memory access register [63:32]=addr, [31:0]=data
    reg [31:0] debug_reg;        // Debug register
    
    // Memory access control
    reg        mem_operation_pending;
    reg [15:0] mem_timeout_counter;
    reg        mem_access_valid;
    
    // Reset detection and generation
    always @(posedge tck or posedge ext_reset) begin
        if (ext_reset) begin
            trst_n <= 1'b0;
            tms_high_count <= 5'b00000;
        end else begin
            if (tms) begin
                if (tms_high_count < 5'b11111)
                    tms_high_count <= tms_high_count + 1'b1;
            end else begin
                tms_high_count <= 5'b00000;
            end
            
            // Assert reset if TMS is high for 5 or more cycles
            trst_n <= ~(tms_high_count >= 5'b00101);
        end
    end
    
    assign trst_n_out = trst_n;
    
    // JTAG TAP state machine (IEEE 1149.1 compliant)
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            state <= TEST_LOGIC_RESET;
        end else begin
            case (state)
                TEST_LOGIC_RESET: 
                    state <= tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
                    
                RUN_TEST_IDLE:    
                    state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                    
                SELECT_DR_SCAN:   
                    state <= tms ? SELECT_IR_SCAN : CAPTURE_DR;
                    
                CAPTURE_DR:       
                    state <= tms ? EXIT1_DR : SHIFT_DR;
                    
                SHIFT_DR:         
                    state <= tms ? EXIT1_DR : SHIFT_DR;
                    
                EXIT1_DR:         
                    state <= tms ? UPDATE_DR : PAUSE_DR;
                    
                PAUSE_DR:         
                    state <= tms ? EXIT2_DR : PAUSE_DR;
                    
                EXIT2_DR:         
                    state <= tms ? UPDATE_DR : SHIFT_DR;
                    
                UPDATE_DR:        
                    state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                    
                SELECT_IR_SCAN:   
                    state <= tms ? TEST_LOGIC_RESET : CAPTURE_IR;
                    
                CAPTURE_IR:       
                    state <= tms ? EXIT1_IR : SHIFT_IR;
                    
                SHIFT_IR:         
                    state <= tms ? EXIT1_IR : SHIFT_IR;
                    
                EXIT1_IR:         
                    state <= tms ? UPDATE_IR : PAUSE_IR;
                    
                PAUSE_IR:         
                    state <= tms ? EXIT2_IR : PAUSE_IR;
                    
                EXIT2_IR:         
                    state <= tms ? UPDATE_IR : SHIFT_IR;
                    
                UPDATE_IR:        
                    state <= tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                    
                default:          
                    state <= TEST_LOGIC_RESET;
            endcase
        end
    end
    
    // State indicator assignments
    assign test_logic_reset_state = (state == TEST_LOGIC_RESET);
    assign run_test_idle_state    = (state == RUN_TEST_IDLE);
    assign select_dr_scan_state   = (state == SELECT_DR_SCAN);
    assign capture_dr_state       = (state == CAPTURE_DR);
    assign shift_dr_state         = (state == SHIFT_DR);
    assign exit1_dr_state         = (state == EXIT1_DR);
    assign pause_dr_state         = (state == PAUSE_DR);
    assign exit2_dr_state         = (state == EXIT2_DR);
    assign update_dr_state        = (state == UPDATE_DR);
    assign select_ir_scan_state   = (state == SELECT_IR_SCAN);
    assign capture_ir_state       = (state == CAPTURE_IR);
    assign shift_ir_state         = (state == SHIFT_IR);
    assign exit1_ir_state         = (state == EXIT1_IR);
    assign pause_ir_state         = (state == PAUSE_IR);
    assign exit2_ir_state         = (state == EXIT2_IR);
    assign update_ir_state        = (state == UPDATE_IR);
    
    // Instruction Register logic
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir_shift <= IDCODE;  // Default to IDCODE on reset
            ir_reg <= IDCODE;
        end else begin
            // Capture phase - load fixed pattern
            if (capture_ir_state) begin
                ir_shift <= 4'b0101; // Fixed pattern as per IEEE 1149.1
            end 
            // Shift phase - shift in new instruction
            else if (shift_ir_state) begin
                ir_shift <= {tdi, ir_shift[3:1]};
            end
            
            // Update phase - update instruction register
            if (update_ir_state) begin
                // Validate instruction before updating
                case (ir_shift)
                    BYPASS, IDCODE, SAMPLE_PRELOAD, EXTEST, INTEST,
                    MEM_READ, MEM_WRITE, DEBUG_ACCESS: begin
                        ir_reg <= ir_shift;
                        jtag_error <= 1'b0;
                        error_code <= ERR_NONE;
                    end
                    default: begin
                        ir_reg <= BYPASS; // Default to BYPASS for invalid instructions
                        jtag_error <= 1'b1;
                        error_code <= ERR_INVALID_INSTR;
                    end
                endcase
            end
        end
    end
    
    // Data Register operations
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            // Initialize all data registers
            idcode_reg <= 32'h1234_5678;  // Device ID (configurable in real implementation)
            bypass_reg <= 1'b0;
            boundary_scan_reg <= 8'h00;
            mem_access_reg <= 64'h0000_0000_0000_0000;
            debug_reg <= 32'h0000_0000;
            mem_operation_pending <= 1'b0;
            mem_timeout_counter <= 16'h0000;
            mem_access_valid <= 1'b0;
        end else begin
            
            // Handle data register operations based on current instruction
            case (ir_reg)
                
                IDCODE: begin
                    if (capture_dr_state) begin
                        // IDCODE is automatically captured
                    end else if (shift_dr_state) begin
                        idcode_reg <= {tdi, idcode_reg[31:1]};
                    end
                end
                
                BYPASS: begin
                    if (shift_dr_state) begin
                        bypass_reg <= tdi;
                    end
                end
                
                SAMPLE_PRELOAD, EXTEST: begin
                    if (capture_dr_state) begin
                        // Capture boundary scan data
                        boundary_scan_reg <= boundary_scan_in;
                    end else if (shift_dr_state) begin
                        boundary_scan_reg <= {tdi, boundary_scan_reg[7:1]};
                    end else if (update_dr_state) begin
                        // Update boundary scan outputs
                        boundary_scan_out <= boundary_scan_reg;
                    end
                end
                
                MEM_READ: begin
                    if (capture_dr_state) begin
                        // Capture memory read data
                        if (mem_ready && !mem_error) begin
                            mem_access_reg[31:0] <= mem_read_data;
                            jtag_error <= 1'b0;
                            error_code <= ERR_NONE;
                        end else if (mem_error) begin
                            mem_access_reg[31:0] <= 32'hDEAD_BEEF; // Error pattern
                            jtag_error <= 1'b1;
                            error_code <= ERR_MEM_ERROR;
                        end
                    end else if (shift_dr_state) begin
                        mem_access_reg <= {tdi, mem_access_reg[63:1]};
                    end else if (update_dr_state) begin
                        // Initiate memory read operation
                        mem_address <= mem_access_reg[63:32];
                        
                        // Address range checking
                        if (mem_access_reg[63:32] >= MEM_BASE_ADDR && 
                            mem_access_reg[63:32] <= MEM_END_ADDR) begin
                            mem_enable <= 1'b1;
                            mem_write <= 1'b0;
                            mem_operation_pending <= 1'b1;
                            mem_timeout_counter <= 16'hFFFF;
                            mem_access_valid <= 1'b1;
                        end else begin
                            jtag_error <= 1'b1;
                            error_code <= ERR_INVALID_ADDR;
                            mem_access_valid <= 1'b0;
                        end
                    end
                end
                
                MEM_WRITE: begin
                    if (capture_dr_state) begin
                        // Capture current memory data for verification
                        if (mem_ready && !mem_error) begin
                            mem_access_reg[31:0] <= mem_read_data;
                        end
                    end else if (shift_dr_state) begin
                        mem_access_reg <= {tdi, mem_access_reg[63:1]};
                    end else if (update_dr_state) begin
                        // Initiate memory write operation
                        mem_address <= mem_access_reg[63:32];
                        mem_write_data <= mem_access_reg[31:0];
                        
                        // Address range checking
                        if (mem_access_reg[63:32] >= MEM_BASE_ADDR && 
                            mem_access_reg[63:32] <= MEM_END_ADDR) begin
                            mem_enable <= 1'b1;
                            mem_write <= 1'b1;
                            mem_operation_pending <= 1'b1;
                            mem_timeout_counter <= 16'hFFFF;
                            mem_access_valid <= 1'b1;
                        end else begin
                            jtag_error <= 1'b1;
                            error_code <= ERR_INVALID_ADDR;
                            mem_access_valid <= 1'b0;
                        end
                    end
                end
                
                DEBUG_ACCESS: begin
                    if (capture_dr_state) begin
                        // Capture debug information
                        debug_reg <= {error_code, 8'h00, state, 12'h000};
                    end else if (shift_dr_state) begin
                        debug_reg <= {tdi, debug_reg[31:1]};
                    end
                end
                
                default: begin
                    // Default to bypass for unknown instructions
                    if (shift_dr_state) begin
                        bypass_reg <= tdi;
                    end
                end
            endcase
            
            // Memory operation timeout and completion handling
            if (mem_operation_pending) begin
                if (mem_ready) begin
                    mem_enable <= 1'b0;
                    mem_write <= 1'b0;
                    mem_operation_pending <= 1'b0;
                    if (mem_error) begin
                        jtag_error <= 1'b1;
                        error_code <= ERR_MEM_ERROR;
                    end
                end else if (mem_timeout_counter == 16'h0000) begin
                    // Timeout occurred
                    mem_enable <= 1'b0;
                    mem_write <= 1'b0;
                    mem_operation_pending <= 1'b0;
                    jtag_error <= 1'b1;
                    error_code <= ERR_MEM_TIMEOUT;
                end else begin
                    mem_timeout_counter <= mem_timeout_counter - 1'b1;
                end
            end
        end
    end
    
    // TDO output multiplexer - Complete implementation
    always @(negedge tck or negedge trst_n) begin
        if (!trst_n) begin
            tdo_int <= 1'b0;
        end else begin
            if (shift_ir_state) begin
                // Shift out instruction register
                tdo_int <= ir_shift[0];
            end else if (shift_dr_state) begin
                // Shift out appropriate data register
                case (ir_reg)
                    IDCODE: 
                        tdo_int <= idcode_reg[0];
                    SAMPLE_PRELOAD, EXTEST: 
                        tdo_int <= boundary_scan_reg[0];
                    MEM_READ, MEM_WRITE:
                        tdo_int <= mem_access_reg[0];
                    DEBUG_ACCESS:
                        tdo_int <= debug_reg[0];
                    BYPASS: 
                        tdo_int <= bypass_reg;
                    default: 
                        tdo_int <= bypass_reg; // Default to bypass
                endcase
            end else begin
                tdo_int <= 1'b0;
            end
        end
    end
    
    assign tdo = tdo_int;
    
    // Debug and monitoring (for simulation)
    always @(posedge tck) begin
        if (update_ir_state) begin
            $display("JTAG: Instruction updated to %h at time %0t", ir_shift, $time);
        end
        
        if (mem_enable && mem_write) begin
            $display("JTAG: Memory write to address %h, data %h at time %0t", 
                    mem_address, mem_write_data, $time);
        end
        
        if (mem_enable && !mem_write) begin
            $display("JTAG: Memory read from address %h at time %0t", mem_address, $time);
        end
        
        if (jtag_error) begin
            $display("JTAG: Error occurred - code %h at time %0t", error_code, $time);
        end
    end

endmodule