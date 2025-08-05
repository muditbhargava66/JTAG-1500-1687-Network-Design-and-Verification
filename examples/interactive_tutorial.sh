#!/bin/bash
# Interactive Tutorial System for JTAG/1500/1687 Network Project
# Provides step-by-step guided examples with validation

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${ROOT_DIR}/scripts/common.sh"

# Tutorial configuration
TUTORIAL_MODE="beginner"
CURRENT_STEP=1
TOTAL_STEPS=10
VALIDATION_ENABLED=1

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -h, --help          Show this help message"
            echo "  -m, --mode MODE     Tutorial mode: beginner, intermediate, advanced"
            echo "  -s, --step N        Start from specific step"
            echo "  --no-validation     Skip validation steps"
            echo ""
            echo "Tutorial Modes:"
            echo "  beginner     - Basic JTAG operations and concepts"
            echo "  intermediate - IEEE 1500/1687 integration"
            echo "  advanced     - Custom testing and optimization"
            echo ""
            exit 0
            ;;
        -m|--mode)
            TUTORIAL_MODE="$2"
            shift 2
            ;;
        -s|--step)
            CURRENT_STEP="$2"
            shift 2
            ;;
        --no-validation)
            VALIDATION_ENABLED=0
            shift
            ;;
        *)
            log_message "ERROR" "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Initialize environment
init_environment "$(basename "$0")"

# Function to display tutorial header
show_tutorial_header() {
    clear
    echo "=================================================="
    echo "  JTAG/1500/1687 Network Interactive Tutorial"
    echo "=================================================="
    echo "Mode: ${TUTORIAL_MODE}"
    echo "Step: ${CURRENT_STEP}/${TOTAL_STEPS}"
    echo ""
}

# Function to wait for user input
wait_for_user() {
    local message="$1"
    echo ""
    echo "${message}"
    echo "Press Enter to continue, 'q' to quit, 'r' to repeat step..."
    read -r user_input
    
    case "${user_input}" in
        q|Q|quit|exit)
            echo "Tutorial ended by user."
            exit 0
            ;;
        r|R|repeat)
            return 1  # Signal to repeat step
            ;;
        *)
            return 0  # Continue
            ;;
    esac
}

# Function to validate step completion
validate_step() {
    local step_number="$1"
    local validation_command="$2"
    local expected_result="$3"
    
    if [[ ${VALIDATION_ENABLED} -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    echo "Validating step ${step_number}..."
    
    # Execute validation command
    local result
    if [[ -n "${validation_command}" ]]; then
        result=$(eval "${validation_command}" 2>/dev/null)
        
        if [[ "${result}" == *"${expected_result}"* ]]; then
            echo "✓ Step ${step_number} validation: PASSED"
            return 0
        else
            echo "✗ Step ${step_number} validation: FAILED"
            echo "Expected: ${expected_result}"
            echo "Got: ${result}"
            
            echo ""
            echo "Would you like to:"
            echo "1. Continue anyway (c)"
            echo "2. Repeat this step (r)"
            echo "3. Quit tutorial (q)"
            read -r choice
            
            case "${choice}" in
                c|C|continue) return 0 ;;
                r|R|repeat) return 1 ;;
                q|Q|quit) exit 0 ;;
                *) return 1 ;;
            esac
        fi
    fi
    
    return 0
}

