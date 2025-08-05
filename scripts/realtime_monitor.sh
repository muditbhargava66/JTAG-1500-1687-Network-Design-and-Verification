#!/bin/bash
# Real-time Monitoring System for JTAG/1500/1687 Network Project
# Provides live test progress and resource usage tracking

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Configuration
MONITOR_INTERVAL=2
LOG_FILE="${LOG_DIR}/realtime_monitor.log"
STATUS_FILE="${RESULTS_DIR}/monitor_status.json"
MONITOR_DURATION=300  # 5 minutes default

# Process command line arguments
CONTINUOUS_MODE=0
SHOW_RESOURCES=1
SHOW_PROGRESS=1
TARGET_PROCESS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -h, --help          Show this help message"
            echo "  -c, --continuous    Run in continuous mode"
            echo "  -i, --interval N    Monitor interval in seconds (default: ${MONITOR_INTERVAL})"
            echo "  -d, --duration N    Monitor duration in seconds (default: ${MONITOR_DURATION})"
            echo "  -p, --process NAME  Monitor specific process"
            echo "  --no-resources      Disable resource monitoring"
            echo "  --no-progress       Disable progress monitoring"
            echo ""
            exit 0
            ;;
        -c|--continuous)
            CONTINUOUS_MODE=1
            shift
            ;;
        -i|--interval)
            MONITOR_INTERVAL="$2"
            shift 2
            ;;
        -d|--duration)
            MONITOR_DURATION="$2"
            shift 2
            ;;
        -p|--process)
            TARGET_PROCESS="$2"
            shift 2
            ;;
        --no-resources)
            SHOW_RESOURCES=0
            shift
            ;;
        --no-progress)
            SHOW_PROGRESS=0
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

# Create status file
mkdir -p "$(dirname "${STATUS_FILE}")"

# Function to get system resource usage
get_system_resources() {
    local os=$(detect_os)
    local cpu_usage="N/A"
    local memory_usage="N/A"
    local disk_usage="N/A"
    local load_average="N/A"
    
    case "${os}" in
        macos)
            # CPU usage on macOS
            cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
            
            # Memory usage on macOS
            local memory_info=$(vm_stat | grep -E "(free|active|inactive|wired)")
            local page_size=$(vm_stat | head -1 | grep -o '[0-9]*')
            local free_pages=$(echo "$memory_info" | grep "free" | awk '{print $3}' | sed 's/\.//')
            local total_memory=$(sysctl -n hw.memsize)
            local used_memory=$((total_memory - free_pages * page_size))
            memory_usage=$((used_memory * 100 / total_memory))
            
            # Disk usage
            disk_usage=$(df -h "${ROOT_DIR}" | tail -1 | awk '{print $5}' | sed 's/%//')
            
            # Load average
            load_average=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $1}')
            ;;
        linux)
            # CPU usage on Linux
            cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
            
            # Memory usage on Linux
            local mem_info=$(free | grep Mem)
            local total_mem=$(echo $mem_info | awk '{print $2}')
            local used_mem=$(echo $mem_info | awk '{print $3}')
            memory_usage=$((used_mem * 100 / total_mem))
            
            # Disk usage
            disk_usage=$(df -h "${ROOT_DIR}" | tail -1 | awk '{print $5}' | sed 's/%//')
            
            # Load average
            load_average=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
            ;;
    esac
    
    echo "${cpu_usage},${memory_usage},${disk_usage},${load_average}"
}

