`timescale 1ns / 1ps

module top_module (
    input wire tck,
    input wire tms,
    input wire tdi,
    output wire tdo,
    input wire clk,
    input wire reset,
    input wire [7:0] loopback_data_in,
    output wire [7:0] loopback_data_out,
    input wire [3:0] bsc_control,
    input wire [7:0] bsc_data_in,
    output wire [7:0] bsc_data_out
);

    wire [3:0] jtag_state;
    wire jtag_tdo;  // Output from JTAG controller
    wire bsc_tdo;   // Output from boundary scan chain

    // Instantiate the JTAG controller
    jtag_controller jtag_inst (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(jtag_tdo),  // Changed to jtag_tdo
        .state(jtag_state)
    );

    // Instantiate the boundary scan chain
    boundary_scan_chain bsc_inst (
        .tck(tck),
        .tdi(jtag_tdo),  // Use JTAG controller's output as input
        .tdo(bsc_tdo),   // Output to bsc_tdo
        .control(bsc_control),
        .data_in(bsc_data_in),
        .data_out(bsc_data_out)
    );

    // Instantiate the loopback module
    loopback_module loopback_inst (
        .clk(clk),
        .reset(reset),
        .data_in(loopback_data_in),
        .data_out(loopback_data_out)
    );

    // Select which TDO signal to output based on the current state
    // For this simple implementation, we'll use boundary scan chain's TDO
    // In a more complex design, we'd use a multiplexer based on JTAG state
    assign tdo = bsc_tdo;  // Use boundary scan chain's output as final output

endmodule