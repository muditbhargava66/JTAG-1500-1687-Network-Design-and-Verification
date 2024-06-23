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
    wire bsc_tdo;

    jtag_controller jtag_inst (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(bsc_tdo),
        .state(jtag_state)
    );

    boundary_scan_chain bsc_inst (
        .tck(tck),
        .tdi(tdi),
        .tdo(bsc_tdo),
        .control(bsc_control),
        .data_in(bsc_data_in),
        .data_out(bsc_data_out)
    );

    loopback_module loopback_inst (
        .clk(clk),
        .reset(reset),
        .data_in(loopback_data_in),
        .data_out(loopback_data_out)
    );

    assign tdo = bsc_tdo;

endmodule
