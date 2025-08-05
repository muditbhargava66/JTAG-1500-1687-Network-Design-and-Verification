`timescale 1ns / 1ps

/**
 * Simple Boundary Scan Chain Wrapper
 * 
 * This module provides backward compatibility with the original simple interface
 * while using the enhanced boundary scan chain internally.
 */
module boundary_scan_chain (
    input wire tck,
    input wire tdi,
    output wire tdo,
    input wire [3:0] control, // control signals for scan cells
    input wire [7:0] data_in, // parallel input data
    output wire [7:0] data_out // parallel output data
);

    // Enhanced boundary scan chain with simple interface mapping
    boundary_scan_chain_enhanced #(
        .CHAIN_LENGTH(8),
        .CELL_WIDTH(1)
    ) enhanced_bsc (
        .tck(tck),
        .tdi(tdi),
        .tdo(tdo),
        .control(control),
        .reset_n(1'b1), // Always enabled for simple interface
        .functional_data_in(data_in),
        .functional_data_out(data_out),
        .functional_enable(8'hFF), // All enabled
        .test_data_in(8'h00),
        .test_data_out(),
        .scan_complete(),
        .scan_status()
    );

endmodule