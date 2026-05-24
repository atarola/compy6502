from asm.unit.base import BaseTest


BUFFER = 0x0300


class TestKernelStringsStrInit(BaseTest):
    def test_strings_str_init(self):
        cpu = self.get_rom_cpu()

        cpu.set_k_ptr(BUFFER)
        cpu.memory[BUFFER] = 0x05
        cpu.memory[BUFFER + 1] = ord("A")
        cpu.memory[BUFFER + 2] = ord("B")

        self.run_sub(cpu, "STR_INIT")

        self.assertEqual(0x00, cpu.memory[BUFFER])
        self.assertEqual(ord("A"), cpu.memory[BUFFER + 1])
        self.assertEqual(ord("B"), cpu.memory[BUFFER + 2])
