# Vivado TCL script for running coverage analysis

# Set up project
set project_name "coverage_project"
create_project $project_name ./ -part xc7z020clg400-1

# Add sources
add_files -norecurse ../src/rtl/*.v
add_files -norecurse ../src/tb/*.sv

# Set top module for simulation
set_property top tb_top_module [get_filesets sim_1]

# Enable coverage
set_property coverage_enabled true [get_filesets sim_1]

# Run simulation with coverage
launch_simulation
write_coverage -dir ../results/coverage/reports -name coverage_report
