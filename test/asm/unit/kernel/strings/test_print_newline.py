from asm.unit.base import BaseTest


class TestKernelPrintNewline(BaseTest):
    def test_prints_crlf(self):
        cpu = self.get_rom_cpu()
        acia = cpu.install_acia()

        self.run_sub(cpu, "PRINT_NEWLINE", max_steps=5000)

        self.assertEqual(b"\r\n", acia.output())
