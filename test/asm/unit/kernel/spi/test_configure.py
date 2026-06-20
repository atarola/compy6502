from asm.unit.base import BaseTest

SPI_CLK_1M = 0x18


class TestKernelSpiConfigure(BaseTest):
    def test_spi_configure_writes_config(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_CONFIGURE", a=SPI_CLK_1M)

        self.assertEqual(SPI_CLK_1M, spi.config())

    def test_spi_configure_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_CONFIGURE", a=SPI_CLK_1M)

        self.assertFalse(cpu.carry())
