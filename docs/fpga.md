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

## TinyFPGA Programming

Homebrew does not appear to provide a current `tinyprog` formula. Install it
with Python tooling instead:

```sh
brew install pipx
pipx install tinyprog
```

If `pipx` is not available, a user-local `pip` install is another option:

```sh
python3 -m pip install --user tinyprog
```

## Expected Flow

The normal edit/build/check loop is managed through `doit`:

```sh
uv run doit fpga:sim
uv run doit fpga:build
uv run doit fpga:program -t blink
```

By default, non-programming actions run against all targets under `src/fpga/`.
Use `-t` to select one target:

```sh
uv run doit fpga:sim -t blink
uv run doit fpga:build -t blink
uv run doit fpga:program -t blink
```

Programming always requires an explicit target.

Supported FPGA actions are:

- `sim`: run the target testbench with Icarus Verilog.
- `synth`: synthesize `top.v` with Yosys.
- `pnr`: place and route with `nextpnr-ice40`.
- `pack`: pack the routed design with `icepack`.
- `build`: run `synth`, `pnr`, and `pack`.
- `program`: run `build`, then upload with `tinyprog`.

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
