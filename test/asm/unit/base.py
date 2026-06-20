
import subprocess
import unittest
from collections import deque
from pathlib import Path

from py65.devices import mpu65c02
from py65.memory import ObservableMemory

ACIA_DATA   = 0xC000
ACIA_STATUS = 0xC001
SPI_DATA      = 0xC040
SPI_CONFIG    = 0xC041
SPI_STATUS    = 0xC042
SPI_CS_ENABLE = 0x04
K_PTR_LO    = 0x02
K_PTR_HI    = 0x03
K_PTR2_LO   = 0x04
K_PTR2_HI   = 0x05
K_LEN_LO    = 0x06
K_LEN_HI    = 0x07

ASSEMBLE = "ca65 -I ./src/asm/eeprom -I ./src/asm -I ./src -o ./test/asm/bin/{0}.o ./test/asm/{0}.s"
LINK = "ld65 -C ./src/asm/eeprom/compy6502.x -o ./test/asm/bin/{0}.bin ./test/asm/bin/{0}.o"
ROM = "./bin/compy6502.bin"
ROM_DEBUG = Path("./bin/compy6502.dbg")


class BaseTest(unittest.TestCase):
    _rom_symbols = None

    def get_rom_address(self, name):
        if self._rom_symbols is None:
            self._rom_symbols = self._load_rom_symbols()

        try:
            return self._rom_symbols[name]
        except KeyError as exc:
            raise AssertionError(f"could not locate {name} in {ROM_DEBUG}") from exc

    def _load_rom_symbols(self):
        symbols = {}

        for line in ROM_DEBUG.read_text().splitlines():
            if not line.startswith("sym\t"):
                continue

            fields = {}
            for field in line.split("\t", 1)[1].split(","):
                key, value = field.split("=", 1)
                fields[key] = value

            name = fields.get("name", "").strip('"')
            value = fields.get("val")
            if name and value:
                symbols[name] = int(value[2:], 16)

        return symbols

    def get_cpu(self, filename):
        start, data = self.get_data(filename)
        return self.make_cpu(start, data)

    def get_rom_cpu(self):
        with open(ROM, "rb") as f:
            output = f.read()

        start = int.from_bytes(output[0x7ffc:0x7ffe], byteorder="little")
        return self.make_cpu(start, output)

    def run_sub(self, cpu, name, start=0x0200, a=None, x=None, y=None, max_steps=1000):
        address = self.get_rom_address(name)
        if a is not None:
            cpu.a = a
        if x is not None:
            cpu.x = x
        if y is not None:
            cpu.y = y

        cpu.poke(start, bytes([0x20, address & 0xFF, address >> 8, 0xEA]))
        cpu.pc = start
        cpu.until_pc(start + 3, max_steps=max_steps)
        return cpu

    def make_cpu(self, start, data):
        self.memory = ObservableMemory()
        self.memory[0x8000:0xffff] = data

        cpu = TestMPU(self.memory, start)
        cpu.reset()
        return cpu

    def get_data(self, filename):
        Path("./test/asm/bin", filename).parent.mkdir(parents=True, exist_ok=True)
        subprocess.check_call(self.prep(ASSEMBLE, filename))
        subprocess.check_call(self.prep(LINK, filename))

        with open("./test/asm/bin/{0}.bin".format(filename), "rb") as f:
            output = f.read()

        start = int.from_bytes(output[0x7ffc:0x7ffe], byteorder="little")
        return (start, output)

    def prep(self, string, filename):
        return string.format(filename).split(" ")


class TestMPU(mpu65c02.MPU):
    def poke(self, address, data):
        self.memory[address : address + len(data)] = data

    def set_k_ptr(self, address):
        self.memory[K_PTR_LO] = address & 0xFF
        self.memory[K_PTR_HI] = address >> 8

    def set_k_ptr2(self, address):
        self.memory[K_PTR2_LO] = address & 0xFF
        self.memory[K_PTR2_HI] = address >> 8

    def set_k_len(self, length):
        self.memory[K_LEN_LO] = length & 0xFF
        self.memory[K_LEN_HI] = (length >> 8) & 0xFF

    def carry(self):
        return bool(self.p & 0x01)

    def install_acia(self, data=b""):
        device = AciaDevice(data)
        device.install(self.memory)
        return device

    def install_spi(self, rx_data=b""):
        device = SpiDevice(rx_data)
        device.install(self.memory)
        return device

    def install_fram(self, fram=None):
        device = FramSpiDevice(fram)
        device.install(self.memory)
        return device

    def register_line(self):
        return f"PC={self.pc:04X} A={self.a:02X} X={self.x:02X} Y={self.y:02X}"

    def until_null(self):
        while True:
            if self.memory[self.pc] == 0x00:
                break
            self.step()

    def until_pc(self, address, max_steps=1000):
        for _ in range(max_steps):
            if self.pc == address:
                return
            self.step()

        raise AssertionError(f"pc did not reach {hex(address)} within {max_steps} steps")

    def get_byte(self, loc):
        return hex(self.memory[loc])

    def get_word(self, loc):
        return hex(int.from_bytes(self.memory[loc:loc+2], byteorder="little"))

    def get_stack(self, loc):
        return self.get_word(self.x + (2 * loc))


