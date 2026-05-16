
import subprocess
import unittest
from collections import deque
from pathlib import Path

from py65.devices import mpu65c02
from py65.memory import ObservableMemory

ACIA_DATA = 0xC000
ACIA_STATUS = 0xC001

ASSEMBLE = "ca65 -I ./src/asm/eeprom -I ./src/asm -I ./src -o ./test/asm/bin/{0}.o ./test/asm/{0}.s"
LINK = "ld65 -C ./src/asm/eeprom/compy6502.x -o ./test/asm/bin/{0}.bin ./test/asm/bin/{0}.o"
ROM = "./bin/compy6502.bin"


class BaseTest(unittest.TestCase):

    def get_cpu(self, filename):
        start, data = self.get_data(filename)
        return self.make_cpu(start, data)

    def get_rom_cpu(self):
        with open(ROM, "rb") as f:
            output = f.read()

        start = int.from_bytes(output[0x7ffc:0x7ffe], byteorder="little")
        return self.make_cpu(start, output)

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

        # create our start position
        start = int.from_bytes(output[0x7ffc:0x7ffe], byteorder="little")
        return (start, output)

    def prep(self, string, filename):
        return string.format(filename).split(" ")


class TestMPU(mpu65c02.MPU):
    def poke(self, address, data):
        self.memory[address : address + len(data)] = data

    def install_acia(self, data=b""):
        if isinstance(data, str):
            data = data.encode("ascii")

        self._acia_input = deque(data)
        self._acia_output = bytearray()
        self.memory.subscribe_to_read([ACIA_STATUS], self._read_acia_status)
        self.memory.subscribe_to_read([ACIA_DATA], self._read_acia_data)
        self.memory.subscribe_to_write([ACIA_DATA], self._write_acia_data)

    def acia_output(self):
        return bytes(self._acia_output)

    def _read_acia_status(self, address):
        if self._acia_input:
            return 0x08

        return 0x00

    def _read_acia_data(self, address):
        if self._acia_input:
            return self._acia_input.popleft()

        return 0x00

    def _write_acia_data(self, address, value):
        self._acia_output.append(value)
        return value

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
