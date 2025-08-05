# Design Specifications

## JTAG Controller (IEEE 1149.1)

### Description
The JTAG Controller implements a standard IEEE 1149.1 Test Access Port (TAP) controller with a complete state machine and instruction/data register handling. It serves as the primary interface for test access and boundary scan operations.

### Features
- Complete 16-state TAP controller state machine
- Support for both TMS-based and external reset
- Instruction register with standard instructions
- Bypass register for efficient scan chains
- State indicators for debugging and verification

### Interface
```verilog
module jtag_controller (
    input wire tck,         // Test Clock
    input wire tms,         // Test Mode Select
    input wire tdi,         // Test Data In
    output wire tdo,        // Test Data Out
    output wire trst_n_out, // Test Reset (active low) output
    
    // TAP state outputs
    output reg [3:0] state, // Current state of the JTAG state machine
    
    // State indicator outputs
    output wire test_logic_reset_state,
    output wire run_test_idle_state,
    output wire select_dr_scan_state,
    output wire capture_dr_state,
    output wire shift_dr_state,
    output wire exit1_dr_state,
    output wire pause_dr_state,
    output wire exit2_dr_state,
    output wire update_dr_state,
    output wire select_ir_scan_state,
    output wire capture_ir_state,
    output wire shift_ir_state,
    output wire exit1_ir_state,
    output wire pause_ir_state,
    output wire exit2_ir_state,
    output wire update_ir_state,
    
    // Instruction register
    output reg [3:0] ir_reg, // Instruction register

    // Optional external reset
    input wire ext_reset
);
```

### State Machine
The TAP controller implements the standard 16-state machine defined in IEEE 1149.1:
1. Test-Logic-Reset
2. Run-Test/Idle
3. Select-DR-Scan
4. Capture-DR
5. Shift-DR
6. Exit1-DR
7. Pause-DR
8. Exit2-DR
9. Update-DR
10. Select-IR-Scan
11. Capture-IR
12. Shift-IR
13. Exit1-IR
14. Pause-IR
15. Exit2-IR
16. Update-IR

### Instructions
- IDCODE (4'b0001): Device identification
- BYPASS (4'b1111): Bypass test data
- EXTEST (4'b0000): Test external circuitry
- SAMPLE (4'b0010): Sample/preload boundary scan chain

## Boundary Scan Chain

### Description
The boundary scan chain implements a shift register for boundary scan testing, allowing test patterns to be applied and captured at I/O pins.

### Features
- Serial shift register for scan operations
- Parallel load and capture capabilities
- Control signals for different scan operations

### Interface
```verilog
module boundary_scan_chain (
    input wire tck,
    input wire tdi,
    output wire tdo,
    input wire [3:0] control, // control signals for scan cells
    input wire [7:0] data_in, // parallel input data
    output wire [7:0] data_out // parallel output data
);
```

## IEEE 1500 Wrapper

### Description
The IEEE 1500 wrapper provides a standardized interface for core-level testing, isolating the core from surrounding logic during test operations.

### Features
- Wrapper Instruction Register (WIR) with standard instructions
- Wrapper Boundary Register (WBR) for core isolation
- Support for various test modes (EXTEST, INTEST, BYPASS, etc.)
- Serial and parallel test interfaces

### Interface
```verilog
module ieee1500_wrapper (
    // IEEE 1500 Wrapper Serial Interface
    input  wire        wrstn,       // Wrapper reset (active low)
    input  wire        wrck,        // Wrapper clock
    input  wire        wsi,         // Wrapper serial input
    output wire        wso,         // Wrapper serial output
    input  wire        selectwir,   // Select wrapper instruction register
    input  wire        capturewir,  // Capture to wrapper instruction register
    input  wire        shiftwir,    // Shift wrapper instruction register
    input  wire        updatewir,   // Update wrapper instruction register
    input  wire        selectwdr,   // Select wrapper data register
    input  wire        capturewdr,  // Capture to wrapper data register
    input  wire        shiftwdr,    // Shift wrapper data register
    input  wire        updatewdr,   // Update wrapper data register
    
    // Core Functional Interface
    input  wire [7:0]  core_inputs, // Inputs to the core
    output wire [7:0]  core_outputs // Outputs from the core
);
```

### Instructions
- BYPASS (3'b000): Bypass test data
- EXTEST (3'b001): Test external circuitry
- INTEST (3'b010): Test internal core logic
- SAMPLE (3'b011): Sample/preload boundary cells
- CLAMP (3'b100): Clamp outputs to fixed values

## IEEE 1687 Network

### Description
The IEEE 1687 network provides a reconfigurable scan network for accessing embedded instruments within the design.

### Features
- Segment Insertion Bits (SIBs) for reconfigurable scan paths
- Instrument selection and control capabilities
- Status capture for instrument data readback
- Integration with JTAG TAP controller

### Interface
```verilog
module ieee1687_network (
    // JTAG Interface
    input  wire        tck,         // Test Clock
    input  wire        tms,         // Test Mode Select
    input  wire        tdi,         // Test Data In
    output wire        tdo,         // Test Data Out
    input  wire        trst_n,      // Test Reset (active low)
    
    // TAP Controller State Inputs
    input  wire        capture_dr,  // Capture DR state
    input  wire        shift_dr,    // Shift DR state
    input  wire        update_dr,   // Update DR state
    
    // Instruction Register
    input  wire [3:0]  ir,          // Current instruction register value
    
    // Instrument Interface
    output wire [7:0]  instr_data,  // Data to embedded instruments
    output wire [3:0]  instr_addr,  // Address to select instrument
    output wire        instr_enable, // Enable signal for instruments
    input  wire [7:0]  instr_status  // Status from embedded instruments
);
```

### Instructions
- BYPASS (4'b0000): Bypass test data
- IDCODE (4'b0001): Device identification
- IJTAG_ACCESS (4'b1000): Access IEEE 1687 network

## Top Module

### Description
The top module integrates the JTAG controller, IEEE 1500 wrapper, and IEEE 1687 network into a complete test infrastructure.

### Features
- Mode selection based on JTAG instruction register
- Integration of all test components
- Loopback functionality for basic testing
- Complete test infrastructure for complex designs

### Interface
```verilog
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
```

### Integration
The top module integrates the components with the following connections:
1. JTAG TAP controller provides the primary interface and state machine
2. IEEE 1500 wrapper is selected through a dedicated instruction
3. IEEE 1687 network is selected through a dedicated instruction
4. TDO output is multiplexed based on the selected mode
5. Core functionality is demonstrated via a loopback module