# Function to run beginner tutorial
run_beginner_tutorial() {
    case ${CURRENT_STEP} in
        1)
            show_tutorial_header
            echo "Step 1: Environment Setup and Tool Check"
            echo "========================================"
            echo ""
            echo "Welcome to the JTAG/1500/1687 Network tutorial!"
            echo ""
            echo "First, let's check that all required tools are installed."
            echo "We'll run the environment check command:"
            echo ""
            echo "Command: make check-env"
            echo ""
            
            if wait_for_user "Ready to check your environment?"; then
                cd "${ROOT_DIR}"
                make check-env
                
                if validate_step 1 "make check-env 2>&1 | grep -c 'found'" "4"; then
                    CURRENT_STEP=2
                else
                    echo ""
                    echo "Some tools may be missing. You can install them with:"
                    echo "./scripts/install_tools.sh"
                fi
            fi
            ;;
            
        2)
            show_tutorial_header
            echo "Step 2: Understanding the Project Structure"
            echo "=========================================="
            echo ""
            echo "Let's explore the project structure:"
            echo ""
            echo "src/rtl/     - RTL source files (Verilog)"
            echo "src/tb/      - Testbench files (SystemVerilog)"
            echo "scripts/     - Build and utility scripts"
            echo "examples/    - Example configurations and tutorials"
            echo "results/     - Generated results and reports"
            echo ""
            echo "Key files:"
            echo "- src/rtl/jtag_controller.v    - Main JTAG controller"
            echo "- src/rtl/ieee1500_wrapper.v   - IEEE 1500 wrapper"
            echo "- src/rtl/ieee1687_network.v   - IEEE 1687 network"
            echo ""
            
            if wait_for_user "Ready to see the file structure?"; then
                echo "Project structure:"
                ls -la "${ROOT_DIR}/src/rtl/"
                echo ""
                echo "Testbench files:"
                ls -la "${ROOT_DIR}/src/tb/" | head -10
                
                if validate_step 2 "ls ${ROOT_DIR}/src/rtl/*.v | wc -l" "5"; then
                    CURRENT_STEP=3
                fi
            fi
            ;;
            
        3)
            show_tutorial_header
            echo "Step 3: Running Your First Simulation"
            echo "====================================="
            echo ""
            echo "Now let's run a simple JTAG controller simulation."
            echo ""
            echo "This will:"
            echo "1. Compile the JTAG controller RTL"
            echo "2. Compile the testbench"
            echo "3. Run the simulation"
            echo "4. Generate a waveform file"
            echo ""
            echo "Command: make sim-tb_jtag_controller"
            echo ""
            
            if wait_for_user "Ready to run your first simulation?"; then
                cd "${ROOT_DIR}"
                make sim-tb_jtag_controller
                
                if validate_step 3 "ls ${ROOT_DIR}/results/simulation/waveforms/tb_jtag_controller.vcd" "tb_jtag_controller.vcd"; then
                    echo ""
                    echo "Great! Your simulation completed successfully."
                    echo "A waveform file was generated at:"
                    echo "results/simulation/waveforms/tb_jtag_controller.vcd"
                    CURRENT_STEP=4
                fi
            fi
            ;;
            
        4)
            show_tutorial_header
            echo "Step 4: Understanding JTAG States"
            echo "================================="
            echo ""
            echo "The JTAG controller implements a 16-state state machine:"
            echo ""
            echo "Test-Logic-Reset → Run-Test/Idle → Select-DR-Scan → ..."
            echo ""
            echo "Key states:"
            echo "- Test-Logic-Reset: Initial state after reset"
            echo "- Run-Test/Idle: Stable state between operations"
            echo "- Shift-DR: Shifting data through data registers"
            echo "- Shift-IR: Shifting instructions through instruction register"
            echo ""
            echo "Let's examine the simulation log to see state transitions:"
            echo ""
            
            if wait_for_user "Ready to examine the simulation results?"; then
                if [[ -f "${ROOT_DIR}/results/simulation/logs/tb_jtag_controller.log" ]]; then
                    echo "Recent simulation log entries:"
                    tail -20 "${ROOT_DIR}/results/simulation/logs/tb_jtag_controller.log"
                else
                    echo "Log file not found. The simulation may not have completed successfully."
                fi
                
                if validate_step 4 "grep -c 'State:' ${ROOT_DIR}/results/simulation/logs/tb_jtag_controller.log 2>/dev/null || echo 0" "1"; then
                    CURRENT_STEP=5
                fi
            fi
            ;;
            
        5)
            show_tutorial_header
            echo "Step 5: Running All Simulations"
            echo "==============================="
            echo ""
            echo "Now let's run all the testbenches to see the complete system:"
            echo ""
            echo "This will simulate:"
            echo "- JTAG Controller"
            echo "- IEEE 1500 Wrapper"
            echo "- IEEE 1687 Network"
            echo "- Boundary Scan Chain"
            echo "- Top Module Integration"
            echo ""
            echo "Command: make sim"
            echo ""
            
            if wait_for_user "Ready to run all simulations? (This may take a minute)"; then
                cd "${ROOT_DIR}"
                make sim
                
                local sim_count=$(find "${ROOT_DIR}/results/simulation/waveforms" -name "*.vcd" 2>/dev/null | wc -l)
                if validate_step 5 "echo ${sim_count}" "6"; then
                    echo ""
                    echo "Excellent! All simulations completed."
                    echo "Generated waveform files:"
                    ls -la "${ROOT_DIR}/results/simulation/waveforms/"
                    CURRENT_STEP=6
                fi
            fi
            ;;
            
        6)
            show_tutorial_header
            echo "Step 6: Synthesis - Converting to Hardware"
            echo "=========================================="
            echo ""
            echo "Synthesis converts your RTL code into a gate-level netlist."
            echo "This step verifies that your design can be implemented in hardware."
            echo ""
            echo "The synthesis process will:"
            echo "1. Parse and elaborate the RTL"
            echo "2. Optimize the logic"
            echo "3. Generate a gate-level netlist"
            echo "4. Provide resource utilization reports"
            echo ""
            echo "Command: make syn"
            echo ""
            
            if wait_for_user "Ready to synthesize the design?"; then
                cd "${ROOT_DIR}"
                make syn
                
                if validate_step 6 "ls ${ROOT_DIR}/results/synthesis/*_synth.v 2>/dev/null | wc -l" "1"; then
                    echo ""
                    echo "Synthesis completed! Let's look at the resource usage:"
                    if [[ -f "${ROOT_DIR}/results/synthesis/reports/top_module_stats.rpt" ]]; then
                        echo ""
                        echo "Resource utilization:"
                        head -20 "${ROOT_DIR}/results/synthesis/reports/top_module_stats.rpt"
                    fi
                    CURRENT_STEP=7
                fi
            fi
            ;;
            
        7)
            show_tutorial_header
            echo "Step 7: Coverage Analysis"
            echo "========================"
            echo ""
            echo "Coverage analysis helps ensure your tests exercise all parts of the design."
            echo ""
            echo "Types of coverage:"
            echo "- Line coverage: Which lines of code were executed"
            echo "- Branch coverage: Which decision branches were taken"
            echo "- Toggle coverage: Which signals changed state"
            echo ""
            echo "Command: make cov"
            echo ""
            
            if wait_for_user "Ready to run coverage analysis?"; then
                cd "${ROOT_DIR}"
                make cov
                
                local cov_files=$(find "${ROOT_DIR}/results/coverage" -name "*.log" 2>/dev/null | wc -l)
                if validate_step 7 "echo ${cov_files}" "6"; then
                    echo ""
                    echo "Coverage analysis completed!"
                    echo "Coverage reports are available in results/coverage/"
                    CURRENT_STEP=8
                fi
            fi
            ;;
            
        8)
            show_tutorial_header
            echo "Step 8: Generating HTML Reports"
            echo "==============================="
            echo ""
            echo "HTML reports provide a professional summary of all test results."
            echo ""
            echo "The report includes:"
            echo "- Test execution summary"
            echo "- Pass/fail status for each test"
            echo "- Resource utilization from synthesis"
            echo "- Coverage metrics"
            echo ""
            echo "Command: make html-report"
            echo ""
            
            if wait_for_user "Ready to generate an HTML report?"; then
                cd "${ROOT_DIR}"
                make html-report
                
                if validate_step 8 "ls ${ROOT_DIR}/results/html_reports/latest.html" "latest.html"; then
                    echo ""
                    echo "HTML report generated successfully!"
                    echo "You can open it in your browser:"
                    echo "file://${ROOT_DIR}/results/html_reports/latest.html"
                    CURRENT_STEP=9
                fi
            fi
            ;;
            
        9)
            show_tutorial_header
            echo "Step 9: Using the GUI Controller"
            echo "==============================="
            echo ""
            echo "The GUI controller provides a graphical interface for managing tests."
            echo ""
            echo "Features:"
            echo "- Visual test control and monitoring"
            echo "- Real-time progress tracking"
            echo "- Results visualization"
            echo "- Environment management"
            echo ""
            echo "To launch the GUI:"
            echo "python3 scripts/gui_controller.py"
            echo ""
            echo "Note: Requires Python 3 with Tkinter support"
            echo ""
            
            if wait_for_user "Would you like to see the GUI? (It will open in a new window)"; then
                if command_exists python3; then
                    echo "Launching GUI controller..."
                    echo "(Close the GUI window to continue the tutorial)"
                    cd "${ROOT_DIR}"
                    python3 scripts/gui_controller.py &
                    local gui_pid=$!
                    
                    echo ""
                    echo "GUI launched with PID: ${gui_pid}"
                    echo "You can explore the interface and then close it to continue."
                    
                    wait_for_user "GUI exploration complete?"
                    CURRENT_STEP=10
                else
                    echo "Python 3 not found. Skipping GUI demonstration."
                    CURRENT_STEP=10
                fi
            fi
            ;;
            
        10)
            show_tutorial_header
            echo "Step 10: Tutorial Complete!"
            echo "=========================="
            echo ""
            echo "Congratulations! You've completed the beginner tutorial."
            echo ""
            echo "You've learned how to:"
            echo "✓ Check your development environment"
            echo "✓ Run individual and complete simulations"
            echo "✓ Synthesize RTL designs"
            echo "✓ Analyze test coverage"
            echo "✓ Generate professional HTML reports"
            echo "✓ Use the GUI controller interface"
            echo ""
            echo "Next steps:"
            echo "- Try the intermediate tutorial: $0 --mode intermediate"
            echo "- Explore the examples in the examples/ directory"
            echo "- Read the documentation in docs/"
            echo "- Experiment with your own test scenarios"
            echo ""
            echo "Resources:"
            echo "- Project README: README.md"
            echo "- Contributing guide: CONTRIBUTING.md"
            echo "- Future roadmap: FUTURE.md"
            echo ""
            
            wait_for_user "Tutorial completed! Press Enter to exit."
            echo "Thank you for using the JTAG/1500/1687 Network tutorial!"
            exit 0
            ;;
    esac
}

