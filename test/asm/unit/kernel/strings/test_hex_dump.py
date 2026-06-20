from asm.unit.base import BaseTest

SRC_ADDR = 0x0300


class TestKernelHexDump(BaseTest):
    def test_prints_space_separated_uppercase_hex_bytes(self):
        cpu = self.get_rom_cpu()
        acia = cpu.install_acia()

        cpu.poke(SRC_ADDR, bytes([0x01, 0xAB, 0xFF]))
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_len(3)

        self.run_sub(cpu, "HEX_DUMP", max_steps=5000)

        self.assertEqual(b"01 AB FF ", acia.output())

    def test_zero_length_prints_nothing(self):
        cpu = self.get_rom_cpu()
        acia = cpu.install_acia()

        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_len(0)

        self.run_sub(cpu, "HEX_DUMP", max_steps=5000)

        self.assertEqual(b"", acia.output())
