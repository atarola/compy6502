from asm.unit.base import BaseTest


class TestKernelSpiTransfer(BaseTest):
    def test_spi_transfer_sends_byte(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi(rx_data=bytes([0x55]))

        self.run_sub(cpu, "SPI_TRANSFER", a=0xAB)

        self.assertEqual(bytes([0xAB]), spi.tx())

    def test_spi_transfer_receives_byte(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi(rx_data=bytes([0x55]))

        self.run_sub(cpu, "SPI_TRANSFER", a=0x00)

        self.assertEqual(0x55, cpu.a)

    def test_spi_transfer_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi(rx_data=bytes([0x55]))

        self.run_sub(cpu, "SPI_TRANSFER", a=0x00)

        self.assertFalse(cpu.carry())
