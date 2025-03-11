#!/bin/bash

# Script to analyze coverage using Verilator

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

echo "Running Verilator simulation with coverage..."

# Process each testbench separately
for tb_file in $TB_DIR/*.sv; do
    tb_name=$(basename $tb_file .sv)
    echo "Processing testbench: $tb_name"
    
    # Create a top-level wrapper for Verilator
    cat > ${tb_name}_main.cpp << EOF
#include "V${tb_name}.h"
#include "verilated.h"
#include "verilated_cov.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    V${tb_name}* top = new V${tb_name};
    
    // Run simulation for a fixed number of cycles
    for (int i = 0; i < 1000 && !Verilated::gotFinish(); i++) {
        top->eval();
    }
    
    // Generate coverage data
    VerilatedCov::write("${REPORT_DIR}/${tb_name}_coverage.dat");
    
    delete top;
    return 0;
}
EOF
    
    # Compile with Verilator using timing flag
    verilator --timing --cc --exe --coverage \
              -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-MULTIDRIVEN \
              --build ${tb_name}_main.cpp \
              -I${RTL_DIR} $RTL_DIR/*.v $tb_file \
              --top-module ${tb_name} \
              -o ${tb_name}
    
    if [ $? -eq 0 ]; then
        echo "✅ Testbench ${tb_name} compiled successfully"
        
        # Run the simulation
        ./obj_dir/${tb_name}
        
        if [ -f "${REPORT_DIR}/${tb_name}_coverage.dat" ]; then
            echo "✅ Coverage data generated for ${tb_name}"
            
            # Generate HTML coverage report
            verilator_coverage --annotate ${REPORT_DIR}/${tb_name}_annotated \
                              ${REPORT_DIR}/${tb_name}_coverage.dat
        else
            echo "❌ No coverage data generated for ${tb_name}"
        fi
    else
        echo "❌ Failed to compile testbench ${tb_name}"
    fi
    
    # Clean up
    rm -f ${tb_name}_main.cpp
done

echo "Coverage analysis completed!"