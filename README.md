# compy6502

`compy6502` is an early-stage 6502 homebrew computer project. The long-term
goal is to build enough hardware and firmware to run Tetris on the machine.

The design follows the spirit of Ben Eater-style breadboard/modular 6502
systems for simplicity and debuggability, but uses a different memory map based
on the MMU/address-decoder architecture in `docs/mmu.png`.

The repo currently includes KiCad hardware designs, early ROM bring-up
firmware, build/write scripts, emulator test scaffolding, and architecture
reference images in `docs/`.

## Memory Map

The intended memory map is:

```text
$0000-$BFFF  RAM
$C000-$C0FF  I/O page
$C100-$FFFF  ROM
```

The I/O page is split into four 64-byte device slots:

```text
$C000-$C03F  IO0B
$C040-$C07F  IO1B
$C080-$C0BF  IO2B
$C0C0-$C0FF  IO3B
```

The current linker script still maps ROM from `$8000-$FFFF` for bring-up. That
is a temporary convenience and should eventually be changed to the final
`$C100-$FFFF` ROM region while keeping vectors at `$FFFA-$FFFF`.

## TODO

### Base Computer

- [ ] Set up the ACIA design on a breadboard and test it.
- [ ] Create the ACIA card.
- [ ] Revise the CPU card.
- [ ] Revise the ROM card.
- [ ] Revise the backplane with 8 connectors.
- [ ] Get new boards manufactured.

### I/O

- [ ] Start working on SPI interface using a TinyFPGA BX on a breadboard.
- [ ] Design an SPI card.
- [ ] Source an SNES socket.
- [ ] Start working on a VIA interface.
- [ ] Design a VIA card.
- [ ] Get I/O boards manufactured.

### Tetris

- [ ] Think about later.

## Credits

- `docs/mmu.png`: Mike McLaren, K8LH.
- `docs/Beater 02b.png`: Mike McLaren, K8LH.
