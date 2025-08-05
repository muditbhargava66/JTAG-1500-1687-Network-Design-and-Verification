# Examples Makefile for JTAG/1500/1687 Network Project

# Get the root directory (parent of examples)
ROOT_DIR := $(shell cd .. && pwd)
EXAMPLES_DIR := $(shell pwd)

# Example-specific targets
.PHONY: all examples basic_jtag_scan ieee1500_core_test ieee1687_instrument_access integration_demo

# Run all examples
all: examples

examples: basic_jtag_scan ieee1500_core_test ieee1687_instrument_access integration_demo
	@echo "All examples completed successfully!"

# Individual example targets
basic_jtag_scan:
	@echo "Running Basic JTAG Scan Example..."
	@echo "=================================="
	@cd $(ROOT_DIR) && $(MAKE) sim-tb_jtag_controller
	@echo ""
	@echo "✅ Basic JTAG scan example completed"
	@echo "📊 View waveforms: gtkwave $(ROOT_DIR)/results/simulation/waveforms/tb_jtag_controller.vcd"
	@echo "📋 See example guide: $(EXAMPLES_DIR)/basic_jtag_scan/README.md"
	@echo ""

ieee1500_core_test:
	@echo "Running IEEE 1500 Core Test Example..."
	@echo "======================================"
	@cd $(ROOT_DIR) && $(MAKE) sim-tb_ieee1500_wrapper
	@echo ""
	@echo "✅ IEEE 1500 core test example completed"
	@echo "📊 View waveforms: gtkwave $(ROOT_DIR)/results/simulation/waveforms/tb_ieee1500_wrapper.vcd"
	@echo "📋 See example guide: $(EXAMPLES_DIR)/ieee1500_core_test/README.md"
	@echo ""

ieee1687_instrument_access:
	@echo "Running IEEE 1687 Instrument Access Example..."
	@echo "=============================================="
	@cd $(ROOT_DIR) && $(MAKE) sim-tb_ieee1687_network
	@echo ""
	@echo "✅ IEEE 1687 instrument access example completed"
	@echo "📊 View waveforms: gtkwave $(ROOT_DIR)/results/simulation/waveforms/tb_ieee1687_network.vcd"
	@echo "📋 See example guide: $(EXAMPLES_DIR)/ieee1687_instrument_access/README.md"
	@echo ""

integration_demo:
	@echo "Running Integration Demo..."
	@echo "=========================="
	@cd $(ROOT_DIR) && $(MAKE) sim-tb_top_module
	@cd $(ROOT_DIR) && $(MAKE) syn
	@echo ""
	@echo "✅ Integration demo completed"
	@echo "📊 View waveforms: gtkwave $(ROOT_DIR)/results/simulation/waveforms/tb_top_module.vcd"
	@echo "📋 Synthesis report: $(ROOT_DIR)/results/synthesis/reports/top_module_stats.rpt"
	@echo "📋 See example guide: $(EXAMPLES_DIR)/integration_demo/README.md"
	@echo ""

# Generate example documentation
docs:
	@echo "Generating example documentation..."
	@echo "Available examples:"
	@echo "  1. basic_jtag_scan - Basic JTAG boundary scan operations"
	@echo "  2. ieee1500_core_test - IEEE 1500 wrapper testing"
	@echo "  3. ieee1687_instrument_access - IEEE 1687 network configuration"
	@echo "  4. integration_demo - Complete system integration"
	@echo ""
	@echo "Run 'make <example_name>' to execute individual examples"
	@echo "Run 'make all' to execute all examples"

# Clean example results
clean:
	@cd $(ROOT_DIR) && $(MAKE) clean
	@echo "Example results cleaned"

# Help target
help:
	@echo "JTAG/1500/1687 Network Examples"
	@echo "==============================="
	@echo ""
	@echo "Available targets:"
	@echo "  all                      - Run all examples"
	@echo "  basic_jtag_scan         - Basic JTAG operations demo"
	@echo "  ieee1500_core_test      - IEEE 1500 wrapper demo"
	@echo "  ieee1687_instrument_access - IEEE 1687 network demo"
	@echo "  integration_demo        - Complete system demo"
	@echo "  docs                    - Show example documentation"
	@echo "  clean                   - Clean all results"
	@echo "  help                    - Show this help"
	@echo ""
	@echo "Example usage:"
	@echo "  make basic_jtag_scan    # Run basic JTAG example"
	@echo "  make all                # Run all examples"