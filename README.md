# JTAG/1500/1687 Network Design and Verification

## Overview

This project involves the design, implementation, and verification of JTAG, IEEE 1500, and IEEE 1687 networks for digital logic, embedded memories, and PHY/IOs. The objective is to create a robust system that facilitates efficient testing and debugging of integrated circuits.

## Directory Structure

```
.
├── docs/
│   ├── project_description.md
│   ├── requirements.md
│   ├── design_specifications.md
│   ├── verification_plan.md
│   └── test_strategy.md
├── scripts/
│   ├── run_simulation.sh
│   ├── run_synthesis.sh
│   └── analyze_coverage.sh
├── src/
│   ├── rtl/
│   │   ├── jtag_controller.v
│   │   ├── boundary_scan_chain.v
│   │   ├── loopback_module.v
│   │   └── top_module.v
│   ├── bsdl/
│   │   └── jtag_controller.bsdl
│   ├── icl/
│   │   └── jtag_network.icl
│   ├── pdl/
│   │   └── jtag_procedures.pdl
│   └── tb/
│       ├── tb_jtag_controller.sv
│       ├── tb_boundary_scan_chain.sv
│       ├── tb_loopback_module.sv
│       └── tb_top_module.sv
└── README.md
```

## Project Description

Detailed project description can be found in `docs/project_description.md`.

## Requirements

Requirements for the project are documented in `docs/requirements.md`.

## Design Specifications

Detailed design specifications are provided in `docs/design_specifications.md`.

## Verification Plan

Verification plan is outlined in `docs/verification_plan.md`.

## Test Strategy

Test strategy is described in `docs/test_strategy.md`.

## Setup Instructions

### Prerequisites

- Icarus Verilog
- Yosys
- Verilator
- Vivado
- GTKWave
- Bash

### Installation

1. **Clone the repository:**
    ```bash
    git clone https://github.com/muditbhargava66/JTAG-1500-1687-Network-Design-and-Verification.git
    cd JTAG_1500_1687_Network_Design_and_Verification
    ```

2. **Install necessary tools:**
    - For Ubuntu/Debian:
      ```bash
      sudo apt-get update
      sudo apt-get install -y iverilog yosys verilator gtkwave
      ```
    - For Vivado, follow the official [installation guide](https://www.xilinx.com/support/download.html).

## Running Simulations

To run simulations, execute the following command:
```bash
./scripts/run_simulation.sh
```
Simulation results, including waveforms and logs, will be saved in the `results/simulation` directory.

## Running Synthesis

To run synthesis, execute the following command:
```bash
./scripts/run_synthesis.sh
```
Synthesis results, including reports, will be saved in the `results/synthesis` directory.

## Analyzing Coverage

To analyze coverage, execute the following command:
```bash
./scripts/analyze_coverage.sh
```
Coverage analysis results will be saved in the `results/coverage` directory.

## Contributing

Contributions are welcome! Please read the [contribution guidelines](CONTRIBUTING.md) first.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

Special thanks to the open-source community for providing the tools and resources necessary for this project.

---