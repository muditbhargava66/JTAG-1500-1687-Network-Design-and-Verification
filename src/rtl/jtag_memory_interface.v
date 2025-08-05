`timescale 1ns / 1ps

/**
 * JTAG Memory Interface
 * 
 * This module provides a safe memory interface for JTAG access with
 * address range checking, access control, and error handling.
 */
module jtag_memory_interface #(
    parameter MEM_SIZE = 1024,           // Memory size in words
    parameter ADDR_WIDTH = 32,           // Address width
    parameter DATA_WIDTH = 32,           // Data width
    parameter BASE_ADDR = 32'h00000000   // Base address
) (
    input wire                    clk,
    input wire                    reset_n,
    
    // JTAG interface
    input wire                    jtag_enable,
    input wire                    jtag_write,
    input wire [ADDR_WIDTH-1:0]   jtag_address,
    input wire [DATA_WIDTH-1:0]   jtag_write_data,
    output reg [DATA_WIDTH-1:0]   jtag_read_data,
    output reg                    jtag_ready,
    output reg                    jtag_error,
    
    // System memory interface (optional - for real implementation)
    output reg                    sys_mem_enable,
    output reg                    sys_mem_write,
    output reg [ADDR_WIDTH-1:0]   sys_mem_address,
    output reg [DATA_WIDTH-1:0]   sys_mem_write_data,
    input wire [DATA_WIDTH-1:0]   sys_mem_read_data,
    input wire                    sys_mem_ready,
    input wire                    sys_mem_error,
    
    // Access control
    input wire                    debug_mode,      // Debug mode enable
    input wire [7:0]              access_level     // Access level control
);

    // Memory array (for demonstration - in real implementation, this would interface to system memory)
    reg [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];
    
    // Address calculation
    wire [ADDR_WIDTH-1:0] word_address;
    wire                  address_valid;
    wire                  access_allowed;
    
    // State machine for memory operations
    typedef enum logic [2:0] {
        IDLE,
        CHECK_ACCESS,
        READ_MEM,
        WRITE_MEM,
        COMPLETE,
        ERROR
    } mem_state_t;
    
    mem_state_t current_state, next_state;
    
    // Address validation
    assign word_address = (jtag_address - BASE_ADDR) >> 2; // Convert to word address
    assign address_valid = (jtag_address >= BASE_ADDR) && 
                          (jtag_address < (BASE_ADDR + (MEM_SIZE * 4))) &&
                          ((jtag_address & 2'b11) == 2'b00); // Word aligned
    
    // Access control logic
    assign access_allowed = debug_mode || (access_level >= 8'h80); // Require high access level
    
    // Initialize memory with test pattern
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE; i = i + 1) begin
            memory[i] = i * 4 + 32'hA5A5A500; // Test pattern
        end
    end
    
    // State machine
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (jtag_enable) begin
                    next_state = CHECK_ACCESS;
                end
            end
            
            CHECK_ACCESS: begin
                if (!address_valid || !access_allowed) begin
                    next_state = ERROR;
                end else if (jtag_write) begin
                    next_state = WRITE_MEM;
                end else begin
                    next_state = READ_MEM;
                end
            end
            
            READ_MEM: begin
                next_state = COMPLETE;
            end
            
            WRITE_MEM: begin
                next_state = COMPLETE;
            end
            
            COMPLETE: begin
                if (!jtag_enable) begin
                    next_state = IDLE;
                end
            end
            
            ERROR: begin
                if (!jtag_enable) begin
                    next_state = IDLE;
                end
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Output logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            jtag_read_data <= 32'h00000000;
            jtag_ready <= 1'b0;
            jtag_error <= 1'b0;
            sys_mem_enable <= 1'b0;
            sys_mem_write <= 1'b0;
            sys_mem_address <= 32'h00000000;
            sys_mem_write_data <= 32'h00000000;
        end else begin
            
            case (current_state)
                IDLE: begin
                    jtag_ready <= 1'b0;
                    jtag_error <= 1'b0;
                    sys_mem_enable <= 1'b0;
                end
                
                CHECK_ACCESS: begin
                    jtag_ready <= 1'b0;
                    jtag_error <= 1'b0;
                end
                
                READ_MEM: begin
                    if (word_address < MEM_SIZE) begin
                        // Read from internal memory
                        jtag_read_data <= memory[word_address];
                        jtag_ready <= 1'b1;
                        jtag_error <= 1'b0;
                        
                        // In real implementation, would also access system memory
                        sys_mem_enable <= 1'b1;
                        sys_mem_write <= 1'b0;
                        sys_mem_address <= jtag_address;
                    end else begin
                        jtag_error <= 1'b1;
                    end
                end
                
                WRITE_MEM: begin
                    if (word_address < MEM_SIZE) begin
                        // Write to internal memory
                        memory[word_address] <= jtag_write_data;
                        jtag_read_data <= jtag_write_data; // Echo back written data
                        jtag_ready <= 1'b1;
                        jtag_error <= 1'b0;
                        
                        // In real implementation, would also write to system memory
                        sys_mem_enable <= 1'b1;
                        sys_mem_write <= 1'b1;
                        sys_mem_address <= jtag_address;
                        sys_mem_write_data <= jtag_write_data;
                    end else begin
                        jtag_error <= 1'b1;
                    end
                end
                
                COMPLETE: begin
                    jtag_ready <= 1'b1;
                    sys_mem_enable <= 1'b0;
                end
                
                ERROR: begin
                    jtag_ready <= 1'b1;
                    jtag_error <= 1'b1;
                    jtag_read_data <= 32'hDEADBEEF; // Error pattern
                    sys_mem_enable <= 1'b0;
                end
                
                default: begin
                    jtag_ready <= 1'b0;
                    jtag_error <= 1'b0;
                    sys_mem_enable <= 1'b0;
                end
            endcase
        end
    end
    
    // Debug monitoring
    always @(posedge clk) begin
        if (current_state == WRITE_MEM && jtag_ready) begin
            $display("JTAG Memory: Write to address %h, data %h at time %0t", 
                    jtag_address, jtag_write_data, $time);
        end
        
        if (current_state == READ_MEM && jtag_ready) begin
            $display("JTAG Memory: Read from address %h, data %h at time %0t", 
                    jtag_address, jtag_read_data, $time);
        end
        
        if (current_state == ERROR) begin
            $display("JTAG Memory: Access error - address %h, valid=%b, allowed=%b at time %0t", 
                    jtag_address, address_valid, access_allowed, $time);
        end
    end

endmodule