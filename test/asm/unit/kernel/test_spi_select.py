from asm.unit.base import BaseTest

SPI_CS_ENABLE = 0x04
SPI_CLK_1M = 0x18


class TestKernelSpiSelect(BaseTest):
    def test_spi_select_sets_cs_enable(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_CONFIGURE", a=SPI_CLK_1M)
        self.run_sub(cpu, "SPI_SELECT")

        self.assertEqual(SPI_CLK_1M | SPI_CS_ENABLE, spi.config())

    def test_spi_select_preserves_config(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_CONFIGURE", a=0x05)
        self.run_sub(cpu, "SPI_SELECT")

        self.assertEqual(0x05 | SPI_CS_ENABLE, spi.config())

    def test_spi_select_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "SPI_SELECT")

        self.assertFalse(cpu.carry())
