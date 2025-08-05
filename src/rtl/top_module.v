`timescale 1ns / 1ps

/**
 * Top Module for JTAG/1500/1687 Network Design
 * 
 * This module integrates the JTAG controller, IEEE 1500 wrapper, and IEEE 1687 network
 * into a complete test infrastructure providing boundary scan capabilities,
 * core testing through IEEE 1500, and instrument access through IEEE 1687.
 */
module top_module (
    // Primary JTAG interface
    input  wire        tck,         // Test Clock
    input  wire        tms,         // Test Mode Select
    input  wire        tdi,         // Test Data In
    output wire        tdo,         // Test Data Out
    input  wire        trst_n,      // Test Reset (active low)
    
    // System interface
    input  wire        clk,         // System clock
    input  wire        reset,       // System reset
    
    // Loopback interface (for basic testing)
    input  wire [7:0]  loopback_data_in,
    output wire [7:0]  loopback_data_out,
    
    // Boundary scan interface
    input  wire [3:0]  bsc_control,
    input  wire [7:0]  bsc_data_in,
    output wire [7:0]  bsc_data_out,
    
    // Instrumentation interface
    output wire [7:0]  instrument_data,
    output wire [3:0]  instrument_addr,
    output wire        instrument_enable,
    input  wire [7:0]  instrument_status
);

    // Internal signals
    wire [3:0]  jtag_state;
    wire        tap_reset_n;
    wire [3:0]  ir_reg;
    
    // TAP controller state signals
    wire        test_logic_reset;
    wire        run_test_idle;
    wire        select_dr_scan;
    wire        capture_dr;
    wire        shift_dr;
    wire        exit1_dr;
    wire        pause_dr;
    wire        exit2_dr;
    wire        update_dr;
    wire        select_ir_scan;
    wire        capture_ir;
    wire        shift_ir;
    wire        exit1_ir;
    wire        pause_ir;
    wire        exit2_ir;
    wire        update_ir;
    
    // TDO from various modules
    wire        jtag_tdo;
    wire        bsc_tdo;
    wire        ieee1687_tdo;
    
    // IEEE 1500 Wrapper signals
    wire        wrstn;
    wire        wrck;
    wire        wsi;
    wire        wso;
    wire        selectwir;
    wire        capturewir;
    wire        shiftwir;
    wire        updatewir;
    wire        selectwdr;
    wire        capturewdr;
    wire        shiftwdr;
    wire        updatewdr;
    wire [7:0]  core_inputs;
    wire [7:0]  core_outputs;
    
    // JTAG to IEEE 1500 Adapter signals
    reg         use_1500;
    reg         use_1687;
    
    // JTAG Controller instance
    jtag_controller jtag_inst (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(jtag_tdo),
        .trst_n_out(tap_reset_n),
        .state(jtag_state),
        .ir_reg(ir_reg),
        .ext_reset(reset),
        
        // State indicators
        .test_logic_reset_state(test_logic_reset),
        .run_test_idle_state(run_test_idle),
        .select_dr_scan_state(select_dr_scan),
        .capture_dr_state(capture_dr),
        .shift_dr_state(shift_dr),
        .exit1_dr_state(exit1_dr),
        .pause_dr_state(pause_dr),
        .exit2_dr_state(exit2_dr),
        .update_dr_state(update_dr),
        .select_ir_scan_state(select_ir_scan),
        .capture_ir_state(capture_ir),
        .shift_ir_state(shift_ir),
        .exit1_ir_state(exit1_ir),
        .pause_ir_state(pause_ir),
        .exit2_ir_state(exit2_ir),
        .update_ir_state(update_ir)
    );
    
    // Boundary Scan Chain instance
    boundary_scan_chain bsc_inst (
        .tck(tck),
        .tdi(tdi),
        .tdo(bsc_tdo),
        .control(bsc_control),
        .data_in(bsc_data_in),
        .data_out(bsc_data_out)
    );
    
    // Loopback Module instance
    loopback_module loopback_inst (
        .clk(clk),
        .reset(reset),
        .data_in(loopback_data_in),
        .data_out(loopback_data_out)
    );
    
    // IEEE 1687 Network instance
    ieee1687_network ieee1687_inst (
        .tck(tck),
        .tms(tms),
        .tdi(tdi),
        .tdo(ieee1687_tdo),
        .trst_n(tap_reset_n),
        .capture_dr(capture_dr),
        .shift_dr(shift_dr),
        .update_dr(update_dr),
        .ir(ir_reg),
        .instr_data(instrument_data),
        .instr_addr(instrument_addr),
        .instr_enable(instrument_enable),
        .instr_status(instrument_status)
    );
    
    // IEEE 1500 mode detection based on IR
    always @(posedge tck or negedge tap_reset_n) begin
        if (!tap_reset_n) begin
            use_1500 <= 1'b0;
            use_1687 <= 1'b0;
        end else if (update_ir) begin
            // Decode IR to determine mode
            use_1500 <= (ir_reg == 4'b0100); // Example: IR = 4 for IEEE 1500 mode
            use_1687 <= (ir_reg == 4'b1000); // Example: IR = 8 for IEEE 1687 mode
        end
    end
    
    // IEEE 1500 Wrapper Control Signals Mapping
    assign wrstn = tap_reset_n;
    assign wrck = tck;
    assign wsi = tdi;
    assign selectwir = use_1500 && select_ir_scan;
    assign capturewir = use_1500 && capture_ir;
    assign shiftwir = use_1500 && shift_ir;
    assign updatewir = use_1500 && update_ir;
    assign selectwdr = use_1500 && select_dr_scan;
    assign capturewdr = use_1500 && capture_dr;
    assign shiftwdr = use_1500 && shift_dr;
    assign updatewdr = use_1500 && update_dr;
    
    // Core signals - in this example, we use loopback data as core I/O
    assign core_inputs = loopback_data_in;
    
    // IEEE 1500 Wrapper instance
    ieee1500_wrapper ieee1500_inst (
        .wrstn(wrstn),
        .wrck(wrck),
        .wsi(wsi),
        .wso(wso),
        .selectwir(selectwir),
        .capturewir(capturewir),
        .shiftwir(shiftwir),
        .updatewir(updatewir),
        .selectwdr(selectwdr),
        .capturewdr(capturewdr),
        .shiftwdr(shiftwdr),
        .updatewdr(updatewdr),
        .core_inputs(core_inputs),
        .core_outputs(core_outputs)
    );

    // TDO output multiplexing
    assign tdo = use_1500 ? wso :
                 use_1687 ? ieee1687_tdo :
                 jtag_tdo;

endmodule