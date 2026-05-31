from asm.unit.base import BaseTest

FRAM_CMD_READ = 0x03
DEST_ADDR = 0x0400
FRAM_ADDR = 0x1234


class TestKernelFramReadChunk(BaseTest):
    def test_fram_read_chunk_sends_command_and_address(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi(rx_data=bytes([0xAA, 0xBB, 0xCC]))

        cpu.set_k_ptr(DEST_ADDR)
        cpu.set_k_ptr2(FRAM_ADDR)
        cpu.set_k_len(3)

        self.run_sub(cpu, "FRAM_READ_CHUNK", max_steps=5000)

        tx = spi.tx()
        self.assertEqual(FRAM_CMD_READ, tx[0])
        self.assertEqual(0x12, tx[1])
        self.assertEqual(0x34, tx[2])

    def test_fram_read_chunk_stores_received_data(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi(rx_data=bytes([0xAA, 0xBB, 0xCC]))

        cpu.set_k_ptr(DEST_ADDR)
        cpu.set_k_ptr2(FRAM_ADDR)
        cpu.set_k_len(3)

        self.run_sub(cpu, "FRAM_READ_CHUNK", max_steps=5000)

        self.assertEqual(0xAA, cpu.memory[DEST_ADDR])
        self.assertEqual(0xBB, cpu.memory[DEST_ADDR + 1])
        self.assertEqual(0xCC, cpu.memory[DEST_ADDR + 2])

    def test_fram_read_chunk_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi(rx_data=bytes([0x01]))

        cpu.set_k_ptr(DEST_ADDR)
        cpu.set_k_ptr2(FRAM_ADDR)
        cpu.set_k_len(1)

        self.run_sub(cpu, "FRAM_READ_CHUNK", max_steps=5000)

        self.assertFalse(cpu.carry())
