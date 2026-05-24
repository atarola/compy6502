from asm.unit.base import BaseTest


BUFFER = 0x0300


class TestKernelStringsStrPop(BaseTest):
    def test_strings_str_pop(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(BUFFER)
        cpu.memory[BUFFER] = 0x03
        cpu.memory[BUFFER + 1] = ord("A")
        cpu.memory[BUFFER + 2] = ord("B")
        cpu.memory[BUFFER + 3] = ord("C")

        self.run_sub(cpu, "STR_POP")

        self.assertEqual(ord("C"), cpu.a)
        self.assertEqual(0x02, cpu.memory[BUFFER])
        self.assertFalse(cpu.carry())

    def test_strings_str_pop_empty(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(BUFFER)
        cpu.memory[BUFFER] = 0x00

        self.run_sub(cpu, "STR_POP")

        self.assertTrue(cpu.carry())
