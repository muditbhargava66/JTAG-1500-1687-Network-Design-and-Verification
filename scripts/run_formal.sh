#!/bin/bash
# JTAG/1500/1687 Network Project - Formal Verification Script

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Process command line arguments
MODULE=""
TASK="prove"
DEBUG_MODE=0
CLEAN_MODE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -m, --module MODULE    Module to verify (default: jtag_controller)"
            echo "  -t, --task TASK        Task to run (prove, cover, bmc, default: prove)"
            echo "  -d, --debug            Enable debug output"
            echo "  -c, --clean            Clean results before running"
            echo "  -h, --help             Show this help message"
            exit 0
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        -t|--task)
            TASK="$2"
            shift 2
            ;;
        -d|--debug)
            DEBUG_MODE=1
            shift
            ;;
        -c|--clean)
            CLEAN_MODE=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Set module to jtag_controller if not specified
if [[ -z "$MODULE" ]]; then
    MODULE="jtag_controller"
fi

# Setup formal verification directory
FORMAL_DIR="${ROOT_DIR}/formal"
mkdir -p "${FORMAL_DIR}"

# Check if SymbiYosys is installed
if ! command_exists sby; then
    log_message "ERROR" "SymbiYosys (sby) not found. Please install it first."
    log_message "INFO" "On macOS: brew install symbiyosys"
    log_message "INFO" "On Ubuntu: apt-get install symbiyosys"
    exit 1
fi

# Check if Yosys is installed
if ! command_exists yosys; then
    log_message "ERROR" "Yosys not found. Please install it first."
    log_message "INFO" "On macOS: brew install yosys"
    log_message "INFO" "On Ubuntu: apt-get install yosys"
    exit 1
fi

# Clean mode if requested
if [[ ${CLEAN_MODE} -eq 1 ]]; then
    log_message "INFO" "Cleaning formal verification results"
    rm -rf "${FORMAL_DIR}/${MODULE}_${TASK}"
fi

# Run formal verification
log_message "INFO" "Running formal verification on ${MODULE} (task: ${TASK})"

# Go to formal directory
cd "${FORMAL_DIR}"

# Check if the .sby file exists
if [[ ! -f "${MODULE}.sby" ]]; then
    log_message "ERROR" "Formal configuration file ${MODULE}.sby not found."
    log_message "WARNING" "Formal verification is currently under development."
    log_message "INFO" "Available configurations: jtag_controller.sby, simple_jtag.sby"
    exit 1
fi

# Check if the properties file exists
if [[ ! -f "${MODULE}_props.sv" ]]; then
    log_message "ERROR" "Formal properties file ${MODULE}_props.sv not found."
    log_message "WARNING" "Formal verification requires RTL fixes for multiple driver conflicts."
    exit 1
fi

# Run SymbiYosys
if [[ ${DEBUG_MODE} -eq 1 ]]; then
    sby -f "${MODULE}.sby" "${TASK}"
else
    sby -f "${MODULE}.sby" "${TASK}" > "${MODULE}_${TASK}.log" 2>&1
fi

exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
    log_message "INFO" "Formal verification successful!"
    
    # Display results
    if [[ -f "${MODULE}_${TASK}/engine_0/trace.vcd" ]]; then
        log_message "INFO" "Trace available at: ${FORMAL_DIR}/${MODULE}_${TASK}/engine_0/trace.vcd"
    fi
    
    if [[ -f "${MODULE}_${TASK}/logfile.txt" ]]; then
        log_message "INFO" "Log file: ${FORMAL_DIR}/${MODULE}_${TASK}/logfile.txt"
    fi
    
    # For coverage tasks, display covered items
    if [[ "${TASK}" == "cover" ]]; then
        grep -A 1 "Reached cover statement" "${MODULE}_${TASK}/logfile.txt" || true
    fi
else
    log_message "ERROR" "Formal verification failed with status ${exit_code}"
    
    if [[ -f "${MODULE}_${TASK}/logfile.txt" ]]; then
        # Extract the failing assertion
        log_message "INFO" "Failing assertions:"
        grep -A 3 "Assert failed in" "${MODULE}_${TASK}/logfile.txt" || true
    fi
fi

exit ${exit_code}