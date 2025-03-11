# Vivado Synthesis TCL Script
# This script sets up and runs synthesis in Vivado

# Set up paths
set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]
set root_dir [file dirname $script_dir]
set rtl_dir "$root_dir/src/rtl"
set syn_dir "$root_dir/results/synthesis"
set report_dir "$syn_dir/reports"

# Create directories if they don't exist
file mkdir $syn_dir
file mkdir $report_dir

# Create a new project
create_project -force synthesis_project $syn_dir/vivado_project -part xc7a100tcsg324-1

# Add source files
add_files -norecurse [glob $rtl_dir/*.v]

# Set top module
set_property top top_module [current_fileset]

# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Generate reports
open_run synth_1
report_timing_summary -file $report_dir/timing_summary.rpt
report_utilization -file $report_dir/utilization.rpt
report_power -file $report_dir/power.rpt
report_design_analysis -file $report_dir/design_analysis.rpt

# Export synthesized netlist
write_verilog -force $syn_dir/top_module_synth.v
write_xdc -force $syn_dir/top_module_synth.xdc

# Close project
close_project

puts "Synthesis completed. Reports and netlists saved in $syn_dir"