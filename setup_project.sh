#!/bin/bash

# JTAG/1500/1687 Network Project Setup Script

# This script sets up the project directory structure and prepares the environment

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE}JTAG/1500/1687 Network Project Setup (Version 1.1.0)${NC}"
echo -e "${BLUE}=======================================================${NC}"
echo

# Get script directory and set root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}" && pwd)"

# Create directory structure
create_directory_structure() {
    echo -e "${GREEN}Creating directory structure...${NC}"
    
    # Create results directory structure with .gitkeep files
    mkdir -p "${ROOT_DIR}/results"
    touch "${ROOT_DIR}/results/.gitkeep"
    
    # Simulation directories
    mkdir -p "${ROOT_DIR}/results/simulation"
    touch "${ROOT_DIR}/results/simulation/.gitkeep"
    mkdir -p "${ROOT_DIR}/results/simulation/waveforms"
    touch "${ROOT_DIR}/results/simulation/waveforms/.gitkeep"
    mkdir -p "${ROOT_DIR}/results/simulation/logs"
    touch "${ROOT_DIR}/results/simulation/logs/.gitkeep"
    
    # Synthesis directories
    mkdir -p "${ROOT_DIR}/results/synthesis"
    touch "${ROOT_DIR}/results/synthesis/.gitkeep"
    mkdir -p "${ROOT_DIR}/results/synthesis/reports"
    touch "${ROOT_DIR}/results/synthesis/reports/.gitkeep"
    
    # Coverage directories
    mkdir -p "${ROOT_DIR}/results/coverage"
    touch "${ROOT_DIR}/results/coverage/.gitkeep"
    mkdir -p "${ROOT_DIR}/results/coverage/reports"
    touch "${ROOT_DIR}/results/coverage/reports/.gitkeep"
    
    # Make scripts executable
    chmod +x "${ROOT_DIR}/scripts"/*.sh
    
    echo -e "${GREEN}Directory structure created successfully.${NC}"
}

# Check for required tools
check_tools() {
    echo -e "${GREEN}Checking for required tools...${NC}"
    local all_tools_found=true
    
    # Check for common tools
    if ! command -v make &> /dev/null; then
        echo -e "${YELLOW}Warning: make not found. Install for better build experience.${NC}"
        all_tools_found=false
    fi
    
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Warning: git not found. Install for version control support.${NC}"
        all_tools_found=false
    fi
    
    # Check for open-source tools
    if ! command -v iverilog &> /dev/null; then
        echo -e "${YELLOW}Warning: Icarus Verilog not found. Install for simulation support.${NC}"
        all_tools_found=false
    fi
    
    if ! command -v yosys &> /dev/null; then
        echo -e "${YELLOW}Warning: Yosys not found. Install for synthesis support.${NC}"
        all_tools_found=false
    fi
    
    if ! command -v verilator &> /dev/null; then
        echo -e "${YELLOW}Warning: Verilator not found. Install for coverage analysis.${NC}"
        all_tools_found=false
    fi
    
    local os=$(uname -s)
    if [[ "$os" == "Darwin"* ]]; then
        # On macOS, prioritize Surfer over GTKWave
        if ! command -v surfer &> /dev/null && ! command -v gtkwave &> /dev/null; then
            echo -e "${YELLOW}Warning: No waveform viewer found. Surfer is recommended for macOS.${NC}"
            all_tools_found=false
        elif command -v surfer &> /dev/null; then
            echo -e "${GREEN}Found Surfer. Waveform viewing is available.${NC}"
        elif command -v gtkwave &> /dev/null; then
            echo -e "${GREEN}Found GTKWave. Waveform viewing is available.${NC}"
        fi
    else
        # On other platforms, check for GTKWave
        if ! command -v gtkwave &> /dev/null; then
            echo -e "${YELLOW}Warning: GTKWave not found. Install for waveform viewing.${NC}"
            all_tools_found=false
        fi
    fi
    
    # Check for commercial tools (optional)
    if command -v vivado &> /dev/null; then
        echo -e "${GREEN}Found Vivado. Commercial tool flow is available.${NC}"
    else
        echo -e "${YELLOW}Note: Vivado not found. Commercial tool flow unavailable.${NC}"
    fi
    
    if [ "$all_tools_found" = true ]; then
        echo -e "${GREEN}All required tools found.${NC}"
    else
        echo -e "${YELLOW}Some tools are missing. See warnings above.${NC}"
        # Print installation instructions
        echo -e "${BLUE}Installation instructions:${NC}"
        echo -e " ${BLUE}Ubuntu/Debian:${NC} sudo apt-get install iverilog yosys verilator gtkwave"
        echo -e " ${BLUE}macOS:${NC} brew install icarus-verilog yosys verilator gtkwave"
        echo -e " ${BLUE}Windows:${NC} Use WSL or install individual tools from their websites"
    fi
}

# Display project information
show_project_info() {
    echo -e "${GREEN}Project Information:${NC}"
    echo -e " ${BLUE}Root Directory:${NC} ${ROOT_DIR}"
    echo -e " ${BLUE}Version:${NC} 1.1.0"
    echo -e " ${BLUE}Components:${NC} JTAG (IEEE 1149.1), IEEE 1500 Wrapper, IEEE 1687 Network"
    echo
    echo -e "${GREEN}Available Commands:${NC}"
    echo -e " ${BLUE}make all${NC} - Run simulation, synthesis, and coverage"
    echo -e " ${BLUE}make sim${NC} - Run simulation for top module"
    echo -e " ${BLUE}make syn${NC} - Run synthesis for top module"
    echo -e " ${BLUE}make cov${NC} - Run coverage analysis for top module"
    echo -e " ${BLUE}make help${NC} - Show all available targets"
    echo
    echo -e "${GREEN}Documentation:${NC}"
    echo -e " See README.md and docs/ directory for more information"
}

# Run all setup steps
main() {
    create_directory_structure
    echo
    check_tools
    echo
    show_project_info
    echo
    echo -e "${GREEN}Setup complete. Project is ready to use.${NC}"
}

# Execute main function
main
