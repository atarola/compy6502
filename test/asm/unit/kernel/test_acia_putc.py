from asm.unit.base import BaseTest


ACIA_DATA = 0xC000
ACIA_PUTC = 0xC100


class TestKernelAciaPutc(BaseTest):
    def test_acia_putc(self):
        cpu = self.get_rom_cpu()

        cpu.poke(0x0200, bytes([0xA9, 0x41, 0x20, 0x00, 0xC1, 0xEA]))
        cpu.pc = 0x0200

        cpu.until_pc(0x0205)

        self.assertEqual(0x41, cpu.memory[ACIA_DATA])
        self.assertEqual(0x00, cpu.a)
