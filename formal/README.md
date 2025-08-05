# Formal Verification Directory

This directory contains formal verification configurations for the JTAG system.

## Current Status
- **Status**: ⚠️ NEEDS FIXING
- **Issue**: RTL code has multiple driver conflicts and clock polarity issues
- **Next Update**: Will fix RTL issues and complete formal verification setup

## Files
- `jtag_controller.sby` - Main JTAG controller formal verification configuration
- `jtag_controller_props.sv` - Properties and assertions for JTAG controller
- `simple_jtag.sby` - Simplified JTAG formal verification configuration  
- `simple_jtag_props.sv` - Properties for simplified JTAG verification

## Known Issues
1. Multiple conflicting drivers for `error_code` signals
2. Clock polarity conflicts in RTL design
3. Need to run `clk2fflogic` transformation

## Usage (After Fixes)
```bash
cd formal
sby -f jtag_controller.sby prove    # Run formal proof
sby -f jtag_controller.sby cover    # Run coverage analysis
```

## TODO for Next Update
- [ ] Fix multiple driver conflicts in RTL
- [ ] Resolve clock polarity issues
- [ ] Add proper clock domain handling
- [ ] Complete formal property specifications
- [ ] Add comprehensive assertions