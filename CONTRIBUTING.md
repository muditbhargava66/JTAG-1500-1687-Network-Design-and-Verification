# Contributing to JTAG/1500/1687 Network Project

Thank you for your interest in contributing to the JTAG/1500/1687 Network project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)
- [Documentation](#documentation)
- [Issue Reporting](#issue-reporting)
- [Feature Requests](#feature-requests)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. Be considerate, respectful, and collaborative.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/JTAG-1500-1687-Network-Design-and-Verification.git
   cd JTAG-1500-1687-Network-Design-and-Verification
   ```
3. **Set up the project**:
   ```bash
   ./setup_project.sh
   ```
4. **Create a branch** for your work:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

1. **Check existing issues** before starting work
2. **Create an issue** if none exists for your planned changes
3. **Work on your feature or bug fix** in your branch
4. **Run tests** to ensure your changes don't break existing functionality
5. **Update documentation** to reflect your changes
6. **Submit a pull request** when your changes are ready

## Coding Standards

### Verilog/SystemVerilog Standards

- Use 2-space indentation
- Use lowercase for wire/reg declarations, uppercase for parameters and macros
- Include module description in comments at the top of each file
- Document inputs/outputs with inline comments
- Add `timescale 1ns/1ps` at the top of each file
- Use descriptive signal and module names
- Align port declarations for readability

### File Naming Conventions

- **RTL Files**: Use `module_name.v` format (e.g., `jtag_controller.v`)
- **Testbench Files**: Use `tb_module_name.{sv|v}` format (e.g., `tb_jtag_controller.sv`)
- **Module Names**: Must match filename (module `jtag_controller` in `jtag_controller.v`)
- **Extensions**: Use `.sv` for SystemVerilog features, `.v` for basic Verilog

Example:
```verilog
`timescale 1ns / 1ps

/**
 * Module Name: example_module
 * Description: This module demonstrates coding standards
 */
module example_module (
    input  wire        clk,      // System clock
    input  wire        reset_n,  // Active-low reset
    input  wire [7:0]  data_in,  // Input data bus
    output reg  [7:0]  data_out  // Output data bus
);
    // Module implementation
    ...
endmodule
```

### Shell Script Standards

- Include a shebang line (`#!/bin/bash`)
- Add a brief description as a comment at the top
- Use descriptive function and variable names
- Include error checking for critical operations
- Add comments for complex logic
- Make scripts executable (`chmod +x scriptname.sh`)

### Tcl Script Standards

- Start with a descriptive comment block
- Use meaningful procedure and variable names
- Add comments for complex logic
- Use proper error handling with catch blocks
- Format code for readability

## Commit Guidelines

- Use clear, descriptive commit messages
- Start with a short summary line (50 chars max)
- Add a blank line followed by a detailed description if needed
- Reference issue numbers when applicable
- Use present tense ("Add feature" not "Added feature")

Example:
```
Fix JTAG state machine reset logic

- Fix synchronization in reset path
- Add external reset support
- Update state transition conditions
- Add assertions to verify reset behavior

Fixes #42
```

## Pull Request Process

1. **Update the README.md** if needed with details of your changes
2. **Ensure all tests pass**
3. **Update documentation** to reflect your changes
4. **Add yourself** to the Contributors list if you're not already there
5. **Submit the pull request** with a clear description of the changes
6. **Address review feedback** if requested by maintainers

## Testing Requirements

All new code must include appropriate tests:

1. **Unit Tests** for individual modules
2. **Integration Tests** when modifying how modules interact
3. **Coverage Analysis** to ensure adequate test coverage

Before submitting a pull request:
```bash
# Run all tests and check coverage
make all

# Alternatively, run specific tests for your changes
make sim_YOUR_MODULE
make syn_YOUR_MODULE
make cov_YOUR_MODULE
```

Aim for at least 90% code coverage for new features.

## Documentation

Documentation is crucial for this project:

1. **Code Documentation**:
   - Add comments to explain complex logic
   - Document module interfaces completely
   - Include timing diagrams for protocols when relevant

2. **User Documentation**:
   - Update relevant documentation in the `docs/` directory
   - Add usage examples for new features
   - Include waveform examples for new modules

## Issue Reporting

When reporting issues, please include:

1. **Description** of the issue
2. **Steps to reproduce** the issue
3. **Expected behavior**
4. **Actual behavior**
5. **Environment details**:
   - Operating system
   - Tool versions (Icarus Verilog, Yosys, Verilator, Vivado, etc.)
   - Any relevant configuration information

## Feature Requests

For feature requests, please:

1. **Check the roadmap** in FUTURE.md to see if it's already planned
2. **Create an issue** with the label "feature request"
3. **Describe the feature** and why it would be valuable
4. **Provide examples** of use cases if possible
5. **Indicate if you're willing to implement** the feature yourself

## Licensing

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

Thank you for contributing to the JTAG/1500/1687 Network project!