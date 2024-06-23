`timescale 1ns / 1ps

module jtag_controller (
    input wire tck,  // Test Clock
    input wire tms,  // Test Mode Select
    input wire tdi,  // Test Data In
    output wire tdo, // Test Data Out
    output reg [3:0] state // Current state of the JTAG state machine
);

    // JTAG state machine states
    localparam TEST_LOGIC_RESET = 4'b0000;
    localparam RUN_TEST_IDLE    = 4'b0001;
    localparam SELECT_DR_SCAN   = 4'b0010;
    localparam CAPTURE_DR       = 4'b0011;
    localparam SHIFT_DR         = 4'b0100;
    localparam EXIT1_DR         = 4'b0101;
    localparam PAUSE_DR         = 4'b0110;
    localparam EXIT2_DR         = 4'b0111;
    localparam UPDATE_DR        = 4'b1000;
    localparam SELECT_IR_SCAN   = 4'b1001;
    localparam CAPTURE_IR       = 4'b1010;
    localparam SHIFT_IR         = 4'b1011;
    localparam EXIT1_IR         = 4'b1100;
    localparam PAUSE_IR         = 4'b1101;
    localparam EXIT2_IR         = 4'b1110;
    localparam UPDATE_IR        = 4'b1111;

    // JTAG state machine
    always @(posedge tck or posedge tms) begin
        if (tms) begin
            state <= TEST_LOGIC_RESET;
        end else begin
            case (state)
                TEST_LOGIC_RESET: state <= RUN_TEST_IDLE;
                RUN_TEST_IDLE:    state <= (tms) ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                SELECT_DR_SCAN:   state <= (tms) ? SELECT_IR_SCAN : CAPTURE_DR;
                CAPTURE_DR:       state <= (tms) ? EXIT1_DR : SHIFT_DR;
                SHIFT_DR:         state <= (tms) ? EXIT1_DR : SHIFT_DR;
                EXIT1_DR:         state <= (tms) ? UPDATE_DR : PAUSE_DR;
                PAUSE_DR:         state <= (tms) ? EXIT2_DR : PAUSE_DR;
                EXIT2_DR:         state <= (tms) ? UPDATE_DR : SHIFT_DR;
                UPDATE_DR:        state <= (tms) ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                SELECT_IR_SCAN:   state <= (tms) ? TEST_LOGIC_RESET : CAPTURE_IR;
                CAPTURE_IR:       state <= (tms) ? EXIT1_IR : SHIFT_IR;
                SHIFT_IR:         state <= (tms) ? EXIT1_IR : SHIFT_IR;
                EXIT1_IR:         state <= (tms) ? UPDATE_IR : PAUSE_IR;
                PAUSE_IR:         state <= (tms) ? EXIT2_IR : PAUSE_IR;
                EXIT2_IR:         state <= (tms) ? UPDATE_IR : SHIFT_IR;
                UPDATE_IR:        state <= (tms) ? SELECT_DR_SCAN : RUN_TEST_IDLE;
                default:          state <= TEST_LOGIC_RESET;
            endcase
        end
    end

    assign tdo = tdi; // For simplicity, loop TDI to TDO in this example

endmodule
