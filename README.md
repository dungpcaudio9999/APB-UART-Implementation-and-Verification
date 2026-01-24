# APB UART Verification Environment

This repository contains the SystemVerilog verification environment for an APB-based UART core.

## 1. Prerequisites
- **QuestaSim** (Verified on version 10.7c)
- A working shell/terminal (cmd/powershell on Windows)

## 2. Directory Structure
```
.
├── docs/       # Specifications and test plans
├── rtl/        # UART RTL source code
├── sim/        # Simulation scripts and work library
└── tb/         # Testbench source files
    ├── apb_agent/   # APB UVC (Driver, Monitor, Gen)
    ├── uart_agent/  # UART UVC (Driver, Monitor)
    ├── env/         # Environment, Scoreboard, Coverage
    ├── test/        # Test scenarios (.sv files)
    ├── include/     # Defines, interfaces, transactions
    └── tb_top.sv    # Top-level testbench module
```

## 3. How to Run Simulation

### Method 1: GUI Mode (Recommended for Debugging)
1. Open **QuestaSim**.
2. Change directory to the `sim` folder:
   ```tcl
   cd sim
   ```
3. Run the automation script `run.do`:
   ```tcl
   do run.do
   ```
   *By default, this runs the `test_sanity` testcase.*

### Method 2: Command Line (Batch Mode)
From your terminal:
```bash
cd sim
vsim -c -do "do run.do"
```

## 4. Running Different Test Cases

To run a specific test case, you can pass the `TESTNAME` argument when launching `vsim`.
However, because `run.do` handles the compilation and loading steps, you can modify `run.do` OR specify the argument if you are running manually.

**Using the `run.do` script (Easiest):**
Open `sim/run.do` and modify the argument passed to the script, or pass it directly if calling the script function (if wrapper exists).
Currently, the script reads the first argument `$1`.

Example inside QuestaSim console:
```tcl
# Run default (test_sanity)
do run.do

# Run TX Test
do run.do test_tx

# Run RX Test
do run.do test_rx
```

**Available Test Cases:**
*   `test_sanity` (Default): Sends random transactions to verify connectivity.
*   `test_tx`: Verifies UART Transmission logic (APB Write -> Serial TX).
*   `test_rx`: Verifies UART Reception logic (Serial RX -> APB Read).
*   `test_fifo`: Tests behavior when FIFO fills up (Overrun).
*   `test_flow_control`: Verifies CTS/RTS handshaking.
*   `test_error_injection`: Injects Parity errors to verify detection.

## 5. Common Issues

*   **Compilation Error**: Ensure you run `do run.do` from within the `sim` directory so relative paths (`../tb`, `../rtl`) resolve correctly.
*   **Permissions**: Ensure you have write permissions in the `sim` folder to create the `work` library.
