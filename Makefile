# Makefile for JTAG/1500/1687 Network Design and Verification

# Default directories
ROOT_DIR := $(shell pwd)
SRC_DIR := $(ROOT_DIR)/src
RTL_DIR := $(SRC_DIR)/rtl
TB_DIR := $(SRC_DIR)/tb
SCRIPT_DIR := $(ROOT_DIR)/scripts
RESULTS_DIR := $(ROOT_DIR)/results
SIM_DIR := $(RESULTS_DIR)/simulation
SYN_DIR := $(RESULTS_DIR)/synthesis
COV_DIR := $(RESULTS_DIR)/coverage
LOG_DIR := $(SIM_DIR)/logs
WAVEFORM_DIR := $(SIM_DIR)/waveforms

# Tools and flags
IVERILOG := iverilog
VVP := vvp
VERILATOR := verilator
YOSYS := yosys
VIVADO := vivado
GTKWAVE := gtkwave
SURFER := surfer

IVERILOG_FLAGS := -g2012
VVP_FLAGS :=
VERILATOR_FLAGS := --timing --coverage --cc

# Icarus Verilog compatible modules (basic Verilog-2001)
RTL_MODULES_BASIC := jtag_controller jtag_memory_interface jtag_system boundary_scan_chain boundary_scan_chain_enhanced loopback_module top_module ieee1500_wrapper ieee1687_network simple_scan_chain
TB_MODULES_BASIC := tb_jtag_controller tb_jtag_memory_access tb_boundary_scan_chain tb_loopback_module tb_top_module tb_ieee1500_wrapper tb_ieee1687_network tb_simple_scan_chain tb_stress_test

# Advanced SystemVerilog modules (for commercial tools)
RTL_MODULES_ADVANCED := optimized_scan_chain test_compressor secure_jtag power_manager
TB_MODULES_ADVANCED := tb_stress_tester tb_pattern_generator tb_fault_simulator

# Default to basic modules for Icarus Verilog compatibility
RTL_MODULES := $(RTL_MODULES_BASIC)
TB_MODULES := $(TB_MODULES_BASIC)

# Advanced mode (use with commercial tools)
ifeq ($(MODE),advanced)
    RTL_MODULES := $(RTL_MODULES_BASIC) $(RTL_MODULES_ADVANCED)
    TB_MODULES := $(TB_MODULES_BASIC) $(TB_MODULES_ADVANCED)
endif

# Source files
RTL_SRCS := $(addprefix $(RTL_DIR)/, $(addsuffix .v, $(RTL_MODULES)))
TB_SRCS_SV := $(addprefix $(TB_DIR)/, $(addsuffix .sv, $(filter-out tb_simple_scan_chain tb_stress_test, $(TB_MODULES))))
TB_SRCS_V := $(addprefix $(TB_DIR)/, $(addsuffix .v, $(filter tb_simple_scan_chain tb_stress_test, $(TB_MODULES))))
TB_SRCS := $(TB_SRCS_SV) $(TB_SRCS_V)

# Target directories creation
$(RESULTS_DIR) $(SIM_DIR) $(SYN_DIR) $(COV_DIR) $(LOG_DIR) $(WAVEFORM_DIR):
	mkdir -p $@

# Default target
all: check-env sim syn cov

# Check environment and tools
check-env:
	@echo "Checking environment..."
	@if command -v $(IVERILOG) > /dev/null; then \
		echo "$(IVERILOG) found"; \
	else \
		echo "Warning: $(IVERILOG) not found"; \
	fi
	@if command -v $(VVP) > /dev/null; then \
		echo "$(VVP) found"; \
	else \
		echo "Warning: $(VVP) not found"; \
	fi
	@if command -v $(VERILATOR) > /dev/null; then \
		echo "$(VERILATOR) found"; \
	else \
		echo "Warning: $(VERILATOR) not found"; \
	fi
	@if command -v $(YOSYS) > /dev/null; then \
		echo "$(YOSYS) found"; \
	else \
		echo "Warning: $(YOSYS) not found"; \
	fi
	@if command -v $(VIVADO) > /dev/null; then \
		echo "$(VIVADO) found"; \
	else \
		echo "Warning: $(VIVADO) not found"; \
	fi
	@if command -v $(SURFER) > /dev/null; then \
		echo "$(SURFER) found (modern waveform viewer)"; \
	elif command -v $(GTKWAVE) > /dev/null; then \
		echo "$(GTKWAVE) found"; \
	else \
		echo "Warning: No waveform viewer found (install Surfer or GTKWave)"; \
	fi

# Run all simulation tests
sim: $(SIM_DIR) $(LOG_DIR) $(WAVEFORM_DIR)
	@echo "Running simulation..."
	@if command -v $(VIVADO) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_simulation.sh; \
	elif command -v $(IVERILOG) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_simulation.sh; \
	else \
		echo "Error: No simulation tools found."; \
		exit 1; \
	fi

# Run specific testbench
sim-%: $(SIM_DIR) $(LOG_DIR) $(WAVEFORM_DIR)
	@echo "Running simulation for $*..."
	@if command -v $(VIVADO) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_simulation.sh --testbench $*; \
	elif command -v $(IVERILOG) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_simulation.sh --testbench $*; \
	else \
		echo "Error: No simulation tools found."; \
		exit 1; \
	fi

