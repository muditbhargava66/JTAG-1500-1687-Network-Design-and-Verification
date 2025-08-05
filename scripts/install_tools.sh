#!/bin/bash
# JTAG/1500/1687 Network Project - Tool Installation Guide
# Automated installation script for required tools

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Installation functions for different operating systems
install_macos_tools() {
    log_message "INFO" "Installing tools for macOS using Homebrew"
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        log_message "ERROR" "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        return 1
    fi
    
    log_message "INFO" "Updating Homebrew..."
    brew update
    
    # Install core tools
    local tools=("icarus-verilog" "yosys" "verilator" "gtkwave")
    
    for tool in "${tools[@]}"; do
        if brew list "${tool}" &>/dev/null; then
            log_message "INFO" "${tool} already installed"
        else
            log_message "INFO" "Installing ${tool}..."
            brew install "${tool}"
        fi
    done
    
    # Install modern waveform viewer (Surfer) for macOS
    if ! command_exists surfer; then
        log_message "INFO" "Installing Surfer waveform viewer (recommended for macOS)..."
        if brew list --cask surfer &>/dev/null; then
            log_message "INFO" "Surfer already installed"
        else
            log_message "INFO" "Installing Surfer via Homebrew cask..."
            brew install --cask surfer || {
                log_message "WARNING" "Surfer installation failed, GTKWave will be used as fallback"
            }
        fi
    else
        log_message "INFO" "Surfer already available"
    fi
    
    log_message "INFO" "macOS tool installation completed"
}

install_linux_tools() {
    log_message "INFO" "Installing tools for Linux"
    
    # Detect Linux distribution
    if [[ -f /etc/debian_version ]]; then
        install_debian_tools
    elif [[ -f /etc/redhat-release ]]; then
        install_redhat_tools
    else
        log_message "WARNING" "Unknown Linux distribution. Please install manually:"
        print_manual_installation_guide
    fi
}

install_debian_tools() {
    log_message "INFO" "Installing tools for Debian/Ubuntu"
    
    # Update package list
    log_message "INFO" "Updating package list..."
    sudo apt-get update
    
    # Install core tools
    local packages=("iverilog" "yosys" "verilator" "gtkwave" "build-essential")
    
    for package in "${packages[@]}"; do
        log_message "INFO" "Installing ${package}..."
        sudo apt-get install -y "${package}"
    done
    
    log_message "INFO" "Debian/Ubuntu tool installation completed"
}

install_redhat_tools() {
    log_message "INFO" "Installing tools for Red Hat/CentOS/Fedora"
    
    # Check if dnf or yum is available
    if command_exists dnf; then
        local pkg_manager="dnf"
    elif command_exists yum; then
        local pkg_manager="yum"
    else
        log_message "ERROR" "No package manager found (dnf/yum)"
        return 1
    fi
    
    # Enable EPEL repository for additional packages
    if [[ "${pkg_manager}" == "yum" ]]; then
        sudo yum install -y epel-release
    fi
    
    # Install core tools
    local packages=("iverilog" "yosys" "verilator" "gtkwave" "gcc-c++")
    
    for package in "${packages[@]}"; do
        log_message "INFO" "Installing ${package}..."
        sudo "${pkg_manager}" install -y "${package}"
    done
    
    log_message "INFO" "Red Hat tool installation completed"
}

install_windows_tools() {
    log_message "INFO" "Windows installation guide"
    log_message "INFO" "For Windows, we recommend using WSL (Windows Subsystem for Linux)"
    
    echo ""
    echo "Windows Installation Steps:"
    echo "1. Install WSL2 with Ubuntu:"
    echo "   wsl --install -d Ubuntu"
    echo ""
    echo "2. Open Ubuntu terminal and run:"
    echo "   sudo apt-get update"
    echo "   sudo apt-get install -y iverilog yosys verilator gtkwave build-essential"
    echo ""
    echo "3. Alternative: Use MSYS2 or individual Windows installers"
    echo "   - Icarus Verilog: http://bleyer.org/icarus/"
    echo "   - Yosys: Build from source or use pre-built binaries"
    echo "   - Verilator: Requires MSYS2 or Cygwin"
    echo "   - GTKWave: http://gtkwave.sourceforge.net/"
    echo ""
}

