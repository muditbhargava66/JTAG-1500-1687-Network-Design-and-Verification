# JTAG/1500/1687 Network Examples

This directory contains practical examples demonstrating the capabilities of the JTAG/1500/1687 network implementation.

## 📁 Directory Structure

```
examples/
├── README.md                    # This file
├── basic_jtag_scan/            # Basic JTAG boundary scan example
├── ieee1500_core_test/         # IEEE 1500 wrapper testing example  
├── ieee1687_instrument_access/ # IEEE 1687 network configuration example
├── integration_demo/           # Complete system integration demo
├── synthesis_results/          # Example synthesis outputs
└── waveform_captures/          # Reference waveform files
```

## 🚀 Running Examples

### Quick Start
```bash
# Run all examples
make -C examples all

# Run specific example
make -C examples basic_jtag_scan
```

### Individual Examples

1. **Basic JTAG Scan** - Demonstrates fundamental JTAG operations
2. **IEEE 1500 Core Test** - Shows core-level testing capabilities  
3. **IEEE 1687 Instrument Access** - Illustrates embedded instrument control
4. **Integration Demo** - Complete system working together

## 📊 Expected Results

Each example includes:
- ✅ Expected simulation output
- 📈 Waveform captures showing correct operation
- 📋 Synthesis reports with resource utilization
- 🧪 Coverage metrics demonstrating thorough testing

## 🔧 Customization

Examples can be modified to:
- Test different instruction sequences
- Vary timing parameters
- Add custom instruments
- Integrate with your own cores

See individual example READMEs for detailed customization instructions.