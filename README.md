# vhdl-uart

A simple, synthesizable UART (Universal Asynchronous Receiver/Transmitter) implementation written in VHDL. This repository provides a lightweight UART core suitable for FPGA and ASIC projects, along with testbenches for simulation.

## Overview

This project implements a configurable UART transmitter and receiver in VHDL with a focus on clarity and portability. The core is written to be synthesizable with common FPGA toolchains and easy to simulate with GHDL/ModelSim/Questa.

Key goals:
- Small, readable VHDL source
- Configurable baud rate and character format
- Testbenches for functional verification
- Synthesizable with Xilinx/Intel toolchains

## Features

- Transmitter (TX) and receiver (RX)
- Configurable:
  - Clock frequency (system clock)
  - Baud rate
  - Data bits (e.g., 7, 8)
  - Parity (none / even / odd) — if implemented in this repo
  - Stop bits (1 or 2)
- Ready / busy / valid signaling for easy integration
- Testbench and example simulation scripts
- Targeted for FPGA usage (IO constraints and synthesis notes included)

> Note: The exact entity/generic/port names used in this README are intentionally generic. Please adapt the examples to the actual names defined in the VHDL sources in this repository.

## Repository layout (example)

- src/ — VHDL source files (UART core, helpers)
- tb/ — testbenches and simulation harnesses
- sim/ — simulation scripts and example waveforms (VCD/GBTK)
- constraints/ — example XDC/SDC constraint files (for FPGA)
- docs/ — design notes and datasheets
- LICENSE — license file (if present)

## Quick start — Simulation (GHDL)

Example: simulate the UART testbench with GHDL and view waveform in GTKWave.

1. Analyze sources:
```bash
ghdl -a src/*.vhd tb/*.vhd
```

2. Elaborate the testbench (replace `tb_uart` with the actual testbench entity name):
```bash
ghdl -e tb_uart
```

3. Run and produce a VCD file:
```bash
ghdl -r tb_uart --vcd=uart.vcd
```

4. Open waveform:
```bash
gtkwave uart.vcd
```

ModelSim/Questa users can use the included `tb/` scripts or create a do-file to compile and run the testbenches.

## Example instantiation

Adapt this example to match the actual entity name and port names in this repo:

```vhdl
-- Generic parameters: CLOCK_FREQ, BAUD_RATE, DATA_BITS, PARITY, STOP_BITS
u_uart : entity work.uart_core
  generic map (
    CLOCK_FREQ => 50000000,   -- 50 MHz
    BAUD_RATE  => 115200,
    DATA_BITS  => 8
  )
  port map (
    i_clk      => clk,
    i_rst      => rst,
    i_rx       => rx_pin,
    o_tx       => tx_pin,
    o_rx_data  => rx_data,
    o_rx_valid => rx_valid,
    i_tx_data  => tx_data,
    i_tx_start => tx_start,
    o_tx_busy  => tx_busy
  );
```

Baud generator note:
- Typical implementation divides the system clock by (CLOCK_FREQ/BAUD_RATE) (or an integer clock tick multiplier) to generate bit timing.
- Ensure the divider fits in the chosen generics and implementation.

## Running tests

- The `tb/` directory contains testbenches that exercise common UART scenarios:
  - simple TX-only loopback
  - RX framing checks
  - parity and stop-bit edge cases (if implemented)
- Use GHDL, ModelSim, or your preferred simulator to run the testbenches and inspect waveforms.

## Synthesis notes

- Add proper constraints for clock and IO pins (XDC for Vivado, .qsf for Quartus).
- IO standards and pin names depend on your FPGA board — adapt constraints accordingly.
- Watch for timing around the baud generator and sampling point in the receiver; if you run at high baud rates relative to your clock, ensure the timing nets meet timing closure.
- Consider using an oversampling factor (e.g., 4x or 16x) in the receiver for better sampling stability — the implementation may or may not include oversampling.

## Integration tips

- Connect tx_pin from the UART core to the physical TX pad and rx_pin to the physical RX pad. Remember that TX is driven by the device and RX is an input.
- If you need hardware flow control (CTS/RTS), add simple handshake signals or FIFO buffers between your logic and the UART core.
- For DMA-like behavior, add a small FIFO between the core and the user logic to absorb bursts.

## Contributing

Contributions are welcome. Suggested workflow:
1. Fork the repository
2. Add or improve features (e.g., parity options, FIFOs, oversampling)
3. Add or update testbenches
4. Open a pull request describing your changes

Please include simulation results and, where applicable, synthesis reports for supported toolchains.

## License

See the LICENSE file in the repository. If no license is present, consider adding an open-source license such as MIT, BSD-3, or Apache-2.0 to clarify reuse terms.

## Author / Contact

- Oubaida ASSLADDAY
- Mohamed ARJAZ
