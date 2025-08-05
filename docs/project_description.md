# Project Description

## Overview

The JTAG/1500/1687 Network Design and Verification project involves the design, implementation, and verification of JTAG, IEEE 1500, and IEEE 1687 networks for digital logic, embedded memories, and PHY/IOs. The project aims to create a robust and flexible test infrastructure that facilitates efficient testing, debugging, and instrumentation of integrated circuits. The implementation follows relevant industry standards to ensure compatibility and reliability.

## Version 1.1.0 Features

Version 1.1.0 implements a complete test and debug infrastructure with:

- Full JTAG (IEEE 1149.1) implementation with robust state machine
- IEEE 1500 wrapper for core-level testing and integration
- IEEE 1687 network for embedded instrument access
- Comprehensive test benches for all components
- Cross-platform build system with support for both open-source tools and Vivado
- Improved verification infrastructure with coverage analysis

## Architecture

The project architecture consists of three main components that work together to provide a complete test infrastructure:

1. **JTAG Controller (IEEE 1149.1)**:
   - Implements the standard JTAG TAP controller state machine
   - Provides boundary scan capabilities
   - Serves as the primary interface for test access

2. **IEEE 1500 Wrapper**:
   - Implements a standardized wrapper around embedded cores
   - Provides Wrapper Instruction Register (WIR) and Wrapper Boundary Register (WBR)
   - Supports various test modes including EXTEST, INTEST, and BYPASS

3. **IEEE 1687 Network**:
   - Implements a reconfigurable scan network for instrument access
   - Features Segment Insertion Bits (SIBs) for flexible scan paths
   - Provides efficient access to embedded instruments

The top-level module integrates these components, allowing them to work together or independently based on the selected test mode.

## Objectives

- Create a complete, standards-compliant implementation of test and debug infrastructure
- Enable efficient testing of digital logic, embedded memories, and PHY/IOs
- Provide a flexible architecture that can be adapted to various design requirements
- Ensure robust verification through comprehensive test benches and coverage analysis
- Support cross-platform development and verification workflows
- Develop clear documentation for users and developers

## Technologies Used

- Verilog for RTL implementation
- SystemVerilog for test benches
- Boundary-Scan Description Language (BSDL) for boundary scan description
- IEEE 1500 Hardware Description Language (ICL) for wrapper description
- Procedural Description Language (PDL) for test procedures
- Open-source tools: Icarus Verilog, Yosys, Verilator
- Commercial tools: Vivado (optional)
- Bash scripting for automation
- Makefile for cross-platform builds

## Release History

- **Version 1.0.0**: Basic JTAG implementation with boundary scan and loopback
- **Version 1.1.0 (Current)**: Added IEEE 1500 and IEEE 1687 support, improved scripts and build system