`timescale 1ns / 1ps

module tb_jtag_controller;

    reg tck;
    reg tms;
    reg tdi;
    wire tdo;
    wire [3:0] state;

    // Instantiate the JTAG controller
    jtag_controller uut (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .state(state)
    );

    // Clock generation
    initial begin
        tck = 0;
        forever #5 tck = ~tck;  // Use --timing or --no-timing to specify how delays should be handled
    end

    // Test sequence
    initial begin
        // Reset
        tms = 1;
        tdi = 0;
        repeat (5) @(posedge tck);  // Use --timing or --no-timing to specify how event controls should be handled
        tms = 0;

        // Test JTAG state transitions
        @(posedge tck);
        tms = 1;
        @(posedge tck);
        tms = 0;
        @(posedge tck);
        tms = 0;
        @(posedge tck);
        tms = 1;
        @(posedge tck);
        tms = 0;
        @(posedge tck);

        // Finish simulation
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time: %0t, state: %0b, tdo: %b", $time, state, tdo);
    end

endmodule
