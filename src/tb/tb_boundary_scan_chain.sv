`timescale 1ns / 1ps

module tb_boundary_scan_chain;

    reg tck;
    reg tdi;
    wire tdo;
    reg [3:0] control;
    reg [7:0] data_in;
    wire [7:0] data_out;

    // Instantiate the boundary scan chain
    boundary_scan_chain uut (
        .tck(tck),
        .tdi(tdi),
        .tdo(tdo),
        .control(control),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        tck = 0;
        forever #5 tck = ~tck;  // Use --timing or --no-timing to specify how delays should be handled
    end

    // Test sequence
    initial begin
        // Initialize
        control = 4'b0000;
        data_in = 8'hA5;
        tdi = 0;

        // Load data into the scan chain
        control[2] = 1;
        @(posedge tck);  // Use --timing or --no-timing to specify how event controls should be handled
        control[2] = 0;

        // Shift data through the scan chain
        control[0] = 1;
        repeat (8) begin
            tdi = $random & 1'b1;  // Fix width truncation warning
            @(posedge tck);  // Use --timing or --no-timing to specify how event controls should be handled
        end
        control[0] = 0;

        // Capture parallel output
        control[1] = 1;
        @(posedge tck);  // Use --timing or --no-timing to specify how event controls should be handled
        control[1] = 0;

        // Finish simulation
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time: %0t, data_out: %0h, tdo: %b", $time, data_out, tdo);
    end

endmodule
