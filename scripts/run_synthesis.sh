#!/bin/bash
# JTAG/1500/1687 Network Project - Run Synthesis Script
# Cross-platform script for running synthesis

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Process command line arguments
MODULE=""
DEBUG_MODE=0
CLEAN_MODE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            print_help "$(basename "$0")"
            exit 0
            ;;
        -v|--version)
            print_version
            exit 0
            ;;
        -m|--module)
            MODULE="$2"
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
            log_message "ERROR" "Unknown option: $1"
            print_help "$(basename "$0")"
            exit 1
            ;;
    esac
done

# Initialize environment
init_environment "$(basename "$0")"

# Clean mode if requested
if [[ ${CLEAN_MODE} -eq 1 ]]; then
    log_message "INFO" "Cleaning synthesis results"
    rm -rf "${SYN_DIR}"/*
    mkdir -p "${SYN_DIR}/reports"
    touch "${SYN_DIR}/reports/.gitkeep"
fi

# Function to run synthesis with Yosys
run_yosys_synthesis() {
    log_message "INFO" "Running synthesis with Yosys"
    
    # Find modules to synthesize
    local modules=()
    
    if [[ -n "${MODULE}" ]]; then
        if [[ -f "${RTL_DIR}/${MODULE}.v" ]]; then
            modules=("${MODULE}")
        else
            log_message "ERROR" "Module file not found: ${RTL_DIR}/${MODULE}.v"
            exit 1
        fi
    else
        # Default to top_module.v if it exists
        if [[ -f "${RTL_DIR}/top_module.v" ]]; then
            modules=("top_module")
            log_message "INFO" "No module specified, synthesizing top_module.v"
        else
            # Get all Verilog modules if no specific one is specified
            modules=($(get_modules "${RTL_DIR}" "v"))
        fi
    fi
    
    local exit_code=0
    
    for module_name in "${modules[@]}"; do
        log_message "INFO" "Synthesizing ${module_name}"
        
        # Create Yosys script
        local yosys_script="${SYN_DIR}/${module_name}_syn.ys"
        
        # Get list of compatible RTL files for read commands
        local compatible_modules="jtag_controller jtag_memory_interface jtag_system boundary_scan_chain boundary_scan_chain_enhanced loopback_module top_module ieee1500_wrapper ieee1687_network simple_scan_chain"
        local rtl_files=""
        for module in ${compatible_modules}; do
            if [[ -f "${RTL_DIR}/${module}.v" ]]; then
                rtl_files="${rtl_files} ${RTL_DIR}/${module}.v"
            fi
        done
        local read_commands=""
        
        # Create read commands for all RTL files
        for rtl_file in ${rtl_files}; do
            read_commands+="read -sv ${rtl_file}\n"
        done
        
        # Create Yosys script for synthesis
        # NOTE: Read ALL Verilog files first, then specify the top module
        cat > "${yosys_script}" << EOF
# Yosys synthesis script for ${module_name}
# Read all Verilog files
$(echo -e ${read_commands})

# Set the top module and perform synthesis
hierarchy -check -top ${module_name}
proc; opt; fsm; opt; memory; opt
techmap; opt
write_verilog ${SYN_DIR}/${module_name}_synth.v
write_json ${SYN_DIR}/${module_name}_synth.json
stat -width
EOF
        
        # Run Yosys with the script
        if [[ ${DEBUG_MODE} -eq 1 ]]; then
            log_message "DEBUG" "Running Yosys with script: ${yosys_script}"
            yosys -l "${SYN_DIR}/${module_name}.log" "${yosys_script}"
        else
            yosys -q -l "${SYN_DIR}/${module_name}.log" "${yosys_script}" > /dev/null 2>&1
        fi
        
        if [[ $? -eq 0 ]]; then
            log_message "INFO" "Synthesis completed for ${module_name}"
            
            # Generate a simple report
            log_message "INFO" "Generating synthesis report"
            
            # Extract statistics
            grep -A20 "Printing statistics" "${SYN_DIR}/${module_name}.log" > "${SYN_DIR}/reports/${module_name}_stats.rpt"
            
            log_message "INFO" "See report: ${SYN_DIR}/reports/${module_name}_stats.rpt"
            log_message "INFO" "Synthesized file: ${SYN_DIR}/${module_name}_synth.v"
        else
            log_message "ERROR" "Synthesis failed for ${module_name}"
            log_message "INFO" "See log for details: ${SYN_DIR}/${module_name}.log"
            exit_code=1
        fi
    done
    
    return ${exit_code}
}

# Function to run synthesis with Vivado
run_vivado_synthesis() {
    log_message "INFO" "Running synthesis with Vivado"
    
    # Set up arguments for the Tcl script
    local tcl_args=""
    
    if [[ -n "${MODULE}" ]]; then
        tcl_args+=" -module ${MODULE}"
    fi
    
    if [[ ${DEBUG_MODE} -eq 1 ]]; then
        tcl_args+=" -verbose"
    fi
    
    if [[ ${CLEAN_MODE} -eq 1 ]]; then
        tcl_args+=" -clean"
    fi
    
    # Run Vivado in batch mode with the synthesis Tcl script
    local vivado_cmd="vivado -mode batch -source ${SCRIPT_DIR}/vivado_syn.tcl -tclargs ${tcl_args}"
    
    if [[ ${DEBUG_MODE} -eq 1 ]]; then
        log_message "DEBUG" "Running: ${vivado_cmd}"
        eval "${vivado_cmd}"
    else
        eval "${vivado_cmd}" > "${SYN_DIR}/vivado_syn.log" 2>&1
    fi
    
    local exit_code=$?
    
    if [[ ${exit_code} -ne 0 ]]; then
        log_message "ERROR" "Vivado synthesis failed with status ${exit_code}"
        log_message "INFO" "See log for details: ${SYN_DIR}/vivado_syn.log"
    else
        log_message "INFO" "Vivado synthesis completed successfully"
    fi
    
    return ${exit_code}
}

# Main function
main() {
    local os=$(detect_os)
    log_message "INFO" "Detected OS: ${os}"
    
    # Check if Vivado is installed and use it if available
    if command_exists vivado; then
        log_message "INFO" "Vivado found, using Vivado for synthesis"
        if check_tools "vivado"; then
            run_vivado_synthesis
        else
            log_message "WARNING" "Falling back to open-source tools"
            if check_tools "synthesis"; then
                run_yosys_synthesis
            else
                log_message "ERROR" "Required tools for synthesis not found"
                exit 1
            fi
        fi
    else
        log_message "INFO" "Vivado not found, using open-source tools"
        if check_tools "synthesis"; then
            run_yosys_synthesis
        else
            log_message "ERROR" "Required tools for synthesis not found"
            exit 1
        fi
    fi
    
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        log_message "INFO" "Synthesis completed successfully"
    else
        log_message "ERROR" "Synthesis failed"
        exit ${exit_code}
    fi
}

# Call the main function
main
