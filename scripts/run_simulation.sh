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
        echo "Simulating $tb_name..."

        # Create a temporary file that adds VCD generation to the testbench
        tmp_tb_file="${tb_name}_with_vcd.sv"
        
        # Check if the testbench already has $dumpfile or $dumpvars
        if grep -q "dumpfile\|dumpvars" "$tb_file"; then
            # Already has dump commands, just compile as is
            cp "$tb_file" "$tmp_tb_file"
        else
            # Add VCD dump commands to the testbench
            awk '
            /initial begin/ {
                print $0;
                print "        // VCD dump commands added by script";
                print "        $dumpfile(\"'$WAVEFORM_DIR'/'$tb_name'.vcd\");";
                print "        $dumpvars(0, '$tb_name');";
                next;
            }
            {print}
            ' "$tb_file" > "$tmp_tb_file"
        fi
        
        # Compile the testbench
        iverilog -g2012 -o $SIM_DIR/${tb_name}.vvp -s ${tb_name} $RTL_DIR/*.v "$tmp_tb_file"
        
        if [ $? -eq 0 ]; then
            echo "Compilation successful for $tb_name"
            
            # Run the simulation
            vvp $SIM_DIR/${tb_name}.vvp > $LOG_DIR/${tb_name}.log
            
            if [ -f "$WAVEFORM_DIR/${tb_name}.vcd" ]; then
                echo "✅ Waveform generated: $WAVEFORM_DIR/${tb_name}.vcd"
                
                # Open the waveform file with appropriate viewer
                if command -v surfer &> /dev/null; then
                    surfer "$WAVEFORM_DIR/${tb_name}.vcd" &
                    echo "Opened waveform with surfer"
                elif command -v gtkwave &> /dev/null; then
                    gtkwave "$WAVEFORM_DIR/${tb_name}.vcd" &
                    echo "Opened waveform with gtkwave"
                else
                    echo "No waveform viewer found (surfer or gtkwave). Please install one to view waveforms."
                fi
            else
                echo "❌ No waveform file generated for $tb_name"
                # This might happen if the simulation exited before generating VCD
                # Try a direct approach
                echo "Trying alternative approach for VCD generation..."
                iverilog -g2012 -o $SIM_DIR/${tb_name}_alt.vvp -s ${tb_name} $RTL_DIR/*.v "$tb_file"
                vvp $SIM_DIR/${tb_name}_alt.vvp -vcd=$WAVEFORM_DIR/${tb_name}.vcd > $LOG_DIR/${tb_name}_alt.log
                
                if [ -f "$WAVEFORM_DIR/${tb_name}.vcd" ]; then
                    echo "✅ Waveform generated using alternative method"
                    
                    if command -v surfer &> /dev/null; then
                        surfer "$WAVEFORM_DIR/${tb_name}.vcd" &
                    elif command -v gtkwave &> /dev/null; then
                        gtkwave "$WAVEFORM_DIR/${tb_name}.vcd" &
                    fi
                else
                    echo "❌ Failed to generate waveform with alternative method"
                fi
            fi
        else
            echo "❌ Compilation failed for $tb_name"
        fi
        
        # Clean up temporary file
        rm -f "$tmp_tb_file"
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