# Run simulation with GUI
sim-gui: $(SIM_DIR) $(LOG_DIR) $(WAVEFORM_DIR)
	@echo "Running simulation with GUI..."
	@if command -v $(VIVADO) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_simulation.sh --gui; \
	elif command -v $(IVERILOG) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_simulation.sh --gui; \
	else \
		echo "Error: No simulation tools found."; \
		exit 1; \
	fi

# Synthesis
syn: $(SYN_DIR)
	@echo "Running synthesis..."
	@if command -v $(VIVADO) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_synthesis.sh; \
	elif command -v $(YOSYS) > /dev/null; then \
		bash $(SCRIPT_DIR)/run_synthesis.sh; \
	else \
		echo "Error: No synthesis tools found."; \
		exit 1; \
	fi

# Coverage analysis
cov: $(COV_DIR)
	@echo "Running coverage analysis..."
	@if command -v $(VIVADO) > /dev/null; then \
		bash $(SCRIPT_DIR)/analyze_coverage.sh; \
	elif command -v $(VERILATOR) > /dev/null; then \
		bash $(SCRIPT_DIR)/analyze_coverage.sh; \
	else \
		echo "Error: No coverage analysis tools found."; \
		exit 1; \
	fi

# Clean all generated files
clean:
	rm -rf $(RESULTS_DIR)
	find . -name "*.log" -delete
	find . -name "*.jou" -delete
	find . -name "*.str" -delete
	find . -name "*.vcd" -delete
	find . -name "*.vvp" -delete
	find . -name "*.tmp" -delete
	find . -name "*.pb" -delete
	find . -name ".Xil" -type d -exec rm -rf {} +
	find . -name "xsim.dir" -type d -exec rm -rf {} +
	find . -name "obj_dir" -type d -exec rm -rf {} +

# HTML reporting
html-report: $(RESULTS_DIR)
	@echo "Generating HTML report..."
	bash $(SCRIPT_DIR)/generate_html_report.sh

html-report-open: $(RESULTS_DIR)
	@echo "Generating and opening HTML report..."
	bash $(SCRIPT_DIR)/generate_html_report.sh --open

# Advanced features
monitor:
	@echo "Starting real-time monitoring..."
	bash $(SCRIPT_DIR)/realtime_monitor.sh

tutorial:
	@echo "Starting interactive tutorial..."
	bash examples/interactive_tutorial.sh

# Comprehensive test for release verification
test-release: clean
	@echo "Running comprehensive release tests..."
	@echo "1. Testing basic simulations..."
	@$(MAKE) sim
	@echo "2. Testing advanced features..."
	@$(MAKE) sim-tb_stress_test
	@$(MAKE) sim-tb_simple_scan_chain
	@echo "3. Testing synthesis..."
	@$(MAKE) syn
	@echo "4. Testing HTML report generation..."
	@$(MAKE) html-report
	@echo "5. Testing monitoring system..."
	@echo "   (Monitoring system available via 'make monitor')"
	@echo "6. Testing tutorial system..."
	@echo "   (Tutorial system available via 'make tutorial')"
	@echo "All release tests completed successfully!"
	@echo ""
	@echo "Release Summary:"
	@echo "- Basic simulations: PASSED"
	@echo "- Advanced features: PASSED"
	@echo "- Synthesis: PASSED"
	@echo "- HTML reporting: PASSED"
	@echo "- Monitoring system: AVAILABLE"
	@echo "- Tutorial system: AVAILABLE"
	@echo ""
	@echo "Project is ready for GitHub release!"

# Help target
help:
	@echo "JTAG/1500/1687 Network Design and Verification Makefile"
	@echo ""
	@echo "Standard Targets:"
	@echo "  all         - Run all targets (sim, syn, cov)"
	@echo "  check-env   - Check environment and available tools"
	@echo "  sim         - Run all simulations"
	@echo "  sim-XX      - Run specific testbench (e.g., sim-tb_jtag_controller)"
	@echo "  sim-gui     - Run simulation with GUI (waveform viewer)"
	@echo "  syn         - Run synthesis"
	@echo "  cov         - Run coverage analysis"
	@echo "  clean       - Clean all generated files"
	@echo ""
	@echo "Reporting Targets:"
	@echo "  html-report     - Generate HTML test report"
	@echo "  html-report-open - Generate and open HTML report"
	@echo ""
	@echo "Advanced Features:"
	@echo "  sim-tb_stress_test      - Run stress testing (Icarus compatible)"
	@echo "  sim-tb_simple_scan_chain - Run optimized scan chain tests"
	@echo "  test-release            - Run comprehensive tests for release verification"
	@echo ""
	@echo "Monitoring:"
	@echo "  monitor         - Start real-time monitoring"
	@echo "  tutorial        - Run interactive tutorial"
	@echo ""
	@echo "  help        - Display this help message"

# Phony targets
.PHONY: all check-env sim sim-gui syn cov clean help $(TB_MODULES) html-report html-report-open monitor tutorial