# FPGA Development Environment

This project is expected to use a TinyFPGA BX for early SPI interface work. The
TinyFPGA BX uses a Lattice iCE40 FPGA, so the local toolchain is based on the
open-source iCE40 flow.

## Toolchain

Install the core tools with Homebrew:

```sh
brew install icarus-verilog verilator yosys nextpnr-ice40 icestorm surfer
```

The important tools are:

- `iverilog` / `vvp`: quick Verilog simulation.
- `verilator`: stronger linting and compiled simulation for larger tests.
- `yosys`: Verilog synthesis.
- `nextpnr-ice40`: place and route for Lattice iCE40 parts.
- `icepack`: bitstream packing, provided by `icestorm`.
- `surfer`: waveform viewer.

GTKWave is the traditional waveform viewer, but the Homebrew cask is currently
disabled. Use Surfer for waveform viewing unless that changes.

## TinyFPGA Programming From Windows

Build bitstreams from WSL/Ubuntu, but program the TinyFPGA BX from Windows.
WSL USB passthrough is unreliable with the BX bootloader timing.

Install `tinyprog` in Windows PowerShell:

```powershell
py -m pip install --user pipx
py -m pipx ensurepath
pipx install tinyprog
tinyprog --help
```

Close and reopen PowerShell after `ensurepath` if `pipx` is not found.

Build the FPGA target in WSL:

```sh
uv run doit fpga:build -t blink
```

Press reset on the TinyFPGA BX so the bootloader is active, then program the
bitstream from Windows:

```powershell
tinyprog -p "\\wsl.localhost\Ubuntu\home\atarola\code\compy6502\build\fpga\blink\blink.bin"
```

The USB serial device can disappear after programming because the bitstream
disables `USBPU`. Press reset before the next upload.

## Expected Flow

The normal edit/build/check loop is managed through `doit`:

```sh
uv run doit fpga:sim
uv run doit fpga:build
```

By default, non-programming actions run against all targets under `src/fpga/`.
Use `-t` to select one target:

```sh
uv run doit fpga:sim -t blink
uv run doit fpga:build -t blink
```

Supported FPGA actions are:

- `sim`: run the target testbench with Icarus Verilog.
- `synth`: synthesize `top.v` with Yosys.
- `pnr`: place and route with `nextpnr-ice40`.
- `pack`: pack the routed design with `icepack`.
- `build`: run `synth`, `pnr`, and `pack`.

Target directories use this layout:

```text
src/fpga/<target>/
  top.v
  pins.pcf
  *_tb.v
  other_design_modules.v
```

`fpga:sim` runs every `*_tb.v` testbench in the target. Synthesis reads all
`.v` files except testbenches and uses `top` as the top-level module.

The final bitstream for a target is written to:

```text
build/fpga/<target>/<target>.bin
```

For the blink target:

```text
build/fpga/blink/blink.bin
```

Program the TinyFPGA BX from Windows with `tinyprog` rather than passing USB
through WSL.

Conceptually, the flow is:

```text
write Verilog
simulate with iverilog or verilator
inspect waveforms with surfer
synthesize with yosys
place and route with nextpnr-ice40
pack a bitstream with icepack
program the TinyFPGA BX with tinyprog
```

The TinyFPGA BX guide is still useful for board-specific behavior and bootloader
details:

```text
https://tinyfpga.com/bx/guide.html
```
