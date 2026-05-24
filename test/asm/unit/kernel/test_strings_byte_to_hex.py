from asm.unit.base import BaseTest


class TestKernelStringsByteToHex(BaseTest):
    def test_strings_byte_to_hex(self):
        cpu = self.get_rom_cpu()

        self.run_sub(cpu, "BYTE_TO_HEX", a=0xAF)

        self.assertEqual(ord("A"), cpu.a)
        self.assertEqual(ord("F"), cpu.x)
