
import subprocess
import unittest

from py65.devices import mpu65c02
from py65.memory import ObservableMemory

ASSEMBLE = "ca65 -I ../src -o ./bin/{0}.o ./asm/{0}.s"
LINK = "ld65 -C ../compy6502.x -o ./bin/{0}.bin ./bin/{0}.o"


class BaseTest(unittest.TestCase):

    def get_cpu(self, filename):
        start, data = self.get_data(filename)

        self.memory = ObservableMemory()
        self.memory[0xf000:0xffff] = data

        cpu = TestMPU(self.memory, start)
        cpu.reset()
        return cpu

    def get_data(self, filename):
        subprocess.check_call(['mkdir', '-p', './bin'])
        subprocess.check_call(self.prep(ASSEMBLE, filename))
        subprocess.check_call(self.prep(LINK, filename))

        with open("./bin/{0}.bin".format(filename), "rb") as f:
            output = f.read()

        # create our start position
        start = int.from_bytes(output[0x0ffc:0xffe], byteorder="little")
        return (start, output)

    def until_null(self, cpu):
        while True:
            if cpu.memory[cpu.pc] == 0x00:
                break

            cpu.step()

    def prep(self, string, filename):
        return string.format(filename).split(" ")


class TestMPU(mpu65c02.MPU):

    def until_null(self):
        while True:
            if self.memory[self.pc] == 0x00:
                break

            self.step()

    def get_byte(self, loc):
        return hex(self.memory[loc])

    def get_word(self, loc):
        return hex(int.from_bytes(self.memory[loc:loc+2], byteorder="little"))

    def get_stack(self, loc):
        return self.get_word(self.x + (2 * loc))