print_manual_installation_guide() {
    echo ""
    echo "Manual Installation Guide:"
    echo "=========================="
    echo ""
    echo "Required Tools:"
    echo "1. Icarus Verilog (iverilog, vvp)"
    echo "   - Website: http://iverilog.icarus.com/"
    echo "   - Purpose: Verilog simulation"
    echo ""
    echo "2. Yosys"
    echo "   - Website: http://www.clifford.at/yosys/"
    echo "   - Purpose: Logic synthesis"
    echo ""
    echo "3. Verilator"
    echo "   - Website: https://www.veripool.org/verilator/"
    echo "   - Purpose: Fast simulation and coverage analysis"
    echo ""
    echo "4. Waveform Viewers"
    echo "   - Surfer (recommended for macOS): https://surfer-project.org/"
    echo "     • Modern, native waveform viewer with better macOS integration"
    echo "     • Installation: brew install --cask surfer"
    echo "   - GTKWave: http://gtkwave.sourceforge.net/"
    echo "     • Traditional waveform viewer, cross-platform"
    echo "     • Installation: Package manager or source"
    echo ""
    echo "Optional Commercial Tools:"
    echo "1. Xilinx Vivado"
    echo "   - Website: https://www.xilinx.com/products/design-tools/vivado.html"
    echo "   - Purpose: Complete FPGA design suite"
    echo ""
}

verify_installation() {
    log_message "INFO" "Verifying tool installation..."
    
    local tools=("iverilog" "vvp" "yosys" "verilator")
    local optional_tools=("gtkwave" "surfer" "vivado")
    local all_good=1
    
    echo ""
    echo "Required Tools:"
    echo "==============="
    
    for tool in "${tools[@]}"; do
        if command_exists "${tool}"; then
            local version=$(${tool} --version 2>/dev/null | head -1 || echo "Version unknown")
            echo "✓ ${tool}: ${version}"
        else
            echo "✗ ${tool}: NOT FOUND"
            all_good=0
        fi
    done
    
    echo ""
    echo "Optional Tools:"
    echo "==============="
    
    for tool in "${optional_tools[@]}"; do
        if command_exists "${tool}"; then
            local version=$(${tool} --version 2>/dev/null | head -1 || echo "Version unknown")
            echo "✓ ${tool}: ${version}"
        else
            echo "- ${tool}: Not installed"
        fi
    done
    
    echo ""
    if [[ ${all_good} -eq 1 ]]; then
        log_message "INFO" "All required tools are installed!"
        echo "You can now run: make check-env"
    else
        log_message "WARNING" "Some required tools are missing. Please install them before proceeding."
    fi
}

# Main installation function
main() {
    local os=$(detect_os)
    local install_mode="auto"
    local verify_only=0
    
    # Process command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  -h, --help     Show this help message"
                echo "  -m, --manual   Show manual installation guide only"
                echo "  -v, --verify   Verify installation only (no installation)"
                echo ""
                exit 0
                ;;
            -m|--manual)
                print_manual_installation_guide
                exit 0
                ;;
            -v|--verify)
                verify_only=1
                shift
                ;;
            *)
                log_message "ERROR" "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [[ ${verify_only} -eq 1 ]]; then
        verify_installation
        exit 0
    fi
    
    log_message "INFO" "JTAG/1500/1687 Network Project - Tool Installation"
    log_message "INFO" "Detected OS: ${os}"
    
    case "${os}" in
        macos)
            install_macos_tools
            ;;
        linux)
            install_linux_tools
            ;;
        windows)
            install_windows_tools
            ;;
        *)
            log_message "ERROR" "Unsupported operating system: ${os}"
            print_manual_installation_guide
            exit 1
            ;;
    esac
    
    echo ""
    verify_installation
}

# Run main function
main "$@"