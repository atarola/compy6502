from asm.unit.base import BaseTest


ACIA_DATA = 0xC000
ACIA_STATUS = 0xC001
ACIA_GETC = 0xC103


class TestKernelAciaGetc(BaseTest):
    def test_acia_getc(self):
        cpu = self.get_rom_cpu()

        cpu.memory[ACIA_STATUS] = 0x08
        cpu.memory[ACIA_DATA] = 0x55
        cpu.poke(0x0200, bytes([0x20, 0x03, 0xC1, 0xEA]))
        cpu.pc = 0x0200

        cpu.until_pc(0x0203)

        self.assertEqual(0x55, cpu.a)
