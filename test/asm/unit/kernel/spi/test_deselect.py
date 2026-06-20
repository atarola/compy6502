from asm.unit.base import BaseTest

SPI_CS_ENABLE = 0x04
SPI_CLK_1M = 0x18


class TestKernelSpiDeselect(BaseTest):
    def test_spi_deselect_clears_cs_enable(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_CONFIGURE", a=SPI_CLK_1M)
        self.run_sub(cpu, "SPI_SELECT")
        self.run_sub(cpu, "SPI_DESELECT")

        self.assertEqual(SPI_CLK_1M, spi.config())

    def test_spi_deselect_preserves_config(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_CONFIGURE", a=0x11)
        self.run_sub(cpu, "SPI_SELECT")
        self.run_sub(cpu, "SPI_DESELECT")

        self.assertEqual(0x11, spi.config())

    def test_spi_deselect_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_DESELECT")

        self.assertFalse(cpu.carry())
