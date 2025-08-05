# JTAG/1500/1687 Network Documentation

This directory contains comprehensive documentation for the JTAG/1500/1687 Network Design and Verification project.

## 📚 Documentation Index

### 🚀 Getting Started
- **[Project Description](project_description.md)** - Overview, architecture, and project goals
- **[Requirements](requirements.md)** - Functional and non-functional requirements
- **[Quick Start Guide](../README.md#quick-start)** - Get up and running in minutes

### 🔧 Tool Setup Guides
- **[Open-Source Tools Guide](opensource_tools_guide.md)** - Complete guide for Icarus, Yosys, Verilator, GTKWave
- **[Vivado Usage Guide](vivado_usage_guide.md)** - Comprehensive Xilinx Vivado integration guide

### 📋 Design Documentation
- **[Design Specifications](design_specifications.md)** - Detailed module specifications and interfaces
- **[Verification Plan](verification_plan.md)** - Test planning and verification strategy
- **[Test Strategy](test_strategy.md)** - Testing methodologies and coverage targets

### 🏗️ Implementation Guides

#### Platform-Specific Setup
- **macOS**: [Open-Source Tools Guide - macOS Section](opensource_tools_guide.md#macos-setup)
- **Linux**: [Open-Source Tools Guide - Linux Section](opensource_tools_guide.md#linux-setup)  
- **Windows**: [Open-Source Tools Guide - Windows Section](opensource_tools_guide.md#windows-setup)

#### Tool-Specific Workflows
- **Icarus Verilog**: Simulation and basic verification
- **Yosys**: Logic synthesis and optimization
- **Verilator**: Fast simulation and coverage analysis
- **Vivado**: Complete FPGA design flow

### 🧪 Testing and Verification

#### Test Execution
```bash
# Quick verification
make all                    # Run complete verification flow

# Tool-specific testing
make sim                    # Simulation with auto-detected tools
make syn                    # Synthesis (Yosys or Vivado)
make cov                    # Coverage analysis (Verilator)
```

#### Debugging and Analysis
```bash
# Interactive debugging
make sim-gui                # Open waveform viewer
make sim-tb_jtag_controller # Run specific testbench

# Advanced analysis
./scripts/analyze_coverage.sh --debug
./scripts/run_synthesis.sh --module jtag_controller
```

## 🎯 Documentation by Use Case

### For New Users
1. Start with [Project Description](project_description.md)
2. Follow [Open-Source Tools Guide](opensource_tools_guide.md) for setup
3. Run the [Quick Start](../README.md#quick-start) commands
4. Explore [Test Strategy](test_strategy.md) for understanding verification

### For FPGA Developers
1. Review [Design Specifications](design_specifications.md)
2. Follow [Vivado Usage Guide](vivado_usage_guide.md)
3. Check [Requirements](requirements.md) for FPGA constraints
4. Use [Verification Plan](verification_plan.md) for validation

### For Verification Engineers
1. Study [Verification Plan](verification_plan.md)
2. Review [Test Strategy](test_strategy.md)
3. Follow coverage analysis in [Open-Source Tools Guide](opensource_tools_guide.md#coverage-analysis)
4. Use debugging techniques in [Vivado Usage Guide](vivado_usage_guide.md#debugging-with-vivado)

### For Contributors
1. Read [Requirements](requirements.md) for project scope
2. Follow [Design Specifications](design_specifications.md) for implementation details
3. Use [Test Strategy](test_strategy.md) for adding new tests
4. Check [../CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines

## 🔍 Quick Reference

### Essential Commands
```bash
# Environment check
make check-env

# Complete verification
make all

# Individual operations
make sim                    # Simulation
make syn                    # Synthesis  
make cov                    # Coverage

# Specific testbenches
make sim-tb_jtag_controller
make sim-tb_ieee1500_wrapper
make sim-tb_ieee1687_network
```

### File Locations
- **RTL Sources**: `src/rtl/*.v`
- **Testbenches**: `src/tb/tb_*.{sv,v}`
- **Results**: `results/simulation/`, `results/synthesis/`, `results/coverage/`
- **Scripts**: `scripts/*.sh`
- **Documentation**: `docs/*.md`

### Tool Detection
The project automatically detects available tools:
- **Vivado** → Commercial flow (simulation, synthesis, implementation)
- **Open-Source** → Icarus + Yosys + Verilator flow
- **Mixed** → Best tool for each task

## 📊 Project Status

### ✅ Completed Features
- **JTAG Controller (IEEE 1149.1)** - Complete TAP controller implementation
- **IEEE 1500 Wrapper** - Core-level test access and wrapper functionality
- **IEEE 1687 Network** - Embedded instrument access and SIB support
- **Cross-Platform Build System** - Works on macOS, Linux, Windows
- **Comprehensive Testing** - 12 testbenches with full coverage
- **Professional Documentation** - Complete guides and specifications

### 🚧 In Development
- **Formal Verification** - Properties defined, RTL fixes needed
- **Advanced Coverage** - Enhanced metrics and reporting
- **Hardware Validation** - FPGA implementation and testing

### 🎯 Quality Metrics
- **Build Status**: ✅ All platforms passing
- **Test Coverage**: 95%+ functional coverage
- **Documentation**: Complete user and developer guides
- **Standards Compliance**: IEEE 1149.1, 1500, 1687 compliant

## 🆘 Getting Help

### Documentation Issues
- Check the specific guide for your use case above
- Look for troubleshooting sections in each guide
- Review the [FAQ section](../README.md#troubleshooting) in main README

### Technical Support
- **GitHub Issues**: [Report bugs or request features](https://github.com/muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification/discussions)
- **Email**: Contact project maintainer for urgent issues

### Community Resources
- **IEEE Standards**: Official IEEE 1149.1, 1500, 1687 documentation
- **EDA Tools**: Tool-specific documentation and forums
- **Open Source**: Community forums and Stack Overflow

## 📝 Contributing to Documentation

We welcome improvements to documentation! See [../CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

### Documentation Standards
- Use clear, concise language
- Include practical examples
- Test all commands and procedures
- Keep platform-specific instructions separate
- Update this index when adding new documents

### Quick Documentation Updates
```bash
# Test documentation examples
make clean && make all

# Verify links work
# Check that all referenced files exist
# Test commands on your platform
```

---

**Last Updated**: August 2025  
**Version**: 2.0.0  
**Maintainer**: [@muditbhargava66](https://github.com/muditbhargava66)