#!/bin/bash
# JTAG/1500/1687 Network Project - Run Simulation Script
# Cross-platform script for running simulations

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Process command line arguments
TESTBENCH=""
GUI_MODE=0
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
        -t|--testbench)
            TESTBENCH="$2"
            shift 2
            ;;
        -g|--gui)
            GUI_MODE=1
            shift
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
    log_message "INFO" "Cleaning simulation results"
    rm -rf "${SIM_DIR}"/*
    create_directories
fi

# Function to run simulation with Icarus Verilog
run_icarus_simulation() {
    log_message "INFO" "Running simulations with Icarus Verilog"
    
    # Find testbenches to simulate
    local testbenches=()
    
    if [[ -n "${TESTBENCH}" ]]; then
        if [[ -f "${TB_DIR}/${TESTBENCH}.sv" ]]; then
            testbenches=("${TESTBENCH}")
        elif [[ -f "${TB_DIR}/${TESTBENCH}.v" ]]; then
            testbenches=("${TESTBENCH}")
        else
            log_message "ERROR" "Testbench file not found: ${TB_DIR}/${TESTBENCH}.sv or ${TB_DIR}/${TESTBENCH}.v"
            exit 1
        fi
    else
        # Get testbenches from Makefile TB_MODULES (only compatible ones)
        local compatible_testbenches="tb_jtag_controller tb_jtag_memory_access tb_boundary_scan_chain tb_loopback_module tb_top_module tb_ieee1500_wrapper tb_ieee1687_network tb_simple_scan_chain tb_stress_test"
        testbenches=(${compatible_testbenches})
    fi
    
    local exit_code=0
    
    for tb_name in "${testbenches[@]}"; do
        log_message "INFO" "Simulating ${tb_name}"
        
        # Create a temporary file that adds VCD generation to the testbench
        local source_file=""
        local tmp_tb_file=""
        
        if [[ -f "${TB_DIR}/${tb_name}.sv" ]]; then
            source_file="${TB_DIR}/${tb_name}.sv"
            tmp_tb_file="${TB_DIR}/${tb_name}_with_vcd.sv"
        elif [[ -f "${TB_DIR}/${tb_name}.v" ]]; then
            source_file="${TB_DIR}/${tb_name}.v"
            tmp_tb_file="${TB_DIR}/${tb_name}_with_vcd.v"
        else
            log_message "ERROR" "Source file not found for ${tb_name}"
            continue
        fi
        
        # Check if the testbench already has $dumpfile or $dumpvars
        if grep -q "dumpfile\|dumpvars" "${source_file}"; then
            # Already has dump commands, just compile as is
            cp "${source_file}" "${tmp_tb_file}"
        else
            # Add VCD dump commands to the testbench
            awk '
            /initial begin/ {
                print $0;
                print "        // VCD dump commands added by script";
                print "        $dumpfile(\"'${WAVEFORM_DIR}'/'${tb_name}'.vcd\");";
                print "        $dumpvars(0, '${tb_name}');";
                next;
            }
            {print}
            ' "${source_file}" > "${tmp_tb_file}"
        fi
        
        # Set compilation flags
        local iverilog_flags="-g2012 -I${RTL_DIR} -o ${SIM_DIR}/${tb_name}.vvp -s ${tb_name}"
        
        # Use only Icarus Verilog compatible modules
        local compatible_modules="jtag_controller jtag_memory_interface jtag_system boundary_scan_chain boundary_scan_chain_enhanced loopback_module top_module ieee1500_wrapper ieee1687_network simple_scan_chain"
        local rtl_files=""
        for module in ${compatible_modules}; do
            if [[ -f "${RTL_DIR}/${module}.v" ]]; then
                rtl_files="${rtl_files} ${RTL_DIR}/${module}.v"
            fi
        done
        
        # Compile the testbench
        if [[ ${DEBUG_MODE} -eq 1 ]]; then
            log_message "DEBUG" "Compiling with: iverilog ${iverilog_flags} ${rtl_files} ${tmp_tb_file}"
        fi
        
        iverilog ${iverilog_flags} ${rtl_files} "${tmp_tb_file}" 2> "${LOG_DIR}/${tb_name}_compile.log"
        
        if [[ $? -eq 0 ]]; then
            log_message "INFO" "Compilation successful for ${tb_name}"
            
            # Run the simulation
            if [[ ${DEBUG_MODE} -eq 1 ]]; then
                vvp "${SIM_DIR}/${tb_name}.vvp" | tee "${LOG_DIR}/${tb_name}.log"
            else
                vvp "${SIM_DIR}/${tb_name}.vvp" > "${LOG_DIR}/${tb_name}.log" 2>&1
            fi
            
            local run_status=$?
            
            if [[ ${run_status} -ne 0 ]]; then
                log_message "ERROR" "Simulation failed for ${tb_name} with status ${run_status}"
                exit_code=1
            else
                log_message "INFO" "Simulation completed for ${tb_name}"
            fi
            
            # Check for VCD file and open waveform viewer if requested
            if [[ -f "${WAVEFORM_DIR}/${tb_name}.vcd" ]]; then
                log_message "INFO" "Waveform generated: ${WAVEFORM_DIR}/${tb_name}.vcd"
                
                if [[ ${GUI_MODE} -eq 1 ]]; then
                    open_waveform "${WAVEFORM_DIR}/${tb_name}.vcd"
                fi
            else
                log_message "WARNING" "No waveform file generated for ${tb_name}"
                
                # Try alternative approach if needed
                if [[ ${GUI_MODE} -eq 1 ]]; then
                    log_message "INFO" "Trying alternative waveform generation"
                    vvp "${SIM_DIR}/${tb_name}.vvp" -vcd="${WAVEFORM_DIR}/${tb_name}.vcd" > "${LOG_DIR}/${tb_name}_vcd.log" 2>&1
                    
                    if [[ -f "${WAVEFORM_DIR}/${tb_name}.vcd" ]]; then
                        log_message "INFO" "Waveform generated with alternative method"
                        open_waveform "${WAVEFORM_DIR}/${tb_name}.vcd"
                    else
                        log_message "ERROR" "Failed to generate waveform with alternative method"
                    fi
                fi
            fi
        else
            log_message "ERROR" "Compilation failed for ${tb_name}"
            log_message "INFO" "See log for details: ${LOG_DIR}/${tb_name}_compile.log"
            exit_code=1
        fi
        
        # Clean up temporary file
        rm -f "${tmp_tb_file}"
    done
    
    return ${exit_code}
}

# Function to run simulation with Vivado
run_vivado_simulation() {
    log_message "INFO" "Running simulations with Vivado"
    
    # Set up arguments for the Tcl script
    local tcl_args=""
    
    if [[ -n "${TESTBENCH}" ]]; then
        tcl_args+=" -testbench ${TESTBENCH}"
    fi
    
    if [[ ${GUI_MODE} -eq 1 ]]; then
        tcl_args+=" -gui"
    fi
    
    if [[ ${DEBUG_MODE} -eq 1 ]]; then
        tcl_args+=" -verbose"
    fi
    
    if [[ ${CLEAN_MODE} -eq 1 ]]; then
        tcl_args+=" -clean"
    fi
    
    # Run Vivado in batch mode with the simulation Tcl script
    local vivado_cmd="vivado -mode batch -source ${SCRIPT_DIR}/vivado_sim.tcl -tclargs ${tcl_args}"
    
    if [[ ${DEBUG_MODE} -eq 1 ]]; then
        log_message "DEBUG" "Running: ${vivado_cmd}"
        eval "${vivado_cmd}"
    else
        eval "${vivado_cmd}" > "${LOG_DIR}/vivado_sim.log" 2>&1
    fi
    
    local exit_code=$?
    
    if [[ ${exit_code} -ne 0 ]]; then
        log_message "ERROR" "Vivado simulation failed with status ${exit_code}"
        log_message "INFO" "See log for details: ${LOG_DIR}/vivado_sim.log"
    else
        log_message "INFO" "Vivado simulation completed successfully"
    fi
    
    return ${exit_code}
}

# Main function
main() {
    local os=$(detect_os)
    log_message "INFO" "Detected OS: ${os}"
    
    # Check if Vivado is installed and use it if available
    if command_exists vivado; then
        log_message "INFO" "Vivado found, using Vivado for simulation"
        if check_tools "vivado"; then
            run_vivado_simulation
        else
            log_message "WARNING" "Falling back to open-source tools"
            if check_tools "simulation"; then
                run_icarus_simulation
            else
                log_message "ERROR" "Required tools for simulation not found"
                exit 1
            fi
        fi
    else
        log_message "INFO" "Vivado not found, using open-source tools"
        if check_tools "simulation"; then
            run_icarus_simulation
        else
            log_message "ERROR" "Required tools for simulation not found"
            exit 1
        fi
    fi
    
    local exit_code=$?
    
    if [[ ${exit_code} -eq 0 ]]; then
        log_message "INFO" "All simulations completed successfully"
    else
        log_message "ERROR" "Some simulations failed"
        exit ${exit_code}
    fi
}

# Call the main function
main
