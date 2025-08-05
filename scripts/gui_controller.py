#!/usr/bin/env python3
"""
JTAG/1500/1687 Network GUI Test Controller

A simple GUI application for controlling and monitoring the test infrastructure.
Provides an intuitive interface for running tests, viewing results, and managing
the test environment.
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog, scrolledtext
import subprocess
import threading
import os
import sys
import json
import time
from pathlib import Path

class JTAGTestController:
    def __init__(self, root):
        self.root = root
        self.root.title("JTAG/1500/1687 Network Test Controller v2.0.0")
        self.root.geometry("1000x700")
        
        # Get project root directory
        self.project_root = Path(__file__).parent.parent
        self.results_dir = self.project_root / "results"
        
        # Test status tracking
        self.test_running = False
        self.current_process = None
        
        # Create GUI elements
        self.create_widgets()
        self.update_status()
        
    def create_widgets(self):
        # Create main notebook for tabs
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Test Control Tab
        self.create_test_control_tab()
        
        # Results Tab
        self.create_results_tab()
        
        # Configuration Tab
        self.create_config_tab()
        
        # Status Tab
        self.create_status_tab()
        
        # Status bar
        self.status_bar = ttk.Label(self.root, text="Ready", relief=tk.SUNKEN)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)
        
    def create_test_control_tab(self):
        # Test Control Frame
        test_frame = ttk.Frame(self.notebook)
        self.notebook.add(test_frame, text="Test Control")
        
        # Test selection
        selection_frame = ttk.LabelFrame(test_frame, text="Test Selection")
        selection_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Test type selection
        ttk.Label(selection_frame, text="Test Type:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=5)
        self.test_type = ttk.Combobox(selection_frame, values=[
            "All Tests", "Simulation Only", "Synthesis Only", "Coverage Only",
            "Parallel Build", "Fast Build", "Individual Testbench"
        ])
        self.test_type.set("All Tests")
        self.test_type.grid(row=0, column=1, sticky=tk.W+tk.E, padx=5, pady=5)
        
        # Individual testbench selection
        ttk.Label(selection_frame, text="Testbench:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=5)
        self.testbench = ttk.Combobox(selection_frame, values=[
            "tb_jtag_controller", "tb_ieee1500_wrapper", "tb_ieee1687_network",
            "tb_boundary_scan_chain", "tb_loopback_module", "tb_top_module"
        ])
        self.testbench.set("tb_jtag_controller")
        self.testbench.grid(row=1, column=1, sticky=tk.W+tk.E, padx=5, pady=5)
        
        selection_frame.columnconfigure(1, weight=1)
        
        # Control buttons
        control_frame = ttk.LabelFrame(test_frame, text="Test Control")
        control_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.run_button = ttk.Button(control_frame, text="Run Tests", command=self.run_tests)
        self.run_button.pack(side=tk.LEFT, padx=5, pady=5)
        
        self.stop_button = ttk.Button(control_frame, text="Stop Tests", command=self.stop_tests, state=tk.DISABLED)
        self.stop_button.pack(side=tk.LEFT, padx=5, pady=5)
        
        self.clear_button = ttk.Button(control_frame, text="Clear Results", command=self.clear_results)
        self.clear_button.pack(side=tk.LEFT, padx=5, pady=5)
        
        self.report_button = ttk.Button(control_frame, text="Generate Report", command=self.generate_report)
        self.report_button.pack(side=tk.LEFT, padx=5, pady=5)
        
        # Progress bar
        progress_frame = ttk.LabelFrame(test_frame, text="Progress")
        progress_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.progress = ttk.Progressbar(progress_frame, mode='indeterminate')
        self.progress.pack(fill=tk.X, padx=5, pady=5)
        
        # Output console
        console_frame = ttk.LabelFrame(test_frame, text="Console Output")
        console_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        self.console = scrolledtext.ScrolledText(console_frame, height=15, state=tk.DISABLED)
        self.console.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
    def create_results_tab(self):
        # Results Frame
        results_frame = ttk.Frame(self.notebook)
        self.notebook.add(results_frame, text="Results")
        
        # Results summary
        summary_frame = ttk.LabelFrame(results_frame, text="Test Summary")
        summary_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Create summary labels
        self.sim_status = ttk.Label(summary_frame, text="Simulations: Not Run")
        self.sim_status.grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        
        self.syn_status = ttk.Label(summary_frame, text="Synthesis: Not Run")
        self.syn_status.grid(row=0, column=1, sticky=tk.W, padx=5, pady=2)
        
        self.cov_status = ttk.Label(summary_frame, text="Coverage: Not Run")
        self.cov_status.grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        
        self.overall_status = ttk.Label(summary_frame, text="Overall: Ready")
        self.overall_status.grid(row=1, column=1, sticky=tk.W, padx=5, pady=2)
        
        # Results tree
        tree_frame = ttk.LabelFrame(results_frame, text="Detailed Results")
        tree_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        self.results_tree = ttk.Treeview(tree_frame, columns=('Status', 'Time', 'Details'), show='tree headings')
        self.results_tree.heading('#0', text='Test')
        self.results_tree.heading('Status', text='Status')
        self.results_tree.heading('Time', text='Duration')
        self.results_tree.heading('Details', text='Details')
        
        scrollbar = ttk.Scrollbar(tree_frame, orient=tk.VERTICAL, command=self.results_tree.yview)
        self.results_tree.configure(yscrollcommand=scrollbar.set)
        
        self.results_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Results buttons
        results_buttons_frame = ttk.Frame(results_frame)
        results_buttons_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Button(results_buttons_frame, text="View Waveforms", command=self.view_waveforms).pack(side=tk.LEFT, padx=5)
        ttk.Button(results_buttons_frame, text="Open Results Folder", command=self.open_results_folder).pack(side=tk.LEFT, padx=5)
        ttk.Button(results_buttons_frame, text="Export Results", command=self.export_results).pack(side=tk.LEFT, padx=5)
        
    def create_config_tab(self):
        # Configuration Frame
        config_frame = ttk.Frame(self.notebook)
        self.notebook.add(config_frame, text="Configuration")
        
        # Tool configuration
        tools_frame = ttk.LabelFrame(config_frame, text="Tool Configuration")
        tools_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Parallel jobs
        ttk.Label(tools_frame, text="Parallel Jobs:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=5)
        self.parallel_jobs = tk.StringVar(value="4")
        ttk.Entry(tools_frame, textvariable=self.parallel_jobs, width=10).grid(row=0, column=1, sticky=tk.W, padx=5, pady=5)
        
        # Tool paths
        ttk.Label(tools_frame, text="Project Root:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=5)
        self.project_path = tk.StringVar(value=str(self.project_root))
        ttk.Entry(tools_frame, textvariable=self.project_path, width=50).grid(row=1, column=1, sticky=tk.W+tk.E, padx=5, pady=5)
        ttk.Button(tools_frame, text="Browse", command=self.browse_project_path).grid(row=1, column=2, padx=5, pady=5)
        
        tools_frame.columnconfigure(1, weight=1)
        
        # Test options
        options_frame = ttk.LabelFrame(config_frame, text="Test Options")
        options_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.gui_mode = tk.BooleanVar(value=False)
        ttk.Checkbutton(options_frame, text="Open waveform viewer after simulation", variable=self.gui_mode).pack(anchor=tk.W, padx=5, pady=2)
        
        self.verbose_mode = tk.BooleanVar(value=False)
        ttk.Checkbutton(options_frame, text="Verbose output", variable=self.verbose_mode).pack(anchor=tk.W, padx=5, pady=2)
        
        self.auto_report = tk.BooleanVar(value=True)
        ttk.Checkbutton(options_frame, text="Generate HTML report automatically", variable=self.auto_report).pack(anchor=tk.W, padx=5, pady=2)
        
        # Environment check
        env_frame = ttk.LabelFrame(config_frame, text="Environment")
        env_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        ttk.Button(env_frame, text="Check Environment", command=self.check_environment).pack(padx=5, pady=5)
        ttk.Button(env_frame, text="Install Tools", command=self.install_tools).pack(padx=5, pady=5)
        
        self.env_status = scrolledtext.ScrolledText(env_frame, height=10, state=tk.DISABLED)
        self.env_status.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
    def create_status_tab(self):
        # Status Frame
        status_frame = ttk.Frame(self.notebook)
        self.notebook.add(status_frame, text="System Status")
        
        # System information
        sys_frame = ttk.LabelFrame(status_frame, text="System Information")
        sys_frame.pack(fill=tk.X, padx=10, pady=5)
        
        ttk.Label(sys_frame, text=f"Platform: {sys.platform}").pack(anchor=tk.W, padx=5, pady=2)
        ttk.Label(sys_frame, text=f"Python: {sys.version.split()[0]}").pack(anchor=tk.W, padx=5, pady=2)
        ttk.Label(sys_frame, text=f"Project Root: {self.project_root}").pack(anchor=tk.W, padx=5, pady=2)
        
        # Resource usage
        resource_frame = ttk.LabelFrame(status_frame, text="Resource Usage")
        resource_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.cpu_usage = ttk.Label(resource_frame, text="CPU Usage: N/A")
        self.cpu_usage.pack(anchor=tk.W, padx=5, pady=2)
        
        self.memory_usage = ttk.Label(resource_frame, text="Memory Usage: N/A")
        self.memory_usage.pack(anchor=tk.W, padx=5, pady=2)
        
        self.disk_usage = ttk.Label(resource_frame, text="Disk Usage: N/A")
        self.disk_usage.pack(anchor=tk.W, padx=5, pady=2)
        
        # Log viewer
        log_frame = ttk.LabelFrame(status_frame, text="System Log")
        log_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=5)
        
        self.system_log = scrolledtext.ScrolledText(log_frame, height=15, state=tk.DISABLED)
        self.system_log.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
    def log_message(self, message):
        """Add message to console and system log"""
        timestamp = time.strftime("%H:%M:%S")
        formatted_message = f"[{timestamp}] {message}\n"
        
        # Update console
        self.console.config(state=tk.NORMAL)
        self.console.insert(tk.END, formatted_message)
        self.console.see(tk.END)
        self.console.config(state=tk.DISABLED)
        
        # Update system log
        self.system_log.config(state=tk.NORMAL)
        self.system_log.insert(tk.END, formatted_message)
        self.system_log.see(tk.END)
        self.system_log.config(state=tk.DISABLED)
        
    def run_tests(self):
        """Run selected tests in a separate thread"""
        if self.test_running:
            messagebox.showwarning("Warning", "Tests are already running!")
            return
            
        self.test_running = True
        self.run_button.config(state=tk.DISABLED)
        self.stop_button.config(state=tk.NORMAL)
        self.progress.start()
        
        # Clear console
        self.console.config(state=tk.NORMAL)
        self.console.delete(1.0, tk.END)
        self.console.config(state=tk.DISABLED)
        
        # Start test thread
        test_thread = threading.Thread(target=self._run_tests_thread)
        test_thread.daemon = True
        test_thread.start()
        
    def _run_tests_thread(self):
        """Thread function for running tests"""
        try:
            test_type = self.test_type.get()
            
            # Change to project directory
            os.chdir(self.project_root)
            
            if test_type == "All Tests":
                self._run_command(["make", "all"])
            elif test_type == "Simulation Only":
                self._run_command(["make", "sim"])
            elif test_type == "Synthesis Only":
                self._run_command(["make", "syn"])
            elif test_type == "Coverage Only":
                self._run_command(["make", "cov"])
            elif test_type == "Parallel Build":
                self._run_command(["make", "parallel-all"])
            elif test_type == "Fast Build":
                self._run_command(["make", "fast-build"])
            elif test_type == "Individual Testbench":
                testbench = self.testbench.get()
                self._run_command(["make", f"sim-{testbench}"])
                
            # Generate report if enabled
            if self.auto_report.get():
                self.log_message("Generating HTML report...")
                self._run_command(["make", "html-report"])
                
            self.log_message("Tests completed successfully!")
            
        except Exception as e:
            self.log_message(f"Error running tests: {str(e)}")
        finally:
            # Update UI in main thread
            self.root.after(0, self._test_completed)
            
    def _run_command(self, command):
        """Run a command and capture output"""
        self.log_message(f"Running: {' '.join(command)}")
        
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
            bufsize=1
        )
        
        self.current_process = process
        
        # Read output line by line
        for line in process.stdout:
            if line.strip():
                self.root.after(0, lambda l=line.strip(): self.log_message(l))
                
        process.wait()
        self.current_process = None
        
        if process.returncode != 0:
            raise Exception(f"Command failed with return code {process.returncode}")
            
    def _test_completed(self):
        """Called when tests are completed"""
        self.test_running = False
        self.run_button.config(state=tk.NORMAL)
        self.stop_button.config(state=tk.DISABLED)
        self.progress.stop()
        self.update_results()
        
    def stop_tests(self):
        """Stop running tests"""
        if self.current_process:
            self.current_process.terminate()
            self.log_message("Tests stopped by user")
        self._test_completed()
        
    def clear_results(self):
        """Clear test results"""
        if messagebox.askyesno("Confirm", "Clear all test results?"):
            try:
                os.chdir(self.project_root)
                subprocess.run(["make", "clean"], check=True)
                self.log_message("Results cleared")
                self.update_results()
            except Exception as e:
                messagebox.showerror("Error", f"Failed to clear results: {str(e)}")
                
    def generate_report(self):
        """Generate HTML report"""
        try:
            os.chdir(self.project_root)
            subprocess.run(["make", "html-report-open"], check=True)
            self.log_message("HTML report generated and opened")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to generate report: {str(e)}")
            
    def check_environment(self):
        """Check tool environment"""
        try:
            os.chdir(self.project_root)
            result = subprocess.run(["make", "check-env"], capture_output=True, text=True)
            
            self.env_status.config(state=tk.NORMAL)
            self.env_status.delete(1.0, tk.END)
            self.env_status.insert(tk.END, result.stdout)
            if result.stderr:
                self.env_status.insert(tk.END, "\nErrors:\n" + result.stderr)
            self.env_status.config(state=tk.DISABLED)
            
        except Exception as e:
            messagebox.showerror("Error", f"Failed to check environment: {str(e)}")
            
    def install_tools(self):
        """Install required tools"""
        if messagebox.askyesno("Confirm", "Install required tools automatically?"):
            try:
                os.chdir(self.project_root)
                subprocess.run(["./scripts/install_tools.sh"], check=True)
                self.log_message("Tools installation completed")
                self.check_environment()
            except Exception as e:
                messagebox.showerror("Error", f"Failed to install tools: {str(e)}")
                
    def update_results(self):
        """Update results display"""
        # Clear existing results
        for item in self.results_tree.get_children():
            self.results_tree.delete(item)
            
        # Check for result files and update display
        if self.results_dir.exists():
            # Check simulation results
            sim_dir = self.results_dir / "simulation" / "logs"
            if sim_dir.exists():
                sim_count = len(list(sim_dir.glob("*.log")))
                self.sim_status.config(text=f"Simulations: {sim_count} completed")
                
                # Add simulation results to tree
                sim_node = self.results_tree.insert('', 'end', text='Simulations', values=('', '', ''))
                for log_file in sim_dir.glob("*.log"):
                    status = "PASS" if "successful" in log_file.read_text() else "FAIL"
                    self.results_tree.insert(sim_node, 'end', text=log_file.stem, values=(status, '', ''))
                    
            # Check synthesis results
            syn_dir = self.results_dir / "synthesis"
            if syn_dir.exists():
                syn_count = len(list(syn_dir.glob("*_synth.v")))
                self.syn_status.config(text=f"Synthesis: {syn_count} modules")
                
            # Check coverage results
            cov_dir = self.results_dir / "coverage"
            if cov_dir.exists():
                cov_count = len(list(cov_dir.glob("*.log")))
                self.cov_status.config(text=f"Coverage: {cov_count} analyzed")
                
    def update_status(self):
        """Update status bar and system information"""
        if self.test_running:
            self.status_bar.config(text="Running tests...")
        else:
            self.status_bar.config(text="Ready")
            
        # Schedule next update
        self.root.after(1000, self.update_status)
        
    def view_waveforms(self):
        """Open waveform viewer"""
        waveform_dir = self.results_dir / "simulation" / "waveforms"
        if waveform_dir.exists():
            vcd_files = list(waveform_dir.glob("*.vcd"))
            if vcd_files:
                # Try to open with gtkwave
                try:
                    subprocess.Popen(["gtkwave", str(vcd_files[0])])
                except FileNotFoundError:
                    messagebox.showinfo("Info", f"Please open {vcd_files[0]} with your waveform viewer")
            else:
                messagebox.showinfo("Info", "No waveform files found. Run simulations first.")
        else:
            messagebox.showinfo("Info", "No waveform directory found. Run simulations first.")
            
    def open_results_folder(self):
        """Open results folder in file manager"""
        if self.results_dir.exists():
            if sys.platform == "win32":
                os.startfile(self.results_dir)
            elif sys.platform == "darwin":
                subprocess.run(["open", str(self.results_dir)])
            else:
                subprocess.run(["xdg-open", str(self.results_dir)])
        else:
            messagebox.showinfo("Info", "Results directory not found. Run tests first.")
            
    def export_results(self):
        """Export results to file"""
        filename = filedialog.asksaveasfilename(
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        if filename:
            # Create results summary
            results = {
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                "project_root": str(self.project_root),
                "results": {}
            }
            
            # Add simulation results
            sim_dir = self.results_dir / "simulation" / "logs"
            if sim_dir.exists():
                results["results"]["simulation"] = []
                for log_file in sim_dir.glob("*.log"):
                    results["results"]["simulation"].append({
                        "name": log_file.stem,
                        "status": "PASS" if "successful" in log_file.read_text() else "FAIL"
                    })
                    
            # Save to file
            with open(filename, 'w') as f:
                json.dump(results, f, indent=2)
                
            messagebox.showinfo("Success", f"Results exported to {filename}")
            
    def browse_project_path(self):
        """Browse for project path"""
        path = filedialog.askdirectory(initialdir=self.project_root)
        if path:
            self.project_path.set(path)
            self.project_root = Path(path)

def main():
    """Main function"""
    root = tk.Tk()
    app = JTAGTestController(root)
    
    # Center window on screen
    root.update_idletasks()
    x = (root.winfo_screenwidth() // 2) - (root.winfo_width() // 2)
    y = (root.winfo_screenheight() // 2) - (root.winfo_height() // 2)
    root.geometry(f"+{x}+{y}")
    
    root.mainloop()

if __name__ == "__main__":
    main()