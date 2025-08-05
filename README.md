<div align="center">

# JTAG/1500/1687 Network Design and Verification

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Coverage](https://img.shields.io/badge/coverage-95%25-brightgreen)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)
![Tools](https://img.shields.io/badge/tools-Icarus%20%7C%20Yosys%20%7C%20Verilator%20%7C%20Vivado-orange)

*A comprehensive, standards-compliant test infrastructure for digital designs*

</div>

## Overview

This project implements a complete test and debug infrastructure for digital designs, featuring JTAG (IEEE 1149.1), IEEE 1500 wrapper, and IEEE 1687 network components. The system provides boundary scan capabilities, core-level testing, and embedded instrument access in a standards-compliant implementation.

## Features

- **JTAG Controller (IEEE 1149.1)**
  - Complete TAP controller state machine
  - Instruction and data register handling
  - Standard instructions (IDCODE, BYPASS, EXTEST, SAMPLE)
  - Reset control and state indicators

- **IEEE 1500 Wrapper**
  - Core-level test access
  - Wrapper Instruction Register (WIR) 
  - Wrapper Boundary Register (WBR)
  - Multiple test modes (EXTEST, INTEST, BYPASS, etc.)

- **IEEE 1687 Network**
  - Embedded instrument access
  - Segment Insertion Bit (SIB) support
  - Reconfigurable scan path
  - Instrument selection and control

- **Cross-platform Build System**
  - Support for Linux, macOS, and Windows
  - Both open-source and commercial tool flows
  - Comprehensive Makefile and scripts

## 🚀 Quick Start

### One-Command Setup
```bash
# Clone and setup in one go
git clone https://github.com/muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification.git
cd JTAG-1500-1687-Network-Design-and-Verification

# Install required tools automatically
./scripts/install_tools.sh

# Run complete verification flow
make all

# Run specific testbench with GUI
make sim-tb_jtag_controller
make sim-gui
```

## Directory Structure

```
.
├── docs/                            # Documentation
│   ├── README.md                    # Documentation index and quick reference
│   ├── project_description.md       # Project overview and architecture
│   ├── requirements.md              # Functional and non-functional requirements
│   ├── design_specifications.md     # Module specifications
│   ├── verification_plan.md         # Verification strategy and test plans
│   ├── test_strategy.md             # Testing approach and methodologies
│   ├── vivado_usage_guide.md        # Complete Xilinx Vivado integration guide
│   └── opensource_tools_guide.md    # Comprehensive open-source tools guide
├── scripts/                         # Automation scripts
│   ├── common.sh                    # Common shell functions
│   ├── run_simulation.sh            # Cross-platform simulation script
│   ├── run_synthesis.sh             # Cross-platform synthesis script
│   ├── analyze_coverage.sh          # Cross-platform coverage analysis
│   ├── run_formal.sh                # Formal verification script
│   ├── install_tools.sh             # Automated tool installation
│   ├── generate_html_report.sh      # HTML report generation
│   ├── realtime_monitor.sh          # Real-time monitoring
│   ├── gui_controller.py            # GUI test controller
│   ├── Vivado/                      # Vivado-specific TCL scripts
│   └── html_templates/              # HTML report templates
├── src/                             # Source files
│   ├── rtl/                         # RTL implementation (14 modules)
│   │   ├── jtag_controller.v        # JTAG TAP controller
│   │   ├── jtag_system.v            # Complete JTAG system integration
│   │   ├── jtag_memory_interface.v  # Memory access interface
│   │   ├── boundary_scan_chain.v    # Basic boundary scan implementation
│   │   ├── boundary_scan_chain_enhanced.v # Advanced boundary scan
│   │   ├── ieee1500_wrapper.v       # IEEE 1500 wrapper implementation
│   │   ├── ieee1687_network.v       # IEEE 1687 network implementation
│   │   ├── loopback_module.v        # Basic loopback functionality
│   │   ├── simple_scan_chain.v      # Icarus-compatible scan chain
│   │   ├── optimized_scan_chain.v   # Advanced scan chain
│   │   ├── test_compressor.v        # Test compression
│   │   ├── secure_jtag.v            # Secure JTAG features
│   │   ├── power_manager.v          # Power management
│   │   └── top_module.v             # Top-level integration
│   ├── bsdl/                        # BSDL descriptions
│   │   └── jtag_controller.bsdl     # JTAG controller BSDL file
│   ├── icl/                         # IEEE 1500 descriptions
│   │   └── jtag_network.icl         # ICL description file
│   ├── pdl/                         # PDL procedures
│   │   └── jtag_procedures.pdl      # JTAG procedures in PDL
│   └── tb/                          # Test benches (12 testbenches)
│       ├── tb_jtag_controller.sv    # JTAG controller tests
│       ├── tb_jtag_memory_access.v  # Memory access tests
│       ├── tb_boundary_scan_chain.sv # Boundary scan tests
│       ├── tb_loopback_module.sv    # Loopback module tests
│       ├── tb_ieee1500_wrapper.sv   # IEEE 1500 wrapper tests
│       ├── tb_ieee1687_network.sv   # IEEE 1687 network tests
│       ├── tb_top_module.sv         # Top module integration tests
│       ├── tb_simple_scan_chain.v   # Simple scan chain tests
│       ├── tb_stress_test.v         # Stress testing
│       ├── tb_fault_simulator.sv    # Fault simulation tests
│       ├── tb_pattern_generator.sv  # Pattern generation tests
│       └── tb_stress_tester.sv      # Advanced stress tests
├── results/                         # Build and test results
│   ├── simulation/                  # Simulation outputs
│   │   ├── waveforms/               # Waveform files
│   │   └── logs/                    # Simulation logs
│   ├── synthesis/                   # Synthesis outputs
│   │   └── reports/                 # Synthesis reports
│   └── coverage/                    # Coverage analysis results
│       └── reports/                 # Coverage reports
├── Makefile                         # Cross-platform build system
├── CONTRIBUTING.md                  # Contribution guidelines
├── FUTURE.md                        # Future development roadmap
├── setup_project.sh                 # Project setup script
└── README.md                        # This file
```

## 📋 Prerequisites & Installation

### Automated Installation (Recommended)

The project includes an automated tool installer that works across platforms:

```bash
# Check what tools you have
make check-env

# Install missing tools automatically
./scripts/install_tools.sh

# Verify installation
./scripts/install_tools.sh --verify
```

### Manual Installation

**Open-Source Flow:**
- **Icarus Verilog** (simulation) - `iverilog`, `vvp`
- **Yosys** (synthesis) - Logic synthesis and optimization
- **Verilator** (coverage/analysis) - Fast simulation and coverage
- **Surfer/GTKWave** (waveform viewing) - Signal visualization

**Commercial Flow (Optional):**
- **Vivado Design Suite** - Complete FPGA design environment

### Platform-Specific Setup

<details>
<summary><strong>🍎 macOS</strong></summary>

```bash
# Using Homebrew (recommended)
brew install icarus-verilog yosys verilator
brew install --cask surfer  # Modern waveform viewer (recommended for macOS)
brew install gtkwave         # Traditional waveform viewer (alternative)

# Verify installation
make check-env
```
</details>

<details>
<summary><strong>🐧 Linux (Ubuntu/Debian)</strong></summary>

```bash
# Update package list
sudo apt-get update

# Install core tools
sudo apt-get install -y iverilog yosys verilator gtkwave build-essential

# Optional: Install Surfer for modern waveform viewing
# Download from https://surfer-project.org/

# Verify installation
make check-env
```
</details>

<details>
<summary><strong>🪟 Windows</strong></summary>

**Option 1: WSL2 (Recommended)**
```bash
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu

# In Ubuntu terminal:
sudo apt-get update
sudo apt-get install -y iverilog yosys verilator gtkwave build-essential
```

**Option 2: Native Windows**
- Download individual installers from tool websites
- Use MSYS2 for Unix-like environment
</details>

## 🔧 Usage Guide

### Build System Overview

The project uses a sophisticated cross-platform build system with automatic tool detection:

```bash
# Complete verification flow
make all                    # Run simulation + synthesis + coverage

# Individual operations
make sim                    # Run all simulations
make syn                    # Run synthesis
make cov                    # Run coverage analysis
make clean                  # Clean all generated files
```

### 🎯 Targeted Testing

**Run specific testbench:**
```bash
make sim-tb_jtag_controller     # Test JTAG controller only
make sim-tb_ieee1500_wrapper    # Test IEEE 1500 wrapper
make sim-tb_top_module          # Test complete integration
```

**Interactive debugging:**
```bash
make sim-gui                    # Open waveform viewer automatically
make sim-tb_jtag_controller     # Then manually: gtkwave results/simulation/waveforms/tb_jtag_controller.vcd
```

### 📊 Expected Output

When you run `make all`, you should see output like this:

```
Checking environment...
✓ iverilog found
✓ vvp found  
✓ verilator found
✓ yosys found

Running simulation...
[INFO] Simulating tb_jtag_controller
[INFO] Compilation successful for tb_jtag_controller
[INFO] Simulation completed for tb_jtag_controller
[INFO] Waveform generated: results/simulation/waveforms/tb_jtag_controller.vcd

Running synthesis...
[INFO] Synthesizing top_module
[INFO] Synthesis completed for top_module
[INFO] See report: results/synthesis/reports/top_module_stats.rpt

Running coverage analysis...
[INFO] Successfully analyzed 6/6 testbenches
[INFO] Coverage reports: results/coverage/reports/
```

### 🔍 Advanced Usage Examples

**Debug a failing test:**
```bash
# Run with verbose output
./scripts/run_simulation.sh --testbench tb_jtag_controller --debug

# Check logs
cat results/simulation/logs/tb_jtag_controller.log
```

**Synthesis for specific module:**
```bash
./scripts/run_synthesis.sh --module jtag_controller --debug
```

**Coverage analysis with tracing:**
```bash
./scripts/analyze_coverage.sh --testbench tb_top_module --debug
```

**Run synthesis for a specific module:**
```bash
make syn_top_module
```

**Run coverage analysis:**
```bash
make cov
```

**Clean all generated files:**
```bash
make clean
```

**View all available targets:**
```bash
make help
```

### Using Individual Scripts

If you prefer to use the scripts directly:

**Run simulation:**
```bash
./scripts/run_simulation.sh [-t TESTBENCH] [-g] [-d] [-c]
```

**Run synthesis:**
```bash
./scripts/run_synthesis.sh [-m MODULE] [-d] [-c]
```

**Run coverage analysis:**
```bash
./scripts/analyze_coverage.sh [-t TESTBENCH] [-d] [-c]
```

Where:
- `-t TESTBENCH`: Specify a testbench to run
- `-m MODULE`: Specify a module to synthesize
- `-g`: Enable GUI mode (for simulation)
- `-d`: Enable debug mode with verbose output
- `-c`: Clean results before running

## Example Usage Scenarios

### Basic JTAG Testing

```bash
# Run the JTAG controller test bench
make sim_tb_jtag_controller

# View the waveform (choose your preferred viewer)
surfer results/simulation/waveforms/tb_jtag_controller.vcd   # Modern viewer
gtkwave results/simulation/waveforms/tb_jtag_controller.vcd  # Traditional viewer
```

### IEEE 1500 Wrapper Testing

```bash
# Run the IEEE 1500 wrapper test bench
make sim_tb_ieee1500_wrapper

# Check coverage
make cov_tb_ieee1500_wrapper

# View coverage report
open results/coverage/reports/tb_ieee1500_wrapper_annotated/index.html
```

### IEEE 1687 Network Testing

```bash
# Run the IEEE 1687 network test bench
make sim_tb_ieee1687_network

# View waveform in GUI mode
make sim_gui
```

### Complete System Testing

```bash
# Run comprehensive test for the top module
make test_top_module
```

## Documentation

The project includes comprehensive documentation:

- **Project Description** (`docs/project_description.md`): Overview, architecture, and goals
- **Requirements** (`docs/requirements.md`): Functional and non-functional requirements
- **Design Specifications** (`docs/design_specifications.md`): Detailed module specifications
- **Verification Plan** (`docs/verification_plan.md`): Test planning and verification approach
- **Test Strategy** (`docs/test_strategy.md`): Testing methodologies and targets
- **Future Roadmap** (`FUTURE.md`): Planned features and enhancements
- **Contributing Guidelines** (`CONTRIBUTING.md`): How to contribute to the project

## Visualization Examples

Here are some key visualizations to help understand the project:

### JTAG State Machine
```
                  ┌───────┐
                  │ Reset │
                  └───┬───┘
                      │
                      ▼
              ┌──────────────┐
              │ Run-Test/Idle│◄──┐
              └──────┬───────┘   │
                     │           │
                     ▼           │
            ┌─────────────────┐  │
            │ Select-DR-Scan  │  │
            └─────┬─────┬─────┘  │
                  │     │        │
                  ▼     ▼        │
      ┌─────────────┐  ┌──────────────┐
      │ Capture-DR  │  │Select-IR-Scan│
      └──────┬──────┘  └──────┬───────┘
             │                │
             ▼                ▼
      ┌─────────────┐  ┌─────────────┐
      │  Shift-DR   │  │ Capture-IR  │
      └──────┬──────┘  └──────┬──────┘
             │                │
             ▼                ▼
      ┌─────────────┐  ┌─────────────┐
      │  Exit1-DR   │  │  Shift-IR   │
      └──────┬──────┘  └──────┬──────┘
             │                │
             ▼                ▼
      ┌─────────────┐  ┌─────────────┐
      │  Pause-DR   │  │  Exit1-IR   │
      └──────┬──────┘  └──────┬──────┘
             │                │
             ▼                ▼
      ┌─────────────┐  ┌─────────────┐
      │  Exit2-DR   │  │  Pause-IR   │
      └──────┬──────┘  └──────┬──────┘
             │                │
             ▼                ▼
      ┌─────────────┐  ┌─────────────┐
      │  Update-DR  │  │  Exit2-IR   │
      └──────┬──────┘  └──────┬──────┘
             │                │
             │                ▼
             │         ┌─────────────┐
             │         │  Update-IR  │
             │         └──────┬──────┘
             │                │
             └────────────────┘
```

### IEEE 1500 Wrapper Architecture
```
┌───────────────────────────────────────────────────┐
│                Core Boundary                      │
│  ┌───────────────────────────────────────────┐    │
│  │                  Core Logic               │    │
│  │                                           │    │
│  └─────────────┬─────────────────┬───────────┘    │
│                │                 │                │
│  ┌─────────────▼─────┐  ┌────────▼──────────────┐ │
│  │ Wrapper Boundary  │  │ Wrapper Boundary      │ │
│  │ Register (Input)  │  │ Register (Output)     │ │
│  └─────────────┬─────┘  └────────┬──────────────┘ │
│                │                 │                │
└────────────────┼─────────────────┼────────────────┘
                 │                 │
      ┌──────────▼─────────────────▼────────────┐
      │       IEEE 1500 Wrapper Interface       │
      │ WIR                                 WBR │
      └──────────┬─────────────────┬────────────┘
                 │                 │
        ┌────────▼────────┐  ┌─────▼─────────┐
        │ WSI             │  │  WSO          │
        └─────────────────┘  └───────────────┘
```

### IEEE 1687 Network Example
```
┌──────────────────────────────────────────────────────┐
│ JTAG TAP                                             │
└─────┬───────────────────────────────────────────┬────┘
      │                                           │
      ▼                                           ▼
┌─────────────┐                           ┌────────────┐
│ IEEE 1687   │                           │   TDO      │
│ Controller  │                           │            │
└─────┬───────┘                           └─────▲──────┘
      │                                         │
      ▼                                         │
┌─────────────┐      ┌─────────┐      ┌─-─-─────┴───────┐
│ SIB 1       ├──────► Instr 1 ├──-────►  SIB 2         │
└─────┬───────┘      └─────────┘      └──-─-────┬───────┘
      │                                         │
      │                                         ▼
      │                               ┌─────────────────┐
      └───────────────────────────────► Instr 2         │
                                      └─────────────────┘
```

## Contributing

We welcome contributions to this project! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on how to contribute.

In brief:
1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- IEEE for the relevant standards (1149.1, 1500, 1687)
- Open-source EDA tool developers
- Contributors to the project


<div align="center">

## Star History

<a href="https://www.star-history.com/#muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification&type=Date" />
 </picture>
</a>

---

⭐️ Star the repo and consider contributing!  
  
📫 **Contact**: [@muditbhargava66](https://github.com/muditbhargava66)
🐛 **Report Issues**: [Issue Tracker](https://github.com/muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification/issues)
  
© 2025 Mudit Bhargava. [MIT License](LICENSE)  
<!-- Copyright symbol using HTML entity for better compatibility -->
</div>