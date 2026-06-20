from asm.unit.base import BaseTest

ACIA_COMMAND = 0xC002
ACIA_CONTROL = 0xC003


class TestKernelWozmon(BaseTest):
    def test_wozmon_address_is_the_first_jump_table_slot(self):
        self.assertEqual(0xC100, self.get_rom_address("WOZMON"))

    def test_jumping_to_wozmon_reaches_wozmon_start(self):
        cpu = self.get_rom_cpu()
        wozmon_addr = self.get_rom_address("WOZMON")
        start_addr = self.get_rom_address("WOZMON_START")

        cpu.pc = wozmon_addr
        cpu.until_pc(start_addr, max_steps=10)

        # WOZMON_START's first few instructions configure the ACIA --
        # reaching this point confirms the trampoline lands in the real code.
        for _ in range(10):
            cpu.step()

        self.assertEqual(0b00011110, cpu.memory[ACIA_CONTROL])
        self.assertEqual(0x0B, cpu.memory[ACIA_COMMAND])
