`timescale 1ns / 1ps

module tb_top_module;

    reg tck;
    reg tms;
    reg tdi;
    wire tdo;
    reg clk;
    reg reset;
    reg [7:0] loopback_data_in;
    wire [7:0] loopback_data_out;
    reg [3:0] bsc_control;
    reg [7:0] bsc_data_in;
    wire [7:0] bsc_data_out;

    // Instantiate the top module
    top_module uut (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .clk(clk),
        .reset(reset),
        .loopback_data_in(loopback_data_in),
        .loopback_data_out(loopback_data_out),
        .bsc_control(bsc_control),
        .bsc_data_in(bsc_data_in),
        .bsc_data_out(bsc_data_out)
    );

    // Clock generation for tck and clk
    initial begin
        tck = 0;
        clk = 0;
        forever begin
            #5 tck = ~tck;  // Use --timing or --no-timing to specify how delays should be handled
            #5 clk = ~clk;  // Use --timing or --no-timing to specify how delays should be handled
        end
    end

    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        loopback_data_in = 8'h00;
        bsc_control = 4'b0000;
        bsc_data_in = 8'hA5;
        tms = 1;
        tdi = 0;

        // Reset system
        @(posedge clk);
        reset = 0;

        // JTAG controller test
        repeat (5) @(posedge tck);  // Use --timing or --no-timing to specify how event controls should be handled
        tms = 0;
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

        // Boundary scan chain test
        bsc_control[2] = 1;
        @(posedge tck);
        bsc_control[2] = 0;
        bsc_control[0] = 1;
        repeat (8) begin
            tdi = ($random % 2) == 1; // Generate either 0 or 1
            @(posedge tck);
        end
        bsc_control[0] = 0;
        bsc_control[1] = 1;
        @(posedge tck);
        bsc_control[1] = 0;

        // Loopback module test
        loopback_data_in = 8'h55;
        @(posedge clk);
        loopback_data_in = 8'hAA;
        @(posedge clk);
        loopback_data_in = 8'hFF;
        @(posedge clk);

        // Finish simulation
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time: %0t, loopback_data_out: %0h, bsc_data_out: %0h, tdo: %b", $time, loopback_data_out, bsc_data_out, tdo);
    end

endmodule
