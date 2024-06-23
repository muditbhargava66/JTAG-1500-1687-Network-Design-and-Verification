`timescale 1ns / 1ps

module tb_loopback_module;

    reg clk;
    reg reset;
    reg [7:0] data_in;
    wire [7:0] data_out;

    // Instantiate the loopback module
    loopback_module uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Use --timing or --no-timing to specify how delays should be handled
    end

    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        data_in = 8'h00;
        @(posedge clk);  // Use --timing or --no-timing to specify how event controls should be handled
        reset = 0;

        // Apply test data
        data_in = 8'h55;
        @(posedge clk);
        data_in = 8'hAA;
        @(posedge clk);
        data_in = 8'hFF;
        @(posedge clk);

        // Finish simulation
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time: %0t, data_in: %0h, data_out: %0h", $time, data_in, data_out);
    end

endmodule
