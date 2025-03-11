# Changelog

## Version 1.0.0 (2025-03-11)

### Fixed Issues
- **Multiple Driver Error**: Fixed conflict in top_module.v where bsc_tdo signal had multiple drivers
- **Verilator Integration**: Successfully integrated Verilator for coverage analysis
  - Added working coverage analysis script that properly handles timing constructs
  - Implemented simplified C++ driver approach for Verilator simulations
  - Suppressed non-critical warnings (WIDTHEXPAND, WIDTHTRUNC, MULTIDRIVEN)
- **Cross-Platform Support**: 
  - Improved script compatibility with macOS (tested on Apple Silicon)
  - Added automatic detection of Verilator include paths

### Added Features
- **Coverage Analysis**: 
  - Added coverage collection and reporting capabilities
  - Generated annotated coverage reports for all testbenches
- **Build System**: 
  - Implemented streamlined build process for all testbenches
  - Added automatic compilation and execution of tests

### Known Limitations
- Limited test coverage for comprehensive verification
- JTAG state machine transitions need more thorough testing
- IEEE 1500 and 1687 standards not yet fully implemented

### Future Plans
- Implement IEEE 1500 wrapper module
- Implement IEEE 1687 network module
- Add cross-platform Makefile
- Enhance test scenarios for better coverage