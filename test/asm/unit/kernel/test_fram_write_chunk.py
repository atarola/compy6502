from asm.unit.base import BaseTest

FRAM_CMD_WRITE = 0x02
SRC_ADDR  = 0x0300
FRAM_ADDR = 0x1234


class TestKernelFramWriteChunk(BaseTest):
    def test_fram_write_chunk_sends_command_address_and_data(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        data = bytes([0xAA, 0xBB, 0xCC])
        cpu.poke(SRC_ADDR, data)
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_ptr2(FRAM_ADDR)
        cpu.set_k_len(len(data))

        self.run_sub(cpu, "FRAM_WRITE_CHUNK", max_steps=5000)

        self.assertEqual(
            bytes([FRAM_CMD_WRITE, 0x12, 0x34, 0xAA, 0xBB, 0xCC]),
            spi.tx()
        )

    def test_fram_write_chunk_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        cpu.poke(SRC_ADDR, bytes([0x01]))
        cpu.set_k_ptr(SRC_ADDR)
        cpu.set_k_ptr2(FRAM_ADDR)
        cpu.set_k_len(1)

        self.run_sub(cpu, "FRAM_WRITE_CHUNK", max_steps=5000)

        self.assertFalse(cpu.carry())
