from asm.unit.base import BaseTest

NAME_ADDR = 0x0500
DATA_ADDR = 0x0520


def pascal(s):
    return bytes([len(s)]) + s.encode("ascii")


class TestKernelPrintFileName(BaseTest):
    def test_prints_the_files_name_and_a_newline(self):
        cpu = self.get_rom_cpu()
        cpu.install_fram()
        acia = cpu.install_acia()
        self._format(cpu)
        self._write(cpu, "greeting", b"hello world")
        self._find(cpu, "greeting")  # K_PTR2 = file ID

        self.run_sub(cpu, "PRINT_FILE_NAME", max_steps=20000)

        self.assertEqual(b"greeting\r\n", acia.output())

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