# Function to run intermediate tutorial
run_intermediate_tutorial() {
    echo "Intermediate tutorial coming soon!"
    echo "This will cover IEEE 1500/1687 integration and advanced testing."
    exit 0
}

# Function to run advanced tutorial
run_advanced_tutorial() {
    echo "Advanced tutorial coming soon!"
    echo "This will cover custom testing, optimization, and development."
    exit 0
}

# Main tutorial loop
main_tutorial_loop() {
    while [[ ${CURRENT_STEP} -le ${TOTAL_STEPS} ]]; do
        case "${TUTORIAL_MODE}" in
            beginner)
                run_beginner_tutorial
                ;;
            intermediate)
                run_intermediate_tutorial
                ;;
            advanced)
                run_advanced_tutorial
                ;;
            *)
                log_message "ERROR" "Unknown tutorial mode: ${TUTORIAL_MODE}"
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    log_message "INFO" "Starting interactive tutorial (mode: ${TUTORIAL_MODE})"
    
    # Set total steps based on mode
    case "${TUTORIAL_MODE}" in
        beginner) TOTAL_STEPS=10 ;;
        intermediate) TOTAL_STEPS=8 ;;
        advanced) TOTAL_STEPS=6 ;;
    esac
    
    # Validate step number
    if [[ ${CURRENT_STEP} -lt 1 || ${CURRENT_STEP} -gt ${TOTAL_STEPS} ]]; then
        log_message "ERROR" "Invalid step number: ${CURRENT_STEP} (valid range: 1-${TOTAL_STEPS})"
        exit 1
    fi
    
    # Start tutorial
    main_tutorial_loop
}

# Run main function
main