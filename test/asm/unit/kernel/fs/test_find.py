from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520
K_PTR2_LO = 0x04
K_PTR2_HI = 0x05


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


def format_volume(test, cpu, name="hello"):
    cpu.poke(NAME_ADDR, pascal(name))
    cpu.set_k_ptr(NAME_ADDR)
    test.run_sub(cpu, "FS_FORMAT", max_steps=10000)


def find(test, cpu, name):
    cpu.poke(NAME_ADDR, pascal(name))
    cpu.set_k_ptr2(NAME_ADDR)
    test.run_sub(cpu, "FS_FIND", max_steps=10000)


class TestKernelFsFind(BaseTest):
    def test_finds_a_written_file_by_name(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        format_volume(self, cpu)
        self._write(cpu, "foo", b"foo file data")
        self._write(cpu, "bar", b"bar file data")

        find(self, cpu, "bar")

        self.assertFalse(cpu.carry())
        self.assertEqual(0xB8, cpu.memory[K_PTR2_LO])
        self.assertEqual(0xFF, cpu.memory[K_PTR2_HI])

    def test_finds_the_other_file_too(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        format_volume(self, cpu)
        self._write(cpu, "foo", b"foo file data")
        self._write(cpu, "bar", b"bar file data")

        find(self, cpu, "foo")

        self.assertFalse(cpu.carry())
        self.assertEqual(0xD0, cpu.memory[K_PTR2_LO])
        self.assertEqual(0xFF, cpu.memory[K_PTR2_HI])

    def test_missing_file_returns_carry_set(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        format_volume(self, cpu)
        self._write(cpu, "foo", b"foo file data")

        find(self, cpu, "nope")

        self.assertTrue(cpu.carry())

    def _write(self, cpu, name, data):
        cpu.poke(NAME_ADDR, pascal(name))
        cpu.poke(DATA_ADDR, data)
        cpu.set_k_ptr(DATA_ADDR)
        cpu.set_k_ptr2(NAME_ADDR)
        cpu.set_k_len(len(data))
        self.run_sub(cpu, "FS_WRITE", max_steps=10000)
