from asm.unit.base import BaseTest


class TestKernelSpiWrite(BaseTest):
    def test_spi_write_sends_byte(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_WRITE", a=0xAB)

        self.assertEqual(bytes([0xAB]), spi.tx())

    def test_spi_write_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_WRITE", a=0xAB)

        self.assertFalse(cpu.carry())
