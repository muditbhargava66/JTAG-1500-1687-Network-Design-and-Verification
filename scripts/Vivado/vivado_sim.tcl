# JTAG/1500/1687 Network Project - Vivado Simulation Script
# TCL script for Vivado simulation

# Process command line arguments
set testbench ""
set gui_mode 0
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
        "-gui" {
            set gui_mode 1
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
set sim_dir [file join $results_dir "simulation"]
set log_dir [file join $sim_dir "logs"]
set waveform_dir [file join $sim_dir "waveforms"]
set report_dir [file join $sim_dir "reports"]

# Create directories if they don't exist
file mkdir $sim_dir
file mkdir $log_dir
file mkdir $waveform_dir
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

# Clean simulation results if requested
if {$clean_mode} {
    log_message "INFO" "Cleaning simulation results"
    file delete -force [glob -nocomplain "$sim_dir/*"]
    file mkdir $log_dir
    file mkdir $waveform_dir
    file mkdir $report_dir
}

# Create a new project
proc create_project_in_memory {} {
    global verbose_mode
    
    log_message "INFO" "Creating Vivado project in memory"
    
    # Create project in memory
    create_project -in_memory -part xc7a100tcsg324-1
    
    # Add HDL language support
    set_property target_language Verilog [current_project]
    
    # Use SystemVerilog for test benches
    set_property simulator_language "Mixed" [current_project]
    
    if {$verbose_mode} {
        log_message "DEBUG" "Project created with part: xc7a100tcsg324-1"
    }
}

# Add design files to the project
proc add_design_files {} {
    global rtl_dir
    global verbose_mode
    
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
    global tb_dir
    global verbose_mode
    
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

# Run simulation for a specific testbench
proc run_simulation {{specific_tb ""}} {
    global sim_dir log_dir waveform_dir report_dir
    global gui_mode verbose_mode
    
    if {$specific_tb != ""} {
        log_message "INFO" "Running simulation for testbench: $specific_tb"
    } else {
        set specific_tb [get_property top [get_filesets sim_1]]
        log_message "INFO" "Running simulation for testbench: $specific_tb"
    }
    
    # Set simulation properties
    set_property simulator_language "Mixed" [current_project]
    set_property target_simulator "XSim" [current_project]
    set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
    
    # Enable VCD dump
    set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
    set_property -name {xsim.simulate.wdb_filename} -value "$waveform_dir/${specific_tb}.wdb" -objects [get_filesets sim_1]
    
    # Create TCL hook for VCD generation
    set vcd_hook "$sim_dir/${specific_tb}_vcd_gen.tcl"
    set vcd_file "$waveform_dir/${specific_tb}.vcd"
    
    set fh [open $vcd_hook w]
    puts $fh "log_wave -recursive *"
    puts $fh "run 1000ns"
    puts $fh "close_sim"
    close $fh
    
    # Launch simulation
    if {$gui_mode} {
        log_message "INFO" "Launching simulation in GUI mode"
        launch_simulation -simset sim_1 -mode behavioral
    } else {
        log_message "INFO" "Launching simulation in batch mode"
        launch_simulation -simset sim_1 -mode behavioral -scripts_only
        
        # Update the simulation script to generate VCD file
        set xsim_script "$sim_dir/sim_1/behav/xsim/elaborate.sh"
        
        if {[file exists $xsim_script]} {
            # Run the simulation
            log_message "INFO" "Running simulation"
            set xsim_dir "$sim_dir/sim_1/behav/xsim"
            set sim_log "$log_dir/${specific_tb}.log"
            
            exec sh -c "cd $xsim_dir && ./elaborate.sh"
            exec sh -c "cd $xsim_dir && ./simulate.sh > $sim_log 2>&1"
            
            log_message "INFO" "Simulation completed"
            log_message "INFO" "Log available at: $sim_log"
            
            # Check if waveform file was generated
            if {[file exists "$waveform_dir/${specific_tb}.wdb"]} {
                log_message "INFO" "Waveform generated: ${specific_tb}.wdb"
            } else {
                log_message "WARNING" "No waveform file generated"
            }
        } else {
            log_message "ERROR" "Simulation scripts not generated properly"
            return 0
        }
    }
    
    # Generate report
    if {!$gui_mode} {
        set report_file "$report_dir/${specific_tb}_report.txt"
        set fh [open $report_file w]
        puts $fh "Simulation Report for $specific_tb"
        puts $fh "=============================="
        puts $fh "Date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
        puts $fh ""
        puts $fh "Simulation Duration: 1000ns"
        puts $fh "Waveform File: $waveform_dir/${specific_tb}.wdb"
        puts $fh "Log File: $log_dir/${specific_tb}.log"
        puts $fh ""
        puts $fh "To open the waveform, use: open_wave_database $waveform_dir/${specific_tb}.wdb"
        close $fh
        
        log_message "INFO" "Report generated: $report_file"
    }
    
    return 1
}

# Main procedure
proc main {} {
    global testbench verbose_mode
    
    if {$verbose_mode} {
        log_message "DEBUG" "Starting Vivado simulation script"
    }
    
    # Create project
    create_project_in_memory
    
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
    
    # Run simulation
    if {![run_simulation $testbench]} {
        log_message "ERROR" "Failed to run simulation"
        return 1
    }
    
    log_message "INFO" "Vivado simulation completed successfully"
    return 0
}

# Run the main procedure
if {[catch {main} result]} {
    log_message "ERROR" "Vivado simulation script failed: $result"
    exit 1
} else {
    exit $result
}