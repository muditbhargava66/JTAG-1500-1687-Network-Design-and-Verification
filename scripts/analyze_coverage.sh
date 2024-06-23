#!/bin/bash

# Script to analyze coverage using open-source tools (Verilator) or Vivado

# Check for the existence of necessary directories
if [ ! -d "src/rtl" ] || [ ! -d "src/tb" ]; then
    echo "RTL or Testbench directories not found!"
    exit 1
fi

# Define directories and files
RTL_DIR="src/rtl"
TB_DIR="src/tb"
COV_DIR="results/coverage"
REPORT_DIR="$COV_DIR/reports"

# Create directories if they don't exist
mkdir -p $REPORT_DIR

# Function to run coverage analysis with Verilator
run_verilator_coverage() {
    echo "Running coverage analysis with Verilator..."
    for tb_file in $TB_DIR/*.sv; do
        tb_name=$(basename $tb_file .sv)
        verilator --timing --coverage --cc $RTL_DIR/*.v --exe $tb_file --top-module ${tb_name}
        make -j -C obj_dir -f V${tb_name}.mk V${tb_name}
        obj_dir/V${tb_name}
        verilator_coverage --write $REPORT_DIR/${tb_name}.info
    done
}

# Function to run coverage analysis with Vivado
run_vivado_coverage() {
    echo "Running coverage analysis with Vivado..."
    vivado -mode batch -source scripts/vivado_cov.tcl
}

# Check if Vivado is installed
if command -v vivado &> /dev/null; then
    run_vivado_coverage
else
    run_verilator_coverage
fi

echo "Coverage analysis completed!"
