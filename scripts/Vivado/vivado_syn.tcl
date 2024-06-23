# Vivado TCL script for running synthesis

# Set up project
set project_name "synthesis_project"
create_project $project_name ./ -part xc7z020clg400-1

# Add sources
add_files -norecurse ../src/rtl/*.v

# Set top module for synthesis
set_property top top_module [current_fileset]

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Report synthesis results
report_utilization -file ../results/synthesis/reports/utilization.rpt
report_timing_summary -file ../results/synthesis/reports/timing_summary.rpt
