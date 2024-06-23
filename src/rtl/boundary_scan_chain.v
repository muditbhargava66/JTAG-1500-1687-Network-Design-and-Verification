`timescale 1ns / 1ps

module boundary_scan_chain (
    input wire tck,
    input wire tdi,
    output wire tdo,
    input wire [3:0] control, // control signals for scan cells
    input wire [7:0] data_in, // parallel input data
    output wire [7:0] data_out // parallel output data
);

    reg [7:0] scan_chain;
    reg [7:0] parallel_out;

    always @(posedge tck) begin
        if (control[0]) begin
            scan_chain <= {scan_chain[6:0], tdi};
        end
        if (control[1]) begin
            parallel_out <= scan_chain;
        end
        if (control[2]) begin
            scan_chain <= data_in;
        end
    end

    assign tdo = scan_chain[7];
    assign data_out = parallel_out;

endmodule
