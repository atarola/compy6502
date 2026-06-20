from asm.unit.base import BaseTest

SRC_ADDR = 0x0300


class TestKernelCrc(BaseTest):
    def test_returns_byte_that_zero_sums_the_buffer(self):
        cpu = self.get_rom_cpu()
        data = bytes([0x12, 0x05, 0x00, 0x0D, 0x00, 0x00, 0x00, 0x03, 0x66, 0x6F, 0x6F])
        cpu.poke(SRC_ADDR, data)
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_len(len(data))

        self.run_sub(cpu, "CRC")

        self.assertEqual(0x95, cpu.a)
        self.assertEqual(0, (sum(data) + cpu.a) & 0xFF)

    def test_empty_buffer_returns_zero(self):
        cpu = self.get_rom_cpu()
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_len(0)

        self.run_sub(cpu, "CRC")

        self.assertEqual(0x00, cpu.a)

    def test_does_not_modify_the_buffer(self):
        cpu = self.get_rom_cpu()
        data = bytes([0xAA, 0xBB, 0xCC])
        cpu.poke(SRC_ADDR, data)
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_len(len(data))

        self.run_sub(cpu, "CRC")

        self.assertEqual(list(data), list(cpu.memory[SRC_ADDR : SRC_ADDR + len(data)]))