class AciaDevice:
    def __init__(self, data=b""):
        if isinstance(data, str):
            data = data.encode("ascii")
        self.input = deque(data)
        self.output_buf = bytearray()

    def install(self, memory):
        memory.subscribe_to_read([ACIA_STATUS], self.read_status)
        memory.subscribe_to_read([ACIA_DATA], self.read_data)
        memory.subscribe_to_write([ACIA_DATA], self.write_data)

    def output(self):
        return bytes(self.output_buf)

    def read_status(self, address):
        return 0x08 if self.input else 0x00

    def read_data(self, address):
        return self.input.popleft() if self.input else 0x00

    def write_data(self, address, value):
        self.output_buf.append(value)
        return value


class SpiDevice:
    def __init__(self, rx_data=b""):
        self.tx_buf = []
        self.rx_buf = deque(rx_data)
        self.config_reg = 0x00
        self._transactions = []
        self._current_txn = None

    def install(self, memory):
        memory.subscribe_to_read([SPI_STATUS], self.read_status)
        memory.subscribe_to_read([SPI_DATA], self.read_data)
        memory.subscribe_to_read([SPI_CONFIG], self.read_config)
        memory.subscribe_to_write([SPI_DATA], self.write_data)
        memory.subscribe_to_write([SPI_CONFIG], self.write_config)

    def tx(self):
        return bytes(self.tx_buf)

    def transactions(self):
        return [bytes(t) for t in self._transactions]

    def config(self):
        return self.config_reg

    def read_status(self, address):
        return 0x00

    def read_data(self, address):
        return self.rx_buf.popleft() if self.rx_buf else 0x00

    def read_config(self, address):
        return self.config_reg

    def write_data(self, address, value):
        self.tx_buf.append(value)
        if self._current_txn is not None:
            self._current_txn.append(value)
        return value

    def write_config(self, address, value):
        cs_was = bool(self.config_reg & SPI_CS_ENABLE)
        cs_now = bool(value & SPI_CS_ENABLE)
        self.config_reg = value
        if not cs_was and cs_now:
            self._current_txn = []
        elif cs_was and not cs_now and self._current_txn is not None:
            self._transactions.append(self._current_txn)
            self._current_txn = None
        return value


FRAM_CMD_WREN = 0x06
FRAM_CMD_READ = 0x03
FRAM_CMD_WRITE = 0x02


class FramSpiDevice:
    """Emulates the FRAM's command protocol (kernel/fram.s) against a real
    backing store, so multi-step filesystem operations (write then read
    back, etc.) behave like the real chip instead of returning canned data.
    """

    def __init__(self, fram=None):
        self.fram = fram if fram is not None else bytearray(0x10000)
        self.config_reg = 0x00
        self._byte_index = 0
        self._cmd = None
        self._addr = 0
        self._next_read = 0x00

    def install(self, memory):
        memory.subscribe_to_read([SPI_STATUS], self.read_status)
        memory.subscribe_to_read([SPI_DATA], self.read_data)
        memory.subscribe_to_write([SPI_DATA], self.write_data)
        memory.subscribe_to_write([SPI_CONFIG], self.write_config)

    def read_status(self, address):
        return 0x00

    def read_data(self, address):
        return self._next_read

    def write_config(self, address, value):
        cs_was = bool(self.config_reg & SPI_CS_ENABLE)
        cs_now = bool(value & SPI_CS_ENABLE)
        self.config_reg = value
        if not cs_was and cs_now:
            self._byte_index = 0
            self._cmd = None
        return value

    def write_data(self, address, value):
        if self._byte_index == 0:
            self._cmd = value
            self._next_read = 0x00
        elif self._cmd in (FRAM_CMD_READ, FRAM_CMD_WRITE) and self._byte_index == 1:
            self._addr = value << 8
            self._next_read = 0x00
        elif self._cmd in (FRAM_CMD_READ, FRAM_CMD_WRITE) and self._byte_index == 2:
            self._addr = (self._addr & 0xFF00) | value
            self._next_read = 0x00
        elif self._cmd == FRAM_CMD_WRITE:
            self.fram[self._addr & 0xFFFF] = value
            self._addr = (self._addr + 1) & 0xFFFF
            self._next_read = 0x00
        elif self._cmd == FRAM_CMD_READ:
            self._next_read = self.fram[self._addr & 0xFFFF]
            self._addr = (self._addr + 1) & 0xFFFF
        else:
            self._next_read = 0x00

        self._byte_index += 1
        return value