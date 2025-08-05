# JTAG/1500/1687 Network Project - Vivado Coverage Analysis Script
# TCL script for Vivado coverage analysis

# Process command line arguments
set testbench ""
set verbose_mode 0
set clean_mode 0

# Parse command-line arguments
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    
    switch -glob -- $arg {
        "-testbench" {
            incr i
            set testbench [lindex $argv $i]
        }
        "-verbose" {
            set verbose_mode 1
        }
        "-clean" {
            set clean_mode 1
        }
        default {
            puts "Warning: Unknown option: $arg"
        }
    }
}

# Set up paths
set script_path [file normalize [info script]]
set script_dir [file dirname $script_path]
set root_dir [file dirname $script_dir]
set src_dir [file join $root_dir "src"]
set rtl_dir [file join $src_dir "rtl"]
set tb_dir [file join $src_dir "tb"]
set results_dir [file join $root_dir "results"]
set cov_dir [file join $results_dir "coverage"]
set report_dir [file join $cov_dir "reports"]
set vivado_dir [file join $cov_dir "vivado_project"]

# Create directories if they don't exist
file mkdir $cov_dir
file mkdir $report_dir

# Set timestamp format
set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]

# Log message function
proc log_message {level message} {
    global timestamp verbose_mode
    
    switch $level {
        "INFO" {
            set color "32"  ;# Green
        }
        "WARNING" {
            set color "33"  ;# Yellow
        }
        "ERROR" {
            set color "31"  ;# Red
        }
        default {
            set color "34"  ;# Blue
        }
    }
    
    if {$verbose_mode || $level != "DEBUG"} {
        puts "\033\[0;${color}m\[$timestamp\] \[$level\] $message\033\[0m"
    }
}

# Clean coverage results if requested
if {$clean_mode} {
    log_message "INFO" "Cleaning coverage results"
    file delete -force [glob -nocomplain "$cov_dir/*"]
    file mkdir $report_dir
}

# Create a new project
proc create_project {} {
    global vivado_dir verbose_mode
    
    log_message "INFO" "Creating Vivado project"
    
    # Create project
    create_project -force coverage_project $vivado_dir -part xc7a100tcsg324-1
    
    # Set HDL language
    set_property target_language Verilog [current_project]
    set_property simulator_language "Mixed" [current_project]
    
    if {$verbose_mode} {
        log_message "DEBUG" "Project created in: $vivado_dir"
    }
}

# Add design files to the project
proc add_design_files {} {
    global rtl_dir verbose_mode
    
    log_message "INFO" "Adding design files to project"
    
    # Add RTL files
    set rtl_files [glob -nocomplain "$rtl_dir/*.v"]
    
    if {[llength $rtl_files] == 0} {
        log_message "ERROR" "No RTL files found in $rtl_dir"
        return 0
    }
    
    # Add files to default fileset
    add_files -norecurse $rtl_files
    
    # Set file properties
    foreach file $rtl_files {
        set_property file_type "Verilog" [get_files $file]
        
        if {$verbose_mode} {
            log_message "DEBUG" "Added RTL file: $file"
        }
    }
    
    return 1
}

# Add test bench files to the project
proc add_testbench_files {{specific_tb ""}} {
    global tb_dir verbose_mode
    
    log_message "INFO" "Adding testbench files to project"
    
    # Create simulation fileset if it doesn't exist
    if {[string equal [get_filesets -quiet sim_1] ""]} {
        create_fileset -simset sim_1
    }
    
    # Add testbench files
    if {$specific_tb != ""} {
        set tb_file "$tb_dir/${specific_tb}.sv"
        
        if {![file exists $tb_file]} {
            log_message "ERROR" "Testbench file not found: $tb_file"
            return 0
        }
        
        add_files -fileset sim_1 -norecurse $tb_file
        set_property file_type "SystemVerilog" [get_files -fileset sim_1 $tb_file]
        set_property top $specific_tb [get_filesets sim_1]
        
        if {$verbose_mode} {
            log_message "DEBUG" "Added testbench file: $tb_file"
            log_message "DEBUG" "Set top module to: $specific_tb"
        }
    } else {
        set tb_files [glob -nocomplain "$tb_dir/*.sv"]
        
        if {[llength $tb_files] == 0} {
            log_message "ERROR" "No testbench files found in $tb_dir"
            return 0
        }
        
        add_files -fileset sim_1 -norecurse $tb_files
        
        # Set file properties
        foreach file $tb_files {
            set_property file_type "SystemVerilog" [get_files -fileset sim_1 $file]
            
            if {$verbose_mode} {
                log_message "DEBUG" "Added testbench file: $file"
            }
        }
        
        # Set top module (tb_top_module if available, otherwise first one alphabetically)
        if {[file exists "$tb_dir/tb_top_module.sv"]} {
            set_property top tb_top_module [get_filesets sim_1]
            
            if {$verbose_mode} {
                log_message "DEBUG" "Set top module to: tb_top_module"
            }
        } else {
            set top_tb [file rootname [file tail [lindex [lsort $tb_files] 0]]]
            set_property top $top_tb [get_filesets sim_1]
            
            if {$verbose_mode} {
                log_message "DEBUG" "Set top module to: $top_tb"
            }
        }
    }
    
    return 1
}

