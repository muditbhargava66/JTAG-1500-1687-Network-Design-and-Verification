#!/bin/bash
# Common shell functions and variables for JTAG/1500/1687 Network project scripts

# Set up directories relative to the script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${ROOT_DIR}/src"
RTL_DIR="${SRC_DIR}/rtl"
TB_DIR="${SRC_DIR}/tb"
BSDL_DIR="${SRC_DIR}/bsdl"
ICL_DIR="${SRC_DIR}/icl"
PDL_DIR="${SRC_DIR}/pdl"
RESULTS_DIR="${ROOT_DIR}/results"
SIM_DIR="${RESULTS_DIR}/simulation"
SYN_DIR="${RESULTS_DIR}/synthesis"
COV_DIR="${RESULTS_DIR}/coverage"
WAVEFORM_DIR="${SIM_DIR}/waveforms"
LOG_DIR="${SIM_DIR}/logs"
REPORT_DIR="${SIM_DIR}/reports"

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create required directories if they don't exist
create_directories() {
    mkdir -p "${WAVEFORM_DIR}" "${LOG_DIR}" "${REPORT_DIR}"
    mkdir -p "${SYN_DIR}/reports"
    mkdir -p "${COV_DIR}/reports"
    
    # Add .gitkeep files to track empty directories
    for dir in "${WAVEFORM_DIR}" "${LOG_DIR}" "${REPORT_DIR}" "${SYN_DIR}/reports" "${COV_DIR}/reports"; do
        if [ ! -f "${dir}/.gitkeep" ]; then
            touch "${dir}/.gitkeep"
        fi
    done
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        MINGW*|CYGWIN*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Open a waveform viewer based on OS
open_waveform() {
    local waveform_file=$1
    local os=$(detect_os)
    
    if [[ ! -f "${waveform_file}" ]]; then
        echo -e "${RED}Error: Waveform file not found: ${waveform_file}${NC}"
        return 1
    fi
    
    case "${os}" in
        macos)
            if command -v surfer &> /dev/null; then
                surfer "${waveform_file}" &
                echo -e "${GREEN}Opened waveform with surfer${NC}"
            elif command -v gtkwave &> /dev/null; then
                gtkwave "${waveform_file}" &
                echo -e "${GREEN}Opened waveform with gtkwave${NC}"
            else
                echo -e "${YELLOW}Warning: No waveform viewer found.${NC}"
                echo -e "${BLUE}Install options for macOS:${NC}"
                echo -e "${BLUE}  • Surfer (recommended): brew install --cask surfer${NC}"
                echo -e "${BLUE}  • GTKWave: brew install gtkwave${NC}"
            fi
            ;;
        linux)
            if command -v surfer &> /dev/null; then
                surfer "${waveform_file}" &
                echo -e "${GREEN}Opened waveform with Surfer (modern waveform viewer)${NC}"
            elif command -v gtkwave &> /dev/null; then
                gtkwave "${waveform_file}" &
                echo -e "${GREEN}Opened waveform with GTKWave${NC}"
            else
                echo -e "${YELLOW}Warning: No waveform viewer found.${NC}"
                echo -e "${BLUE}Install options: sudo apt-get install gtkwave or download Surfer${NC}"
            fi
            ;;
        windows)
            if command -v gtkwave &> /dev/null; then
                gtkwave "${waveform_file}" &
                echo -e "${GREEN}Opened waveform with GTKWave${NC}"
            elif command -v surfer &> /dev/null; then
                surfer "${waveform_file}" &
                echo -e "${GREEN}Opened waveform with Surfer${NC}"
            else
                echo -e "${YELLOW}Warning: No waveform viewer found.${NC}"
                echo -e "${BLUE}Install GTKWave or Surfer for waveform viewing${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Error: Unsupported operating system.${NC}"
            return 1
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Log messages with timestamp
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "${level}" in
        INFO)
            echo -e "${GREEN}[${timestamp}] [INFO] ${message}${NC}"
            ;;
        WARNING)
            echo -e "${YELLOW}[${timestamp}] [WARNING] ${message}${NC}"
            ;;
        ERROR)
            echo -e "${RED}[${timestamp}] [ERROR] ${message}${NC}"
            ;;
        *)
            echo -e "${BLUE}[${timestamp}] [${level}] ${message}${NC}"
            ;;
    esac
}

