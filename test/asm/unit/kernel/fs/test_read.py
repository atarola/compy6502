from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520
DEST_ADDR = 0x0600


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


class TestKernelFsRead(BaseTest):
    def test_reads_file_data_back_into_ram(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")  # K_PTR2 = file ID

        cpu.set_k_ptr(DEST_ADDR)
        self.run_sub(cpu, "FS_READ", max_steps=10000)

        self.assertFalse(cpu.carry())
        self.assertEqual(b"hello world", bytes(cpu.memory[DEST_ADDR : DEST_ADDR + 11]))

    def _format(self, cpu):
        cpu.poke(NAME_ADDR, pascal("hello"))
        cpu.set_k_ptr(NAME_ADDR)
        self.run_sub(cpu, "FS_FORMAT", max_steps=10000)

    def _write(self, cpu, name, data):
        cpu.poke(NAME_ADDR, pascal(name))
        cpu.poke(DATA_ADDR, data)
        cpu.set_k_ptr(DATA_ADDR)
        cpu.set_k_ptr2(NAME_ADDR)
        cpu.set_k_len(len(data))
        self.run_sub(cpu, "FS_WRITE", max_steps=10000)

    def _find(self, cpu, name):
        cpu.poke(NAME_ADDR, pascal(name))
        cpu.set_k_ptr2(NAME_ADDR)
        self.run_sub(cpu, "FS_FIND", max_steps=10000)