# Enable coverage collection
proc enable_coverage {} {
    global verbose_mode
    
    log_message "INFO" "Enabling coverage collection"
    
    # Enable coverage collection for simulation
    set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg COVERAGE} -objects [get_filesets sim_1]
    set_property -name {xsim.compile.xvlog.more_options} -value {-coverage all} -objects [get_filesets sim_1]
    
    if {$verbose_mode} {
        log_message "DEBUG" "Enabled coverage collection for simulation"
    }
}

# Run simulation with coverage
proc run_simulation_with_coverage {{specific_tb ""}} {
    global cov_dir report_dir
    global verbose_mode
    
    if {$specific_tb != ""} {
        log_message "INFO" "Running simulation with coverage for testbench: $specific_tb"
    } else {
        set specific_tb [get_property top [get_filesets sim_1]]
        log_message "INFO" "Running simulation with coverage for testbench: $specific_tb"
    }
    
    # Set simulation properties
    set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
    
    # Set coverage filename
    set_property -name {xsim.simulate.saif} -value "$report_dir/${specific_tb}.saif" -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.saif_all_signals} -value {true} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.saif_scope} -value {all} -objects [get_filesets sim_1]
    
    # Launch simulation
    launch_simulation -simset sim_1 -mode behavioral
    
    # Run simulation
    log_message "INFO" "Running simulation with coverage enabled"
    run 1000ns
    
    # Generate coverage report
    log_message "INFO" "Generating coverage report"
    
    # Save coverage data
    set report_file "$report_dir/${specific_tb}_coverage.txt"
    
    # Generate summary report
    open_saif "$report_dir/${specific_tb}.saif"
    report_switching_activity -file "$report_dir/${specific_tb}_switching.rpt"
    report_power -file "$report_dir/${specific_tb}_power.rpt"
    
    # Generate a simplified coverage report
    set fh [open $report_file w]
    puts $fh "Coverage Report for $specific_tb"
    puts $fh "============================="
    puts $fh "Date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $fh ""
    puts $fh "Coverage Summary:"
    puts $fh "  Signal Toggle Coverage: [exec grep "Average toggle" $report_dir/${specific_tb}_switching.rpt | awk {{print $4}}]"
    puts $fh "  Lines: N/A (Vivado XSim does not directly report line coverage)"
    puts $fh "  Branches: N/A (Vivado XSim does not directly report branch coverage)"
    puts $fh ""
    puts $fh "Detailed reports:"
    puts $fh "  Switching activity report: $report_dir/${specific_tb}_switching.rpt"
    puts $fh "  Power report: $report_dir/${specific_tb}_power.rpt"
    puts $fh "  SAIF file: $report_dir/${specific_tb}.saif"
    close $fh
    
    log_message "INFO" "Coverage report generated: $report_file"
    
    # Close simulation
    close_sim
    
    return 1
}

# Main procedure
proc main {} {
    global testbench verbose_mode
    
    if {$verbose_mode} {
        log_message "DEBUG" "Starting Vivado coverage analysis script"
    }
    
    # Create project
    create_project
    
    # Add design files
    if {![add_design_files]} {
        log_message "ERROR" "Failed to add design files"
        return 1
    }
    
    # Add testbench files
    if {![add_testbench_files $testbench]} {
        log_message "ERROR" "Failed to add testbench files"
        return 1
    }
    
    # Enable coverage collection
    enable_coverage
    
    # Run simulation with coverage
    if {![run_simulation_with_coverage $testbench]} {
        log_message "ERROR" "Failed to run simulation with coverage"
        return 1
    }
    
    log_message "INFO" "Vivado coverage analysis completed successfully"
    return 0
}

# Run the main procedure
if {[catch {main} result]} {
    log_message "ERROR" "Vivado coverage analysis script failed: $result"
    exit 1
} else {
    exit $result
}