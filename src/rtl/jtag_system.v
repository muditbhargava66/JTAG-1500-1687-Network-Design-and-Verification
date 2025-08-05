`timescale 1ns / 1ps

/**
 * Complete JTAG System with Memory Access
 * 
 * This module integrates the complete JTAG controller with memory interface
 * to provide a full-featured JTAG system with memory access capabilities.
 */
module jtag_system (
    input wire        clk,           // System clock
    input wire        reset_n,       // System reset
    
    // JTAG interface
    input wire        tck,           // Test Clock
    input wire        tms,           // Test Mode Select
    input wire        tdi,           // Test Data In
    output wire       tdo,           // Test Data Out
    output wire       trst_n_out,    // Test Reset output
    
    // System interface
    input wire [7:0]  boundary_scan_in,  // Boundary scan inputs
    output wire [7:0] boundary_scan_out, // Boundary scan outputs
    
    // Status outputs
    output wire       jtag_error,    // JTAG error indicator
    output wire [7:0] error_code,    // Error code
    output wire [3:0] jtag_state,    // Current JTAG state
    output wire [3:0] current_instruction, // Current instruction
    
    // Debug interface
    input wire        debug_mode,    // Debug mode enable
    input wire [7:0]  access_level   // Access level control
);

    // Internal signals
    wire        mem_enable;
    wire        mem_write;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;
    wire [31:0] mem_read_data;
    wire        mem_ready;
    wire        mem_error;
    
    // JTAG Controller instance
    jtag_controller jtag_ctrl (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .trst_n_out(trst_n_out),
        
        // State outputs
        .state(jtag_state),
        .test_logic_reset_state(),
        .run_test_idle_state(),
        .select_dr_scan_state(),
        .capture_dr_state(),
        .shift_dr_state(),
        .exit1_dr_state(),
        .pause_dr_state(),
        .exit2_dr_state(),
        .update_dr_state(),
        .select_ir_scan_state(),
        .capture_ir_state(),
        .shift_ir_state(),
        .exit1_ir_state(),
        .pause_ir_state(),
        .exit2_ir_state(),
        .update_ir_state(),
        
        // Instruction register
        .ir_reg(current_instruction),
        
        // Memory interface
        .mem_enable(mem_enable),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),
        .mem_error(mem_error),
        
        // Boundary scan interface
        .boundary_scan_out(boundary_scan_out),
        .boundary_scan_in(boundary_scan_in),
        
        // Status and error outputs
        .jtag_error(jtag_error),
        .error_code(error_code),
        
        // Reset
        .ext_reset(~reset_n)
    );
    
    // Memory Interface instance
    jtag_memory_interface #(
        .MEM_SIZE(1024),              // 4KB memory
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .BASE_ADDR(32'h00000000)
    ) mem_if (
        .clk(clk),
        .reset_n(reset_n),
        
        // JTAG interface
        .jtag_enable(mem_enable),
        .jtag_write(mem_write),
        .jtag_address(mem_address),
        .jtag_write_data(mem_write_data),
        .jtag_read_data(mem_read_data),
        .jtag_ready(mem_ready),
        .jtag_error(mem_error),
        
        // System memory interface (not connected in this example)
        .sys_mem_enable(),
        .sys_mem_write(),
        .sys_mem_address(),
        .sys_mem_write_data(),
        .sys_mem_read_data(32'h00000000),
        .sys_mem_ready(1'b1),
        .sys_mem_error(1'b0),
        
        // Access control
        .debug_mode(debug_mode),
        .access_level(access_level)
    );

endmodule