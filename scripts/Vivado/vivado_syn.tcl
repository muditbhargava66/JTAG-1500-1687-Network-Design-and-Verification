# JTAG/1500/1687 Network Project - Vivado Synthesis Script
# TCL script for Vivado synthesis

# Process command line arguments
set module ""
set verbose_mode 0
set clean_mode 0

# Parse command-line arguments
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    
    switch -glob -- $arg {
        "-module" {
            incr i
            set module [lindex $argv $i]
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
set results_dir [file join $root_dir "results"]
set syn_dir [file join $results_dir "synthesis"]
set report_dir [file join $syn_dir "reports"]
set vivado_dir [file join $syn_dir "vivado_project"]

# Create directories if they don't exist
file mkdir $syn_dir
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

# Clean synthesis results if requested
if {$clean_mode} {
    log_message "INFO" "Cleaning synthesis results"
    file delete -force [glob -nocomplain "$syn_dir/*"]
    file mkdir $report_dir
}

# Create a new project
proc create_project {} {
    global syn_dir vivado_dir verbose_mode
    
    log_message "INFO" "Creating Vivado project"
    
    # Create project
    create_project -force synthesis_project $vivado_dir -part xc7a100tcsg324-1
    
    # Set HDL language
    set_property target_language Verilog [current_project]
    
    if {$verbose_mode} {
        log_message "DEBUG" "Project created in: $vivado_dir"
    }
}

# Add design files to the project
proc add_design_files {{specific_module ""}} {
    global rtl_dir verbose_mode
    
    log_message "INFO" "Adding design files to project"
    
    if {$specific_module != ""} {
        set rtl_file "$rtl_dir/${specific_module}.v"
        
        if {![file exists $rtl_file]} {
            log_message "ERROR" "Module file not found: $rtl_file"
            return 0
        }
        
        add_files -norecurse $rtl_file
        set_property file_type "Verilog" [get_files $rtl_file]
        set_property top $specific_module [current_fileset]
        
        if {$verbose_mode} {
            log_message "DEBUG" "Added RTL file: $rtl_file"
            log_message "DEBUG" "Set top module to: $specific_module"
        }
    } else {
        # Add all RTL files
        set rtl_files [glob -nocomplain "$rtl_dir/*.v"]
        
        if {[llength $rtl_files] == 0} {
            log_message "ERROR" "No RTL files found in $rtl_dir"
            return 0
        }
        
        add_files -norecurse $rtl_files
        
        # Set file properties
        foreach file $rtl_files {
            set_property file_type "Verilog" [get_files $file]
            
            if {$verbose_mode} {
                log_message "DEBUG" "Added RTL file: $file"
            }
        }
        
        # Set top module (top_module if available, otherwise first one alphabetically)
        if {[file exists "$rtl_dir/top_module.v"]} {
            set_property top top_module [current_fileset]
            
            if {$verbose_mode} {
                log_message "DEBUG" "Set top module to: top_module"
            }
        } else {
            set top_module [file rootname [file tail [lindex [lsort $rtl_files] 0]]]
            set_property top $top_module [current_fileset]
            
            if {$verbose_mode} {
                log_message "DEBUG" "Set top module to: $top_module"
            }
        }
    }
    
    return 1
}

# Run synthesis
proc run_synthesis {} {
    global syn_dir report_dir verbose_mode
    
    set top_module [get_property top [current_fileset]]
    log_message "INFO" "Running synthesis for module: $top_module"
    
    # Set synthesis properties
    set_property -name {STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY} -value {rebuilt} -objects [get_runs synth_1]
    set_property -name {STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS} -value {1} -objects [get_runs synth_1]
    set_property -name {STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING} -value {on} -objects [get_runs synth_1]
    set_property -name {STEPS.SYNTH_DESIGN.ARGS.NO_LC} -value {1} -objects [get_runs synth_1]
    
    # Launch synthesis
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    
    # Check if synthesis succeeded
    if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
        log_message "ERROR" "Synthesis failed"
        return 0
    }
    
    # Open synthesis run
    open_run synth_1 -name synth_1
    
    # Generate reports
    report_timing_summary -file "$report_dir/${top_module}_timing.rpt" -warn_on_violation
    report_utilization -file "$report_dir/${top_module}_utilization.rpt"
    report_power -file "$report_dir/${top_module}_power.rpt"
    
    if {$verbose_mode} {
        log_message "DEBUG" "Generated timing report: $report_dir/${top_module}_timing.rpt"
        log_message "DEBUG" "Generated utilization report: $report_dir/${top_module}_utilization.rpt"
        log_message "DEBUG" "Generated power report: $report_dir/${top_module}_power.rpt"
    }
    
    # Write synthesized netlist
    write_verilog -force "$syn_dir/${top_module}_synth.v"
    log_message "INFO" "Wrote synthesized netlist to: $syn_dir/${top_module}_synth.v"
    
    # Generate summary report
    set report_file "$report_dir/${top_module}_synthesis_summary.txt"
    set fh [open $report_file w]
    puts $fh "Synthesis Report for $top_module"
    puts $fh "==============================="
    puts $fh "Date: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $fh ""
    puts $fh "Design Summary:"
    puts $fh "  Slice LUTs: [get_property SLICE_UTIL [get_run synth_1]]%"
    puts $fh "  Slice Registers: [get_property SLICE_REG_UTIL [get_run synth_1]]%"
    puts $fh ""
    puts $fh "Detailed reports:"
    puts $fh "  Timing report: $report_dir/${top_module}_timing.rpt"
    puts $fh "  Utilization report: $report_dir/${top_module}_utilization.rpt"
    puts $fh "  Power report: $report_dir/${top_module}_power.rpt"
    puts $fh ""
    puts $fh "Synthesized netlist: $syn_dir/${top_module}_synth.v"
    close $fh
    
    log_message "INFO" "Generated synthesis summary: $report_file"
    
    return 1
}

# Main procedure
proc main {} {
    global module verbose_mode
    
    if {$verbose_mode} {
        log_message "DEBUG" "Starting Vivado synthesis script"
    }
    
    # Create project
    create_project
    
    # Add design files
    if {![add_design_files $module]} {
        log_message "ERROR" "Failed to add design files"
        return 1
    }
    
    # Run synthesis
    if {![run_synthesis]} {
        log_message "ERROR" "Failed to run synthesis"
        return 1
    }
    
    log_message "INFO" "Vivado synthesis completed successfully"
    return 0
}

# Run the main procedure
if {[catch {main} result]} {
    log_message "ERROR" "Vivado synthesis script failed: $result"
    exit 1
} else {
    exit $result
}