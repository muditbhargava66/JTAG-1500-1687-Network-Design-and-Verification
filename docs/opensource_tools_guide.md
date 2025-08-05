# Open-Source Tools Usage Guide

This guide provides comprehensive instructions for using the JTAG/1500/1687 Network project with open-source EDA tools on macOS, Linux, and Windows.

## Table of Contents
- [Tool Overview](#tool-overview)
- [Installation Guide](#installation-guide)
- [macOS Setup](#macos-setup)
- [Linux Setup](#linux-setup)
- [Windows Setup](#windows-setup)
- [Usage Examples](#usage-examples)
- [Advanced Features](#advanced-features)
- [Troubleshooting](#troubleshooting)

## Tool Overview

The project supports a complete open-source EDA toolchain:

### Core Tools
- **Icarus Verilog** (`iverilog`, `vvp`) - Verilog simulation
- **Yosys** - Logic synthesis and optimization
- **Verilator** - Fast simulation and coverage analysis

### Waveform Viewers
- **Surfer** - Modern waveform viewer (recommended for macOS, available on all platforms)
- **GTKWave** - Traditional waveform viewer (cross-platform, but limited macOS support)

### Optional Tools
- **OpenSTA** - Static timing analysis
- **KLayout** - Layout viewer and editor

### Tool Capabilities Matrix

| Tool | Simulation | Synthesis | Coverage | Waveforms | macOS Native |
|------|------------|-----------|----------|-----------|-------------|
| Icarus Verilog | ✅ | ❌ | ❌ | ✅ | ✅ |
| Yosys | ❌ | ✅ | ❌ | ❌ | ✅ |
| Verilator | ✅ | ❌ | ✅ | ✅ | ✅ |
| Surfer | ❌ | ❌ | ❌ | ✅ | ✅ |
| GTKWave | ❌ | ❌ | ❌ | ✅ | ⚠️ |

## Installation Guide

### Automated Installation (Recommended)

The project includes an automated installer that works across platforms:

```bash
# Check current tool status
make check-env

# Install missing tools automatically
./scripts/install_tools.sh

# Verify installation
./scripts/install_tools.sh --verify
```

### Manual Installation

Choose your platform below for detailed manual installation instructions.

## macOS Setup

### Using Homebrew (Recommended)

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install core EDA tools
brew install icarus-verilog yosys verilator

# Install waveform viewers (choose one or both)
brew install --cask surfer   # Modern waveform viewer (recommended for macOS)
brew install gtkwave         # Traditional waveform viewer

# Install optional tools
brew install klayout         # Layout viewer

# Verify installation
make check-env
```

### Using MacPorts (Alternative)

```bash
# Install MacPorts tools
sudo port install iverilog yosys verilator gtkwave

# Note: Surfer is not available via MacPorts, use Homebrew or download directly

# Update PATH if needed
echo 'export PATH=/opt/local/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
```

### Manual Installation on macOS

If package managers don't work:

1. **Icarus Verilog**:
```bash
# Download and compile from source
git clone https://github.com/steveicarus/iverilog.git
cd iverilog
sh autoconf.sh
./configure --prefix=/usr/local
make
sudo make install
```

2. **Yosys**:
```bash
# Install dependencies
brew install bison flex libffi

# Clone and build
git clone https://github.com/YosysHQ/yosys.git
cd yosys
make config-clang
make -j$(nproc)
sudo make install
```

### macOS-Specific Configuration

```bash
# Add to ~/.zshrc or ~/.bash_profile
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

# For Apple Silicon Macs
export PATH="/opt/homebrew/bin:$PATH"

# Verify tools
which iverilog yosys verilator surfer gtkwave
```

### Waveform Viewer Recommendations for macOS

**Surfer (Recommended)**:
- Native macOS application with modern UI
- Better performance and integration
- Supports dark mode and macOS gestures
- Installation: `brew install --cask surfer`

**GTKWave (Alternative)**:
- Cross-platform but limited macOS integration
- May have display issues on newer macOS versions
- Installation: `brew install gtkwave`

## Linux Setup

### Ubuntu/Debian

```bash
# Update package database
sudo apt-get update

# Install core tools
sudo apt-get install -y iverilog yosys verilator gtkwave

# Install Surfer (modern waveform viewer) - download from website
# https://surfer-project.org/ - provides .deb packages for Ubuntu

# Install build dependencies
sudo apt-get install -y build-essential git cmake

# Install optional tools
sudo apt-get install -y klayout opensta

# Verify installation
make check-env
```

### RHEL/CentOS/Fedora

```bash
# For RHEL/CentOS (with EPEL)
sudo yum install -y epel-release
sudo yum install -y iverilog yosys verilator gtkwave

# For Fedora
sudo dnf install -y iverilog yosys verilator gtkwave

# Install development tools
sudo yum groupinstall -y "Development Tools"
# or for Fedora:
sudo dnf groupinstall -y "Development Tools"
```

### Arch Linux

```bash
# Install from official repositories
sudo pacman -S iverilog yosys verilator gtkwave

# Install AUR packages (optional)
yay -S opensta klayout
```

### Building from Source (Linux)

If packages aren't available:

```bash
# Install dependencies
sudo apt-get install -y build-essential git cmake bison flex libffi-dev

# Build Icarus Verilog
git clone https://github.com/steveicarus/iverilog.git
cd iverilog && sh autoconf.sh && ./configure && make && sudo make install

# Build Yosys
git clone https://github.com/YosysHQ/yosys.git
cd yosys && make && sudo make install

# Build Verilator
git clone https://github.com/verilator/verilator.git
cd verilator && autoconf && ./configure && make && sudo make install
```

## Windows Setup

### Option 1: WSL2 (Recommended)

```bash
# Install WSL2 with Ubuntu
wsl --install -d Ubuntu

# In Ubuntu terminal, follow Linux installation steps
sudo apt-get update
sudo apt-get install -y iverilog yosys verilator gtkwave build-essential

# Access Windows files from WSL
cd /mnt/c/Users/YourName/Projects/
```

### Option 2: MSYS2

```bash
# Install MSYS2 from https://www.msys2.org/

# In MSYS2 terminal
pacman -S mingw-w64-x86_64-iverilog
pacman -S mingw-w64-x86_64-yosys
pacman -S mingw-w64-x86_64-verilator

# Add to PATH
export PATH="/mingw64/bin:$PATH"
```

### Option 3: Native Windows

1. **Download Individual Tools**:
   - Icarus Verilog: http://bleyer.org/icarus/
   - GTKWave: http://gtkwave.sourceforge.net/
   - Yosys: Build from source or use pre-built binaries

2. **Add to PATH**:
```cmd
# Add tool directories to Windows PATH
set PATH=%PATH%;C:\iverilog\bin;C:\gtkwave\bin
```

### Windows-Specific Notes

- Use WSL2 for best compatibility
- Some scripts may need modification for native Windows
- Consider using Git Bash for Unix-like commands

## Usage Examples

### Basic Simulation Workflow

```bash
# Check tool availability
make check-env

# Run all simulations
make sim

# Run specific testbench
make sim-tb_jtag_controller

# View waveforms (choose your preferred viewer)
surfer results/simulation/waveforms/tb_jtag_controller.vcd    # Modern viewer
gtkwave results/simulation/waveforms/tb_jtag_controller.vcd   # Traditional viewer
```

### Synthesis Workflow

```bash
# Run synthesis with Yosys
make syn

# Synthesize specific module
./scripts/run_synthesis.sh --module jtag_controller

# View synthesis reports
cat results/synthesis/reports/jtag_controller_stats.rpt
```

### Coverage Analysis

```bash
# Run coverage analysis with Verilator
make cov

# View coverage reports
open results/coverage/reports/index.html
```

### Advanced Simulation

```bash
# Run with debug output
./scripts/run_simulation.sh --debug

# Run specific testbench with GUI
./scripts/run_simulation.sh --testbench tb_jtag_controller --gui

# Clean and run
./scripts/run_simulation.sh --clean
```

## Advanced Features

### Custom Waveform Analysis

```bash
# Generate VCD with specific signals
iverilog -o tb_test src/rtl/*.v src/tb/tb_jtag_controller.sv
vvp tb_test +vcd=custom_waves.vcd

# View with GTKWave
gtkwave custom_waves.vcd &
```

### Yosys Synthesis Scripting

```bash
# Custom synthesis script
cat > custom_synth.ys << EOF
read_verilog src/rtl/jtag_controller.v
hierarchy -top jtag_controller
proc; opt; fsm; opt; memory; opt
techmap; opt
abc -liberty /path/to/liberty/file.lib
opt_clean
write_verilog synthesized_jtag.v
EOF

# Run custom synthesis
yosys custom_synth.ys
```

### Verilator Advanced Usage

```bash
# Generate C++ model
verilator --cc --exe --build src/rtl/jtag_controller.v --top-module jtag_controller

# Run with coverage
verilator --cc --exe --build --coverage src/rtl/*.v src/tb/tb_jtag_controller.sv

# Generate traces
verilator --cc --exe --build --trace src/rtl/*.v src/tb/tb_jtag_controller.sv
```

### Performance Optimization

1. **Parallel Simulation**:
```bash
# Run multiple testbenches in parallel
make -j4 sim
```

2. **Verilator Optimization**:
```bash
# Use optimized Verilator flags
verilator --cc --exe --build -O3 --x-assign fast --x-initial fast
```

3. **Memory Management**:
```bash
# Limit memory usage for large simulations
ulimit -v 4194304  # 4GB limit
```

## Waveform Viewer Comparison

### Surfer vs GTKWave

| Feature | Surfer | GTKWave |
|---------|--------|---------|
| **macOS Integration** | ✅ Native | ⚠️ Limited |
| **Modern UI** | ✅ Yes | ❌ No |
| **Performance** | ✅ Fast | ⚠️ Moderate |
| **File Formats** | VCD, FST, GHW | VCD, FST, LXT, GHW |
| **Cross-Platform** | ✅ Yes | ✅ Yes |
| **Dark Mode** | ✅ Yes | ❌ No |
| **Touch/Gesture Support** | ✅ Yes | ❌ No |
| **Installation** | Easy (Homebrew) | Easy (Package Manager) |

### Surfer Features
- **Modern Interface**: Clean, intuitive design
- **High Performance**: Optimized for large waveform files
- **Native macOS**: Proper integration with macOS features
- **Multiple Formats**: Supports VCD, FST, and other formats
- **Advanced Navigation**: Smooth zooming and panning

### GTKWave Features
- **Mature Tool**: Long-established with extensive features
- **Wide Format Support**: Supports many waveform formats
- **Scripting**: TCL scripting support for automation
- **Cross-Platform**: Consistent across all platforms

### Choosing the Right Viewer

**Use Surfer if**:
- You're on macOS (especially Apple Silicon)
- You prefer modern, native applications
- You work with large waveform files
- You value performance and smooth UI

**Use GTKWave if**:
- You need maximum format compatibility
- You use scripting for waveform analysis
- You work across multiple platforms consistently
- You're familiar with traditional EDA tools

## Tool-Specific Tips

### Icarus Verilog
- Use `+define+` for compile-time defines
- Enable timing checks with `+timingchecks`
- Use `$dumpfile` and `$dumpvars` for VCD generation

### Yosys
- Use `show` command to visualize netlists
- `stat` command provides resource utilization
- `check` command verifies design consistency

### Verilator
- Use `--timing` for better SystemVerilog support
- `--trace` generates FST files (faster than VCD)
- `--coverage` enables line and toggle coverage

### Surfer
- Drag and drop VCD files to open
- Use mouse wheel for zooming
- Command+F for signal search (macOS)
- Native macOS shortcuts and gestures

### GTKWave
- Use `File > Read Save File` to load signal configurations
- `Ctrl+F` for signal search
- Use markers and cursors for timing analysis
- TCL console for scripting

## Troubleshooting

### Common Issues

1. **Tools Not Found**:
```bash
# Check PATH
echo $PATH

# Find tool locations
which iverilog yosys verilator gtkwave

# Add to PATH if needed
export PATH="/usr/local/bin:$PATH"
```

2. **Permission Issues (Linux/macOS)**:
```bash
# Fix permissions
sudo chown -R $USER:$USER /usr/local/bin/
chmod +x scripts/*.sh
```

3. **Library Issues**:
```bash
# Update library cache (Linux)
sudo ldconfig

# Check library dependencies
ldd $(which iverilog)
```

4. **Compilation Errors**:
```bash
# Check Verilog syntax
iverilog -t null src/rtl/jtag_controller.v

# Verbose compilation
iverilog -v -o test src/rtl/*.v src/tb/tb_test.sv
```

### Platform-Specific Issues

**macOS**:
- Use `brew doctor` to check Homebrew issues
- For Apple Silicon, ensure ARM64 compatibility
- Check Xcode command line tools: `xcode-select --install`

**Linux**:
- Update package database: `sudo apt-get update`
- Check for missing dependencies: `ldd $(which tool)`
- Verify user permissions for `/usr/local/`

**Windows**:
- Use WSL2 for best compatibility
- Check Windows PATH environment variable
- Consider using Git Bash for Unix commands

### Performance Issues

1. **Slow Simulation**:
```bash
# Use Verilator instead of Icarus for large designs
make sim SIMULATOR=verilator

# Reduce simulation time in testbenches
# Optimize clock periods and test duration
```

2. **Memory Issues**:
```bash
# Monitor memory usage
top -p $(pgrep iverilog)

# Limit VCD file size
# Use selective signal dumping in testbenches
```

3. **Disk Space**:
```bash
# Clean generated files
make clean

# Remove old waveforms
find results/ -name "*.vcd" -mtime +7 -delete
```

### Getting Help

1. **Tool Documentation**:
   - Icarus Verilog: http://iverilog.icarus.com/
   - Yosys: http://www.clifford.at/yosys/
   - Verilator: https://verilator.org/
   - GTKWave: http://gtkwave.sourceforge.net/

2. **Community Support**:
   - Stack Overflow with relevant tags
   - Tool-specific GitHub repositories
   - EDA forums and communities

3. **Project Support**:
```bash
# Show available make targets
make help

# Show script options
./scripts/run_simulation.sh --help
```

## Best Practices

### Project Organization
- Keep tool-specific configurations in separate files
- Use version control for all scripts and configurations
- Document tool versions used in project

### Simulation Best Practices
- Use appropriate time scales in testbenches
- Include proper reset sequences
- Add meaningful signal names for debugging

### Synthesis Best Practices
- Start with simple modules and build up
- Review synthesis warnings carefully
- Use consistent coding styles

### Performance Best Practices
- Use Verilator for large designs
- Limit VCD generation to necessary signals
- Run simulations in parallel when possible

This guide should help you effectively use open-source EDA tools with the JTAG/1500/1687 Network project. The automated installation script handles most setup complexity, but this guide provides detailed information for manual setup and advanced usage.