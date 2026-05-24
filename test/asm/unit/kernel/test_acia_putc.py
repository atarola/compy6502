from asm.unit.base import BaseTest

ACIA_DATA = 0xC000


class TestKernelAciaPutc(BaseTest):
    def test_acia_putc(self):
        cpu = self.get_rom_cpu()

        self.run_sub(cpu, "ACIA_PUTC", a=0x41)

        self.assertEqual(0x41, cpu.memory[ACIA_DATA])
        self.assertEqual(0x00, cpu.a)
