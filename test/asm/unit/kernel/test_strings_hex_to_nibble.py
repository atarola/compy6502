from asm.unit.base import BaseTest


class TestKernelStringsHexToNibble(BaseTest):
    def test_strings_hex_to_nibble_upper(self):
        cpu = self.get_rom_cpu()

        self.run_sub(cpu, "HEX_TO_NIBBLE", a=ord("F"))

        self.assertEqual(0x0F, cpu.a)
        self.assertFalse(cpu.carry())

    def test_strings_hex_to_nibble_lower(self):
        cpu = self.get_rom_cpu()

        self.run_sub(cpu, "HEX_TO_NIBBLE", a=ord("b"))

        self.assertEqual(0x0B, cpu.a)
        self.assertFalse(cpu.carry())

    def test_strings_hex_to_nibble_invalid(self):
        cpu = self.get_rom_cpu()

        self.run_sub(cpu, "HEX_TO_NIBBLE", a=ord("G"))

        self.assertTrue(cpu.carry())
