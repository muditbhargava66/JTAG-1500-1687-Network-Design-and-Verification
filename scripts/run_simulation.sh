#!/bin/bash

# Script to run simulations using open-source tools (Icarus Verilog) or Vivado

# Check for the existence of necessary directories
if [ ! -d "src/rtl" ] || [ ! -d "src/tb" ]; then
    echo "RTL or Testbench directories not found!"
    exit 1
fi

# Define directories and files
RTL_DIR="src/rtl"
TB_DIR="src/tb"
SIM_DIR="results/simulation"
WAVEFORM_DIR="$SIM_DIR/waveforms"
LOG_DIR="$SIM_DIR/logs"

# Create directories if they don't exist
mkdir -p $WAVEFORM_DIR $LOG_DIR

# Function to run simulation with Icarus Verilog
run_icarus_simulation() {
    echo "Running simulations with Icarus Verilog..."
    for tb_file in $TB_DIR/*.sv; do
        tb_name=$(basename $tb_file .sv)
        iverilog -o $SIM_DIR/${tb_name}.vvp -s ${tb_name} $RTL_DIR/*.v $tb_file
        vvp $SIM_DIR/${tb_name}.vvp > $LOG_DIR/${tb_name}.log

        # Move VCD files to waveform directory if they exist
        if [ -f ${tb_name}.vcd ]; then
            mv ${tb_name}.vcd $WAVEFORM_DIR/
        fi

        # Open the waveform file with Surfer
        /Applications/surfer $WAVEFORM_DIR/${tb_name}.vcd &
    done
}

# Function to run simulation with Vivado
run_vivado_simulation() {
    echo "Running simulations with Vivado..."
    vivado -mode batch -source scripts/vivado_sim.tcl
}

# Check if Vivado is installed
if command -v vivado &> /dev/null; then
    run_vivado_simulation
else
    run_icarus_simulation
fi

echo "Simulation completed!"