# Function to get test progress
get_test_progress() {
    local progress_info=""
    local test_status="idle"
    local current_test=""
    local completion_percent=0
    
    # Check for running simulations
    if pgrep -f "iverilog\|vvp" > /dev/null; then
        test_status="simulation"
        current_test="simulation"
        
        # Estimate progress based on log files
        if [[ -d "${LOG_DIR}" ]]; then
            local log_count=$(find "${LOG_DIR}" -name "*.log" -newer "${LOG_DIR}/../.." 2>/dev/null | wc -l)
            local total_tests=$(find "${TB_DIR}" -name "*.sv" | wc -l)
            if [[ ${total_tests} -gt 0 ]]; then
                completion_percent=$((log_count * 100 / total_tests))
            fi
        fi
    fi
    
    # Check for running synthesis
    if pgrep -f "yosys" > /dev/null; then
        test_status="synthesis"
        current_test="synthesis"
        
        # Estimate progress based on synthesis files
        if [[ -d "${SYN_DIR}" ]]; then
            local syn_count=$(find "${SYN_DIR}" -name "*_synth.v" 2>/dev/null | wc -l)
            local total_modules=$(find "${RTL_DIR}" -name "*.v" | wc -l)
            if [[ ${total_modules} -gt 0 ]]; then
                completion_percent=$((syn_count * 100 / total_modules))
            fi
        fi
    fi
    
    # Check for running coverage analysis
    if pgrep -f "verilator" > /dev/null; then
        test_status="coverage"
        current_test="coverage"
        completion_percent=50  # Estimate
    fi
    
    echo "${test_status},${current_test},${completion_percent}"
}

# Function to monitor specific process
monitor_process() {
    local process_name="$1"
    local pid=""
    local cpu_percent="0"
    local memory_mb="0"
    local runtime="0"
    
    if [[ -n "${process_name}" ]]; then
        pid=$(pgrep -f "${process_name}" | head -1)
        if [[ -n "${pid}" ]]; then
            local os=$(detect_os)
            case "${os}" in
                macos)
                    local ps_info=$(ps -p ${pid} -o %cpu,%mem,etime | tail -1)
                    cpu_percent=$(echo ${ps_info} | awk '{print $1}')
                    memory_mb=$(echo ${ps_info} | awk '{print $2}')
                    runtime=$(echo ${ps_info} | awk '{print $3}')
                    ;;
                linux)
                    local ps_info=$(ps -p ${pid} -o %cpu,%mem,etime | tail -1)
                    cpu_percent=$(echo ${ps_info} | awk '{print $1}')
                    memory_mb=$(echo ${ps_info} | awk '{print $2}')
                    runtime=$(echo ${ps_info} | awk '{print $3}')
                    ;;
            esac
        fi
    fi
    
    echo "${pid},${cpu_percent},${memory_mb},${runtime}"
}

# Function to update status file
update_status_file() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local resources="$1"
    local progress="$2"
    local process_info="$3"
    
    # Parse resource info
    IFS=',' read -r cpu_usage memory_usage disk_usage load_average <<< "${resources}"
    
    # Parse progress info
    IFS=',' read -r test_status current_test completion_percent <<< "${progress}"
    
    # Parse process info
    IFS=',' read -r process_pid process_cpu process_memory process_runtime <<< "${process_info}"
    
    # Create JSON status
    cat > "${STATUS_FILE}" << EOF
{
    "timestamp": "${timestamp}",
    "system": {
        "cpu_usage": "${cpu_usage}",
        "memory_usage": "${memory_usage}",
        "disk_usage": "${disk_usage}",
        "load_average": "${load_average}"
    },
    "test_progress": {
        "status": "${test_status}",
        "current_test": "${current_test}",
        "completion_percent": ${completion_percent}
    },
    "target_process": {
        "pid": "${process_pid}",
        "cpu_percent": "${process_cpu}",
        "memory_mb": "${process_memory}",
        "runtime": "${process_runtime}"
    }
}
EOF
}

