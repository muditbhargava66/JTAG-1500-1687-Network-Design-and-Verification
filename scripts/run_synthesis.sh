#!/bin/bash

# Script to run synthesis using open-source tools (Yosys) or Vivado

# Check for the existence of necessary directories
if [ ! -d "src/rtl" ]; then
    echo "RTL directory not found!"
    exit 1
fi

# Define directories and files
RTL_DIR="src/rtl"
SYN_DIR="results/synthesis"
REPORT_DIR="$SYN_DIR/reports"

# Create directories if they don't exist
mkdir -p $REPORT_DIR

# Function to run synthesis with Yosys
run_yosys_synthesis() {
    echo "Running synthesis with Yosys..."
    yosys -p "synth -top top_module; write_json $SYN_DIR/top_module.json" $RTL_DIR/*.v
    yosys -p "proc; opt; memory; write_verilog $SYN_DIR/top_module_synth.v" $SYN_DIR/top_module.json
}

# Function to run synthesis with Vivado
run_vivado_synthesis() {
    echo "Running synthesis with Vivado..."
    vivado -mode batch -source scripts/vivado_syn.tcl
}

# Check if Vivado is installed
if command -v vivado &> /dev/null; then
    run_vivado_synthesis
else
    run_yosys_synthesis
fi

echo "Synthesis completed!"
