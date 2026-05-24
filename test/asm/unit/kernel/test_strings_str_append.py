from asm.unit.base import BaseTest


BUFFER = 0x0300


class TestKernelStringsStrAppend(BaseTest):
    def test_strings_str_append(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(BUFFER)
        cpu.memory[BUFFER] = 0x02
        cpu.memory[BUFFER + 1] = ord("A")
        cpu.memory[BUFFER + 2] = ord("B")

        self.run_sub(cpu, "STR_APPEND", a=ord("C"))

        self.assertEqual(0x03, cpu.memory[BUFFER])
        self.assertEqual(ord("C"), cpu.memory[BUFFER + 3])
        self.assertFalse(cpu.carry())

    def test_strings_str_append_full(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(BUFFER)
        cpu.memory[BUFFER] = 0xFF

        self.run_sub(cpu, "STR_APPEND", a=ord("Z"))

        self.assertEqual(0x00, cpu.memory[BUFFER])
        self.assertTrue(cpu.carry())
