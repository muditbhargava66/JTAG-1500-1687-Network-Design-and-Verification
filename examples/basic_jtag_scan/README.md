# Basic JTAG Boundary Scan Example

This example demonstrates fundamental JTAG operations including:
- TAP controller state machine transitions
- Instruction register loading
- Data register operations
- Boundary scan chain access

## 🎯 Learning Objectives

After running this example, you'll understand:
- How JTAG state machine transitions work
- Standard JTAG instructions (IDCODE, BYPASS, EXTEST)
- Boundary scan register operations
- Timing requirements for JTAG operations

## 🚀 Running the Example

```bash
# From project root
make sim-tb_jtag_controller

# View waveforms
gtkwave results/simulation/waveforms/tb_jtag_controller.vcd
```

## 📊 Expected Behavior

### State Machine Transitions
The testbench exercises all 16 JTAG states:
1. **Test-Logic-Reset** → **Run-Test/Idle**
2. **Run-Test/Idle** → **Select-DR-Scan** → **Capture-DR**
3. **Capture-DR** → **Shift-DR** (data shifting)
4. **Shift-DR** → **Exit1-DR** → **Update-DR**

### Instruction Testing
- **IDCODE** (0001): Returns device identification
- **BYPASS** (1111): Single-bit bypass register
- **EXTEST** (0000): External boundary scan test
- **SAMPLE** (0010): Sample boundary scan values

## 🔍 Key Waveform Signals

When viewing waveforms, focus on:
- `tck` - Test clock (should be clean, regular)
- `tms` - Test mode select (controls state transitions)
- `state[3:0]` - Current TAP controller state
- `ir_reg[3:0]` - Instruction register contents
- `tdo` - Test data output (shifted data)

## ✅ Success Criteria

The test passes when:
- All state transitions occur correctly
- Instruction register loads proper values
- Data shifts through registers as expected
- No timing violations or X states

## 🐛 Common Issues

**Problem**: State machine stuck in Test-Logic-Reset
- **Solution**: Check TMS signal timing and reset conditions

**Problem**: Instruction register not updating
- **Solution**: Verify Update-IR state is reached after shifting

**Problem**: Data corruption during shift
- **Solution**: Check setup/hold times relative to TCK edges