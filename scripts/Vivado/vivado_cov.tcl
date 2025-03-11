# Vivado Coverage Analysis TCL Script
# This script sets up and runs coverage analysis in Vivado

# Set up paths
set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]
set root_dir [file dirname $script_dir]
set rtl_dir "$root_dir/src/rtl"
set tb_dir "$root_dir/src/tb" 
set cov_dir "$root_dir/results/coverage"
set report_dir "$cov_dir/reports"

# Create directories if they don't exist
file mkdir $cov_dir
file mkdir $report_dir

# Create a new project
create_project -force coverage_project $cov_dir/vivado_project -part xc7a100tcsg324-1

# Add source files
add_files -norecurse [glob $rtl_dir/*.v]
add_files -norecurse -fileset sim_1 [glob $tb_dir/*.sv]

# Find all test bench files
set tb_files [glob -nocomplain "$tb_dir/*.sv"]

# Run coverage for each testbench
foreach tb_file $tb_files {
    set tb_name [file rootname [file tail $tb_file]]
    puts "Running coverage analysis for testbench: $tb_name"
    
    # Set the current testbench as top module
    set_property top $tb_name [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]
    
    # Set coverage options
    set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.saif_all_signals} -value {true} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.saif_scope} -value {all} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.saif} -value "$report_dir/${tb_name}.saif" -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg COVERAGE} -objects [get_filesets sim_1]
    set_property -name {xsim.compile.xvlog.more_options} -value {-coverage all} -objects [get_filesets sim_1]
    
    # Launch simulation
    launch_simulation -simset sim_1 -mode behavioral
    
    # Run simulation
    run 1000ns
    
    # Close simulation
    close_sim
    
    # Generate coverage report
    open_saif "$report_dir/${tb_name}.saif"
    report_switching_activity -file "$report_dir/${tb_name}_switching.rpt"
    report_power -file "$report_dir/${tb_name}_power.rpt"
    
    puts "Coverage analysis completed for: $tb_name"
}

puts "All coverage analysis tasks completed"
close_project