# Function to display monitoring dashboard
display_dashboard() {
    local resources="$1"
    local progress="$2"
    local process_info="$3"
    
    # Clear screen and move cursor to top
    clear
    
    echo "========================================"
    echo "  JTAG/1500/1687 Real-time Monitor"
    echo "========================================"
    echo "Time: $(date)"
    echo ""
    
    if [[ ${SHOW_RESOURCES} -eq 1 ]]; then
        echo "System Resources:"
        echo "----------------"
        IFS=',' read -r cpu_usage memory_usage disk_usage load_average <<< "${resources}"
        printf "CPU Usage:    %s%%\n" "${cpu_usage}"
        printf "Memory Usage: %s%%\n" "${memory_usage}"
        printf "Disk Usage:   %s%%\n" "${disk_usage}"
        printf "Load Average: %s\n" "${load_average}"
        echo ""
    fi
    
    if [[ ${SHOW_PROGRESS} -eq 1 ]]; then
        echo "Test Progress:"
        echo "-------------"
        IFS=',' read -r test_status current_test completion_percent <<< "${progress}"
        printf "Status:       %s\n" "${test_status}"
        printf "Current Test: %s\n" "${current_test}"
        printf "Progress:     %s%%\n" "${completion_percent}"
        
        # Progress bar
        local bar_length=40
        local filled_length=$((completion_percent * bar_length / 100))
        local bar=""
        for ((i=0; i<filled_length; i++)); do bar+="="; done
        for ((i=filled_length; i<bar_length; i++)); do bar+="-"; done
        printf "Progress Bar: [%s] %s%%\n" "${bar}" "${completion_percent}"
        echo ""
    fi
    
    if [[ -n "${TARGET_PROCESS}" ]]; then
        echo "Process Monitor (${TARGET_PROCESS}):"
        echo "-----------------------------------"
        IFS=',' read -r process_pid process_cpu process_memory process_runtime <<< "${process_info}"
        if [[ -n "${process_pid}" ]]; then
            printf "PID:          %s\n" "${process_pid}"
            printf "CPU:          %s%%\n" "${process_cpu}"
            printf "Memory:       %s MB\n" "${process_memory}"
            printf "Runtime:      %s\n" "${process_runtime}"
        else
            echo "Process not found or not running"
        fi
        echo ""
    fi
    
    echo "Recent Activity:"
    echo "---------------"
    if [[ -f "${LOG_FILE}" ]]; then
        tail -5 "${LOG_FILE}" | while read line; do
            echo "  ${line}"
        done
    else
        echo "  No recent activity"
    fi
    
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo "========================================"
}

# Function to log monitoring data
log_monitoring_data() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local resources="$1"
    local progress="$2"
    
    echo "${timestamp} - Resources: ${resources} - Progress: ${progress}" >> "${LOG_FILE}"
}

# Main monitoring loop
main_monitor_loop() {
    local start_time=$(date +%s)
    local iteration=0
    
    log_message "INFO" "Starting real-time monitoring (interval: ${MONITOR_INTERVAL}s)"
    
    while true; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        
        # Get monitoring data
        local resources=$(get_system_resources)
        local progress=$(get_test_progress)
        local process_info=$(monitor_process "${TARGET_PROCESS}")
        
        # Update status file
        update_status_file "${resources}" "${progress}" "${process_info}"
        
        # Display dashboard
        display_dashboard "${resources}" "${progress}" "${process_info}"
        
        # Log data
        log_monitoring_data "${resources}" "${progress}"
        
        iteration=$((iteration + 1))
        
        # Check exit conditions
        if [[ ${CONTINUOUS_MODE} -eq 0 && ${elapsed_time} -ge ${MONITOR_DURATION} ]]; then
            log_message "INFO" "Monitoring duration completed (${MONITOR_DURATION}s)"
            break
        fi
        
        # Wait for next iteration
        sleep "${MONITOR_INTERVAL}"
    done
}

# Signal handler for clean exit
cleanup_monitor() {
    log_message "INFO" "Monitoring stopped by user"
    echo ""
    echo "Monitoring session completed."
    echo "Log file: ${LOG_FILE}"
    echo "Status file: ${STATUS_FILE}"
    exit 0
}

# Set up signal handler
trap cleanup_monitor SIGINT SIGTERM

# Main function
main() {
    local os=$(detect_os)
    log_message "INFO" "Real-time monitoring starting on ${os}"
    
    # Create necessary directories
    mkdir -p "${LOG_DIR}"
    mkdir -p "$(dirname "${STATUS_FILE}")"
    
    # Start monitoring
    main_monitor_loop
}

# Run main function
main