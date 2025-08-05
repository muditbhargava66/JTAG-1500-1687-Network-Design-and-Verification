# Vivado Usage Guide

This guide provides comprehensive instructions for using the JTAG/1500/1687 Network project with Xilinx Vivado Design Suite.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Vivado Setup](#vivado-setup)
- [Running Simulations](#running-simulations)
- [Synthesis and Implementation](#synthesis-and-implementation)
- [Debugging with Vivado](#debugging-with-vivado)
- [Advanced Features](#advanced-features)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Vivado Installation
- **Vivado Design Suite 2023.1 or later** (recommended)
- **Minimum**: Vivado WebPACK (free version)
- **Recommended**: Vivado Standard or Enterprise for full features

### System Requirements
- **OS**: Linux (RHEL/CentOS 7+, Ubuntu 18.04+) or Windows 10/11
- **RAM**: 8GB minimum, 16GB+ recommended
- **Disk**: 100GB+ free space for Vivado installation
- **CPU**: Multi-core processor recommended

### Installation Verification
```bash
# Check Vivado installation
vivado -version

# Expected output:
# Vivado v2023.1 (64-bit)
# SW Build 3865809 on Sun May  7 15:04:56 MDT 2023
```

## Vivado Setup

### Environment Configuration

1. **Source Vivado Settings** (Linux/macOS):
```bash
# Add to your ~/.bashrc or ~/.zshrc
source /tools/Xilinx/Vivado/2023.1/settings64.sh

# Or source manually each session
source /opt/Xilinx/Vivado/2023.1/settings64.sh
```

2. **Windows Setup**:
```cmd
# Use Vivado Command Prompt or add to PATH
"C:\Xilinx\Vivado\2023.1\bin\vivado.bat"
```

3. **Verify Environment**:
```bash
# Check if Vivado is in PATH
which vivado

# Test project detection
make check-env
```

### Project Configuration

The project automatically detects Vivado and configures appropriate settings:

```bash
# Check tool detection
make check-env

# Expected output with Vivado:
# ✓ vivado found
# ✓ Using commercial tool flow
```

## Running Simulations

### Basic Simulation Commands

```bash
# Run all simulations with Vivado
make sim

# Run specific testbench
make sim-tb_jtag_controller
make sim-tb_ieee1500_wrapper
make sim-tb_ieee1687_network

# Run with GUI (opens Vivado simulator)
make sim-gui
```

### Vivado-Specific Simulation

```bash
# Use Vivado simulator directly
./scripts/run_simulation.sh --tool vivado

# Run with specific testbench
./scripts/run_simulation.sh --tool vivado --testbench tb_jtag_controller

# Enable debug mode
./scripts/run_simulation.sh --tool vivado --debug
```

### Simulation Workflow

1. **Compilation Phase**:
   - Vivado compiles all RTL and testbench files
   - Creates simulation snapshot
   - Generates elaborated design

2. **Simulation Phase**:
   - Runs behavioral simulation
   - Generates waveform database (.wdb files)
   - Produces simulation logs

3. **Results**:
   - Waveforms: `results/simulation/waveforms/*.wdb`
   - Logs: `results/simulation/logs/*.log`

### Example Simulation Output

```bash
$ make sim-tb_jtag_controller

[INFO] Using Vivado for simulation
[INFO] Compiling RTL files...
[INFO] Compiling testbench: tb_jtag_controller
[INFO] Elaborating design...
[INFO] Running simulation...
[INFO] Simulation completed successfully
[INFO] Waveform: results/simulation/waveforms/tb_jtag_controller.wdb
```

## Synthesis and Implementation

### Basic Synthesis

```bash
# Run synthesis with Vivado
make syn

# Synthesize specific module
./scripts/run_synthesis.sh --module top_module --tool vivado
```

### Advanced Synthesis Options

```bash
# Synthesis with timing constraints
./scripts/run_synthesis.sh --tool vivado --constraints timing.xdc

# Synthesis for specific FPGA part
./scripts/run_synthesis.sh --tool vivado --part xc7a35tcpg236-1

# Enable optimization
./scripts/run_synthesis.sh --tool vivado --optimize
```

### Implementation Flow

1. **Synthesis**:
   ```bash
   # Full synthesis flow
   make syn
   ```

2. **Place and Route**:
   ```bash
   # Run implementation (if supported)
   ./scripts/run_synthesis.sh --tool vivado --implement
   ```

3. **Generate Bitstream**:
   ```bash
   # Generate programming file
   ./scripts/run_synthesis.sh --tool vivado --bitstream
   ```

### Synthesis Reports

After synthesis, check these reports:
- **Utilization**: `results/synthesis/reports/utilization.rpt`
- **Timing**: `results/synthesis/reports/timing_summary.rpt`
- **Power**: `results/synthesis/reports/power.rpt`

## Debugging with Vivado

### Waveform Analysis

1. **Open Vivado GUI**:
```bash
# Launch Vivado with project
vivado results/simulation/vivado_project/jtag_project.xpr
```

2. **Load Waveform Database**:
```tcl
# In Vivado TCL console
open_wave_database results/simulation/waveforms/tb_jtag_controller.wdb
```

3. **Add Signals to Waveform**:
```tcl
# Add all signals from testbench
add_wave -r /tb_jtag_controller/*

# Add specific signals
add_wave /tb_jtag_controller/uut/current_state
add_wave /tb_jtag_controller/uut/tck
add_wave /tb_jtag_controller/uut/tdi
add_wave /tb_jtag_controller/uut/tdo
```

### Interactive Debugging

1. **Set Breakpoints**:
```tcl
# Set breakpoint at specific time
add_bp -time 1000ns

# Set conditional breakpoint
add_bp -condition {current_state == 4'b0001}
```

2. **Step Through Simulation**:
```tcl
# Run to next breakpoint
run

# Step one clock cycle
step

# Run for specific time
run 100ns
```

### Logic Analyzer Integration

For hardware debugging with Vivado ILA (Integrated Logic Analyzer):

1. **Add ILA to Design**:
```verilog
// In your RTL
ila_0 ila_inst (
    .clk(tck),
    .probe0(current_state),
    .probe1(tdi),
    .probe2(tdo),
    .probe3(instruction_register)
);
```

2. **Generate and Program Bitstream**:
```bash
# Synthesize with ILA
make syn

# Program FPGA (if hardware available)
vivado -mode batch -source scripts/program_fpga.tcl
```

## Advanced Features

### Custom TCL Scripts

The project includes Vivado-specific TCL scripts in `scripts/Vivado/`:

1. **Simulation Script** (`vivado_sim.tcl`):
```tcl
# Custom simulation flow
source scripts/Vivado/vivado_sim.tcl
run_vivado_simulation tb_jtag_controller
```

2. **Synthesis Script** (`vivado_syn.tcl`):
```tcl
# Custom synthesis flow
source scripts/Vivado/vivado_syn.tcl
run_vivado_synthesis top_module
```

### Constraint Files

Create timing constraints for your design:

```tcl
# timing_constraints.xdc
create_clock -period 10.0 [get_ports tck]
set_input_delay -clock tck 2.0 [get_ports tdi]
set_output_delay -clock tck 2.0 [get_ports tdo]
```

### IP Integration

For using Xilinx IP cores:

1. **Create IP**:
```tcl
# In Vivado TCL console
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name clk_gen
```

2. **Integrate in Design**:
```verilog
// Instantiate IP in your RTL
clk_gen clk_generator (
    .clk_in1(sys_clk),
    .clk_out1(tck),
    .reset(reset),
    .locked(pll_locked)
);
```

## Performance Optimization

### Simulation Performance

1. **Use Compiled Libraries**:
```bash
# Compile Xilinx simulation libraries
compile_simlib -simulator xsim -directory sim_libs
```

2. **Enable Multi-threading**:
```tcl
# In simulation TCL script
set_param simulator.enableMultiThreading true
```

### Synthesis Optimization

1. **Timing-Driven Synthesis**:
```tcl
# Enable timing optimization
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE TimingOptimized [get_runs synth_1]
```

2. **Resource Optimization**:
```tcl
# Optimize for area
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AreaOptimized_high [get_runs synth_1]
```

## Troubleshooting

### Common Issues

1. **Vivado Not Found**:
```bash
# Check PATH
echo $PATH | grep -i vivado

# Source settings
source /opt/Xilinx/Vivado/2023.1/settings64.sh
```

2. **License Issues**:
```bash
# Check license
xlicmgr

# Set license server
export XILINXD_LICENSE_FILE=2100@license-server
```

3. **Simulation Failures**:
```bash
# Check simulation logs
cat results/simulation/logs/tb_jtag_controller_compile.log
cat results/simulation/logs/tb_jtag_controller_sim.log
```

4. **Memory Issues**:
```bash
# Increase memory limit
export VIVADO_MEM_LIMIT=8192  # 8GB
```

### Debug Commands

```bash
# Verbose simulation
./scripts/run_simulation.sh --tool vivado --debug --verbose

# Check Vivado version compatibility
vivado -version

# Test basic functionality
vivado -mode batch -source scripts/test_vivado.tcl
```

### Performance Issues

1. **Slow Simulation**:
   - Use compiled simulation libraries
   - Reduce simulation time in testbenches
   - Enable multi-threading

2. **Large Memory Usage**:
   - Limit waveform capture
   - Use selective signal recording
   - Close unused Vivado windows

### Getting Help

1. **Vivado Documentation**:
   - UG835: Vivado Design Suite TCL Command Reference
   - UG900: Vivado Design Suite User Guide: Logic Simulation
   - UG901: Vivado Design Suite User Guide: Synthesis

2. **Project-Specific Help**:
```bash
# Show available make targets
make help

# Show script options
./scripts/run_simulation.sh --help
./scripts/run_synthesis.sh --help
```

3. **Community Resources**:
   - Xilinx Community Forums
   - Project GitHub Issues
   - Vivado User Guide documentation

## Best Practices

### Project Organization
- Keep constraint files in `constraints/` directory
- Use version control for TCL scripts
- Document custom IP configurations

### Simulation Best Practices
- Use appropriate time units in testbenches
- Include proper reset sequences
- Add assertions for protocol compliance

### Synthesis Best Practices
- Use proper clock domain crossing techniques
- Add timing constraints for all clocks
- Review synthesis warnings carefully

### Version Control
- Add `*.jou`, `*.log`, `*.str` to `.gitignore`
- Don't commit generated IP files
- Version control constraint files and TCL scripts

This guide should help you effectively use Vivado with the JTAG/1500/1687 Network project. For additional help, refer to the project documentation or open an issue on GitHub.