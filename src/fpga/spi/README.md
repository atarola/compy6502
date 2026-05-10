# SPI Controller

The SPI Controller is a memory-mapped SPI peripheral for a 6502-style bus. It provides byte transfers, four programmable active-low chip-select outputs, and a shared tri-state 8-bit data bus that is only driven during read cycles.

## 1. Features
- 6502-compatible register interface.
- One-byte SPI transmit and receive register.
- Four active-low SPI chip-select outputs.
- Software-controlled chip-select hold.
- Shared tri-state external data bus.
- MSB-first SPI transfers.

## 2. External Signals
### 2.1 6502 Bus
- `RESB` (in, active-low): reset.
- `CSB` (in, active-low): selects this peripheral.
- `RDB` (in, active-low): read strobe.
- `WRB` (in, active-low): write strobe.
- `REG_SELECT[1:0]` (in): register select.
- `DATA[7:0]` (inout): shared data bus.

### 2.2 SPI Bus
- `SPI_CSB[3:0]` (out, active-low): SPI chip selects.
- `SCK` (out): SPI clock.
- `MOSI` (out): master-out serial data.
- `MISO` (in): master-in serial data.

## 3. Register Map
`REG_SELECT[1:0]` selects one of four register addresses.

| Address | Name | Read | Write |
| --- | --- | --- | --- |
| `0x00` | Data | Last received byte | Transmit byte and start transfer |
| `0x01` | Config | Current configuration | Update configuration |
| `0x02` | Status | Transfer status | Ignored |
| `0x03` | Reserved | `0x00` | Ignored |

## 4. Config Register
| Bits | Name | Description |
| --- | --- | --- |
| `1:0` | CS Select | Selects one of four SPI chip-select outputs. |
| `2` | CS Enable | `1` asserts selected chip select. `0` releases all chip selects. |
| `7:3` | Reserved | Write `0`. |

Chip-select output when `CS Enable = 1`:

| CS Select | `SPI_CSB[3:0]` |
| --- | --- |
| `0b00` | `0b1110` |
| `0b01` | `0b1101` |
| `0b10` | `0b1011` |
| `0b11` | `0b0111` |

When `CS Enable = 0`, `SPI_CSB[3:0] = 0b1111`.

## 5. Status Register
| Bit | Name | Description |
| --- | --- | --- |
| `0` | Busy | `1` while a byte transfer is active. |
| `7:1` | Reserved | Reads as `0`. |

## 6. Bus Behavior
- The controller drives `DATA[7:0]` only during selected read cycles.
- During writes and unselected cycles, `DATA[7:0]` is high impedance from the controller side.
- Write effects are visible after a small number of FPGA clock cycles.
- Software should poll the Busy bit before assuming a byte transfer has completed.
- Writes to the Data register while Busy is set are ignored.

## 7. SPI Behavior
- Transfers are one byte at a time.
- Bits shift MSB first.
- Chip select is controlled by the Config register, not automatically by each byte transfer.
- For multi-byte devices, assert chip select, write/read the required bytes, then clear chip select.

## 8. Expected Transaction Example
Example: send command byte `0x9f` to device 0, then read three response bytes.

| Step | Register | RDB | WRB | Value | Expected effect |
| --- | --- | --- | --- | --- | --- |
| 1 | Config `0x01` | `1` | `0` | `0x04` | Assert `SPI_CSB[0]`; `SPI_CSB[3:0] = 0b1110`. |
| 2 | Data `0x00` | `1` | `0` | `0x9f` | Start transfer of command byte. |
| 3 | Status `0x02` | `0` | `1` | Read until Busy is `0` | Wait for command byte to finish. |
| 4 | Data `0x00` | `1` | `0` | `0x00` | Start transfer of first response byte. |
| 5 | Status `0x02` | `0` | `1` | Read until Busy is `0` | Wait for first response byte. |
| 6 | Data `0x00` | `0` | `1` | Read | Read first received byte. |
| 7 | Data `0x00` | `1` | `0` | `0x00` | Start transfer of second response byte. |
| 8 | Status `0x02` | `0` | `1` | Read until Busy is `0` | Wait for second response byte. |
| 9 | Data `0x00` | `0` | `1` | Read | Read second received byte. |
| 10 | Data `0x00` | `1` | `0` | `0x00` | Start transfer of third response byte. |
| 11 | Status `0x02` | `0` | `1` | Read until Busy is `0` | Wait for third response byte. |
| 12 | Data `0x00` | `0` | `1` | Read | Read third received byte. |
| 13 | Config `0x01` | `1` | `0` | `0x00` | Release all chip selects; `SPI_CSB[3:0] = 0b1111`. |

Each Data write shifts one byte out on `MOSI` and captures one byte from `MISO`. For read-only SPI responses, write `0x00` or another device-appropriate dummy byte to clock each response byte in.
