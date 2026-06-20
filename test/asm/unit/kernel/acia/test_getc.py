from asm.unit.base import BaseTest

ACIA_DATA = 0xC000
ACIA_STATUS = 0xC001


class TestKernelAciaGetc(BaseTest):
    def test_acia_getc(self):
        cpu = self.get_rom_cpu()

        cpu.memory[ACIA_STATUS] = 0x08
        cpu.memory[ACIA_DATA] = 0x55
        self.run_sub(cpu, "ACIA_GETC")

        self.assertEqual(0x55, cpu.a)
