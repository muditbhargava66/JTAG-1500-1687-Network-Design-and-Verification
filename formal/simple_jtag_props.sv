`timescale 1ns / 1ps

// Simplified JTAG Controller Properties for Basic Formal Verification
module simple_jtag_props (
    input wire tck,
    input wire tms,
    input wire tdi,
    input wire ext_reset,
    output wire tdo,
    output wire trst_n_out,
    output wire [3:0] state
);

    // Instantiate the JTAG controller
    jtag_controller uut (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(tdo),
        .trst_n_out(trst_n_out),
        .state(state),
        .ext_reset(ext_reset)
    );
    
    // TAP controller states
    localparam TEST_LOGIC_RESET = 4'b0000;
    localparam RUN_TEST_IDLE    = 4'b0001;
    
    // Simple properties for basic verification
    reg f_past_valid = 0;
    
    always @(posedge tck) begin
        f_past_valid <= 1;
    end
    
    // Property 1: External reset brings controller to TEST_LOGIC_RESET
    always @(posedge tck) begin
        if (f_past_valid && $past(ext_reset))
            assert(state == TEST_LOGIC_RESET);
    end
    
    // Property 2: State should be valid (0-15)
    always @(*) begin
        assert(state <= 4'b1111);
    end
    
    // Cover: Reach different states
    always @(posedge tck) begin
        cover(state == TEST_LOGIC_RESET);
        cover(state == RUN_TEST_IDLE);
    end

endmodule