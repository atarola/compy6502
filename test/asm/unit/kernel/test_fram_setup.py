from asm.unit.base import BaseTest

FRAM_CMD_WREN = 0x06
FRAM_CONFIG   = 0x18


class TestKernelFramSetup(BaseTest):
    def test_fram_setup_sends_wren(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "FRAM_SETUP", max_steps=5000)

        self.assertIn(FRAM_CMD_WREN, spi.tx())

    def test_fram_setup_configures_spi(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "FRAM_SETUP", max_steps=5000)

        self.assertEqual(FRAM_CONFIG, spi.config())

    def test_fram_setup_carry_clear(self):
        cpu = self.get_rom_cpu()
        spi = cpu.install_spi()

        self.run_sub(cpu, "FRAM_SETUP", max_steps=5000)

        self.assertFalse(cpu.carry())
