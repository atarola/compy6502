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
| Signal | Pin | Direction | Description |
| --- | --- | --- | --- |
| `RESB` | `3` | In, active-low | Reset. |
| `CSB` | `14` | In, active-low | Selects this peripheral. |
| `RDB` | `5` | In, active-low | Read strobe. |
| `WRB` | `4` | In, active-low | Write strobe. |
| `REG_SELECT[1]` | `1` | In | Register select bit 1. |
| `REG_SELECT[0]` | `2` | In | Register select bit 0. |
| `DATA[7]` | `6` | Inout | Shared data bus bit 7. |
| `DATA[6]` | `7` | Inout | Shared data bus bit 6. |
| `DATA[5]` | `8` | Inout | Shared data bus bit 5. |
| `DATA[4]` | `9` | Inout | Shared data bus bit 4. |
| `DATA[3]` | `10` | Inout | Shared data bus bit 3. |
| `DATA[2]` | `11` | Inout | Shared data bus bit 2. |
| `DATA[1]` | `12` | Inout | Shared data bus bit 1. |
| `DATA[0]` | `13` | Inout | Shared data bus bit 0. |
| `DATA_OUT` | `15` | Out | High when the controller is driving `DATA[7:0]` toward the 6502 bus. |

### 2.2 SPI Bus
| Signal | Pin | Direction | Description |
| --- | --- | --- | --- |
| `SPI_CSB[0]` | `16` | Out, active-low | SPI chip select 0. |
| `SPI_CSB[1]` | `17` | Out, active-low | SPI chip select 1. |
| `SPI_CSB[2]` | `18` | Out, active-low | SPI chip select 2. |
| `SPI_CSB[3]` | `19` | Out, active-low | SPI chip select 3. |
| `SCK` | `20` | Out | SPI clock. |
| `MOSI` | `21` | Out | Master-out serial data. |
| `MISO` | `22` | In | Master-in serial data. |

### 2.3 Local Indicators
| Signal | Pin | Direction | Description |
| --- | --- | --- | --- |
| `LED` | `LED` | Out | High when `CSB` is asserted. |

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
| `4:3` | Clock Select | Selects one of four SPI clock rates. |
| `7:5` | Reserved | Write `0`. |

Chip-select output when `CS Enable = 1`:

| CS Select | `SPI_CSB[3:0]` |
| --- | --- |
| `0b00` | `0b1110` |
| `0b01` | `0b1101` |
| `0b10` | `0b1011` |
| `0b11` | `0b0111` |

When `CS Enable = 0`, `SPI_CSB[3:0] = 0b1111`.

Clock rate setting:

| Setting | Result |
| --- | --- |
| `0b00` | `125 kHz` |
| `0b01` | `250 kHz` |
| `0b10` | `500 kHz` |
| `0b11` | `1 MHz` |

## 5. Status Register
| Bit | Name | Description |
| --- | --- | --- |
| `0` | Busy | `1` while a byte transfer is active. |
| `7:1` | Reserved | Reads as `0`. |

## 6. Bus Behavior
- The controller drives `DATA[7:0]` only during selected read cycles.
- `DATA_OUT` is high only during selected read cycles.
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