# Check for required tools based on mode
check_tools() {
    local mode="$1"
    local tools_found=true
    
    if [[ "${mode}" == "vivado" ]]; then
        if ! command_exists vivado; then
            log_message "ERROR" "Vivado not found in path."
            tools_found=false
        fi
    else
        case "${mode}" in
            simulation)
                if ! command_exists iverilog; then
                    log_message "ERROR" "Icarus Verilog not found. Install with:"
                    echo "  Linux:   sudo apt-get install iverilog"
                    echo "  macOS:   brew install icarus-verilog"
                    echo "  Windows: Download from http://bleyer.org/icarus/"
                    tools_found=false
                fi
                if ! command_exists vvp; then
                    log_message "ERROR" "VVP runtime not found."
                    tools_found=false
                fi
                ;;
            synthesis)
                if ! command_exists yosys; then
                    log_message "ERROR" "Yosys not found. Install with:"
                    echo "  Linux:   sudo apt-get install yosys"
                    echo "  macOS:   brew install yosys"
                    echo "  Windows: Download from http://www.clifford.at/yosys/"
                    tools_found=false
                fi
                ;;
            coverage)
                if ! command_exists verilator; then
                    log_message "ERROR" "Verilator not found. Install with:"
                    echo "  Linux:   sudo apt-get install verilator"
                    echo "  macOS:   brew install verilator"
                    echo "  Windows: Use WSL and install via apt-get"
                    tools_found=false
                fi
                ;;
            *)
                log_message "ERROR" "Unknown mode: ${mode}"
                return 1
                ;;
        esac
    fi
    
    return $( [[ "${tools_found}" == "true" ]] ; echo $? )
}

# Get the list of modules from a directory
get_modules() {
    local dir="$1"
    local ext="$2"
    local modules=()
    
    for file in "${dir}"/*."${ext}"; do
        if [[ -f "${file}" ]]; then
            modules+=($(basename "${file}" ."${ext}"))
        fi
    done
    
    echo "${modules[@]}"
}

# Print version and help information
print_version() {
    echo "JTAG/1500/1687 Network Project - Version 1.1.0"
    echo "Copyright (C) 2025"
}

print_help() {
    local script_name="$1"
    
    echo "Usage: $script_name [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -v, --version       Show version information"
    echo "  -t, --testbench TB  Run specific testbench"
    echo "  -g, --gui           Open waveform viewer after simulation"
    echo "  -d, --debug         Enable debug mode with verbose output"
    echo "  -c, --clean         Clean results before running"
    echo ""
    echo "Examples:"
    echo "  $script_name -t tb_jtag_controller -g"
    echo "  $script_name --clean --testbench tb_top_module"
}

# Initialize script environment
init_environment() {
    local script_name="$1"
    
    log_message "INFO" "Initializing environment for ${script_name}"
    create_directories
    log_message "INFO" "Working in ${ROOT_DIR}"
}

# Export all variables and functions
export ROOT_DIR RTL_DIR TB_DIR BSDL_DIR ICL_DIR PDL_DIR RESULTS_DIR
export SIM_DIR SYN_DIR COV_DIR WAVEFORM_DIR LOG_DIR REPORT_DIR
export RED GREEN YELLOW BLUE NC

# Initialize only if this script is being run directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_version
    echo "This script is meant to be sourced by other scripts, not run directly."
    echo "Usage: source $(basename "${BASH_SOURCE[0]}")"
    exit 1
fi